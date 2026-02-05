using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using Sdnx.Core;

namespace Sdnx.Core
{
    public class ReadSuccess
    {
        public bool Ok { get; set; } = true;
        public Dictionary<string, object?> Data { get; set; } = new Dictionary<string, object?>();
    }

    public class ReadFailure
    {
        public bool Ok { get; set; } = false;
        public List<ReadError> SchemaErrors { get; set; } = new List<ReadError>();
        public List<ReadError> DataErrors { get; set; } = new List<ReadError>();
        public List<CheckError> CheckErrors { get; set; } = new List<CheckError>();
    }

    public static class ReadData
    {
        /// <summary>
        /// Reads and validates a data file against a schema.
        /// </summary>
        /// <param name="file">The path to the data file.</param>
        /// <param name="schema">Optional schema string path or Schema object.</param>
        public static object Read(string file, object? schema = null)
        {
            file = Locate(file);

            string contents = File.ReadAllText(file);
            var parsed = ParseData.Parse(contents);
            if (!parsed.Ok)
            {
                return new ReadFailure
                {
                    SchemaErrors = new List<ReadError>(),
                    DataErrors = ConvertErrors(parsed.Errors, contents),
                    CheckErrors = new List<CheckError>()
                };
            }

            // If there's a @schema directive, try to load the schema from there
            if (schema == null)
            {
                var match = Regex.Match(contents, @"^\s*@schema\(""(.+?)""\)");
                if (!match.Success)
                {
                    throw new InvalidOperationException("Schema required");
                }
                string schemaPath = match.Groups[1].Value;
                string baseDir = Path.GetDirectoryName(file) ?? "";
                schema = Path.GetFullPath(Path.Combine(baseDir, schemaPath));
            }

            // TODO: Handle fetching from a URL
            if (schema is string schemaString)
            {
                schema = Locate(schemaString);
                string schemaContents = File.ReadAllText((string)schema);
                var schemaParsed = ParseSchema.Parse(schemaContents);
                if (schemaParsed.Ok)
                {
                    schema = schemaParsed.Data;
                }
                else
                {
                    return new ReadFailure
                    {
                        SchemaErrors = ConvertErrors(schemaParsed.Errors, schemaContents),
                        DataErrors = new List<ReadError>(),
                        CheckErrors = new List<CheckError>()
                    };
                }
            }

            if (schema is Schema schemaObj && parsed.Data != null)
            {
                var checkResult = CheckData.Check(parsed.Data, schemaObj);
                if (checkResult.Ok)
                {
                    return new ReadSuccess
                    {
                        Data = parsed.Data
                    };
                }
                else
                {
                    return new ReadFailure
                    {
                        SchemaErrors = new List<ReadError>(),
                        DataErrors = new List<ReadError>(),
                        CheckErrors = checkResult.Errors ?? new List<CheckError>()
                    };
                }
            }

            throw new InvalidOperationException("Invalid schema type");
        }

        private static List<ReadError> ConvertErrors(List<ParseError>? errors, string contents)
        {
            var result = new List<ReadError>();
            if (errors != null)
            {
                foreach (var error in errors)
                {
                    result.Add(BuildReadError(error, contents));
                }
            }
            return result;
        }

        private static string Locate(string file)
        {
            if (!File.Exists(file))
            {
                string cwd = Directory.GetCurrentDirectory();
                file = Path.Combine(cwd, file);
                if (!File.Exists(file))
                {
                    throw new FileNotFoundException($"File not found: {file}");
                }
            }
            return file;
        }

        private static ReadError BuildReadError(ParseError e, string contents)
        {
            int lineIndex = e.Index;
            while (lineIndex >= 0 && contents[lineIndex] != '\n')
            {
                lineIndex--;
            }
            lineIndex++;

            int lineEndIndex = e.Index;
            while (lineEndIndex < contents.Length && contents[lineEndIndex] != '\n')
            {
                lineEndIndex++;
            }

            return new ReadError
            {
                Message = e.Message,
                Index = e.Index,
                Length = e.Length,
                Line = contents.Substring(lineIndex, lineEndIndex - lineIndex),
                Char = e.Index - lineIndex
            };
        }
    }
}
