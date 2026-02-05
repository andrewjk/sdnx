using System;
using System.Collections.Generic;
using Sdnx.Core;

namespace Sdnx.Core
{
    public class ParseDataStatus : ParseStatus
    {
        public ParseDataStatus() : base()
        {
        }

        public ParseDataStatus(string input) : base(input)
        {
        }
    }

    public static class ParseData
    {
        /// <summary>
        /// Parses some structured data from a string into an object.
        /// </summary>
        /// <param name="input">The input string.</param>
        public static ParseResult<Dictionary<string, object?>> Parse(string input)
        {
            var status = new ParseDataStatus(input);

            Utils.Trim(status);

            try
            {
                while (true)
                {
                    if (Utils.Accept('#', status))
                    {
                        ParseComment(status);
                        Utils.Trim(status);
                    }
                    else if (Utils.Accept('@', status))
                    {
                        ParseMacro(status);
                        Utils.Trim(status);
                    }
                    else
                    {
                        break;
                    }
                }

                if (Utils.Accept('{', status))
                {
                    var data = ParseObject(status);
                    if (status.Errors.Count == 0)
                    {
                        return new ParseResult<Dictionary<string, object?>>
                        {
                            Ok = true,
                            Data = new Dictionary<string, object?>(data)
                        };
                    }
                    else
                    {
                        return new ParseResult<Dictionary<string, object?>>
                        {
                            Ok = false,
                            Errors = status.Errors
                        };
                    }
                }
                else
                {
                    string found = status.I < status.Input.Length ? status.Input[status.I].ToString() : "undefined";
                    status.Errors.Add(new ParseError(
                        $"Expected '{{' but found '{found}'",
                        0,
                        1
                    ));
                    throw new ParseException();
                }
            }
            catch (ParseException)
            {
                return new ParseResult<Dictionary<string, object?>>
                {
                    Ok = false,
                    Errors = status.Errors
                };
            }
            catch (Exception)
            {
                throw;
            }
        }

        private static Dictionary<string, object?> ParseObject(ParseDataStatus status)
        {
            var result = new Dictionary<string, object?>();
            int start = status.I;

            while (true)
            {
                Utils.Trim(status);

                if (Utils.Accept('}', status))
                {
                    break;
                }
                else if (status.I >= status.Input.Length || Utils.Accept(']', status))
                {
                    status.Errors.Add(new ParseError(
                        "Object not closed",
                        start,
                        1
                    ));
                    throw new ParseException();
                }

                ParseField(result, status);

                Utils.Trim(status);
                Utils.Accept(',', status);
            }

            return result;
        }

        private static List<object?> ParseArray(ParseDataStatus status)
        {
            var result = new List<object?>();
            int start = status.I;

            while (true)
            {
                Utils.Trim(status);
                if (Utils.Accept(']', status))
                {
                    break;
                }
                else if (status.I >= status.Input.Length || Utils.Accept('}', status))
                {
                    status.Errors.Add(new ParseError(
                        "Array not closed",
                        start,
                        1
                    ));
                    throw new ParseException();
                }
                else if (result.Count > 0)
                {
                    Utils.Expect(',', status);
                    Utils.Trim(status);
                }

                var value = ParseValue(status);
                result.Add(value);
            }

            return result;
        }

        private static void ParseField(Dictionary<string, object?> result, ParseDataStatus status)
        {
            Utils.Trim(status);

            int start = status.I;

            if (Utils.Accept('#', status))
            {
                ParseComment(status);
                return;
            }

            string name;
            if (status.I < status.Input.Length && status.Input[status.I] == '"')
            {
                // Quoted field name - preserve the quotes
                int fieldStart = status.I;
                status.I++;
                while (status.I < status.Input.Length)
                {
                    if (status.Input[status.I] == '"')
                    {
                        // Check if this is an escaped quote ("")
                        if (status.I + 1 < status.Input.Length && status.Input[status.I + 1] == '"')
                        {
                            status.I += 2;
                        }
                        else
                        {
                            status.I++;
                            break;
                        }
                    }
                    else
                    {
                        status.I++;
                    }
                }
                name = status.Input.Substring(fieldStart, status.I - fieldStart);
            }
            else
            {
                if (status.I >= status.Input.Length || !char.IsLetter(status.Input[status.I]) && status.Input[status.I] != '_')
                {
                    status.Errors.Add(new ParseError(
                        "Field must start with quote or alpha",
                        start,
                        1
                    ));
                    throw new ParseException();
                }
                status.I++;
                while (status.I < status.Input.Length &&
                       (char.IsLetterOrDigit(status.Input[status.I]) || status.Input[status.I] == '_'))
                {
                    status.I++;
                }
                name = status.Input.Substring(start, status.I - start);
            }

            Utils.Trim(status);
            Utils.Expect(':', status);

            result[name] = ParseValue(status);
        }

        private static object? ParseValue(ParseDataStatus status)
        {
            Utils.Trim(status);
            if (Utils.Accept('{', status))
            {
                return ParseObject(status);
            }
            else if (Utils.Accept('[', status))
            {
                return ParseArray(status);
            }
            else if (Utils.Accept('"', status))
            {
                return ParseString(status);
            }
            else
            {
                return ParseType(status);
            }
        }

        private static object? ParseType(ParseDataStatus status)
        {
            int start = status.I;
            while (status.I < status.Input.Length &&
                   status.Input[status.I] != ' ' &&
                   status.Input[status.I] != '\t' &&
                   status.Input[status.I] != '|' &&
                   status.Input[status.I] != ',' &&
                   status.Input[status.I] != '}' &&
                   status.Input[status.I] != ']')
            {
                status.I++;
            }
            string value = status.Input.Substring(start, status.I - start).Trim();

            return ConvertValue.Convert(value, start, status.Errors);
        }

        private static string ParseString(ParseDataStatus status)
        {
            int start = status.I;
            for (; status.I < status.Input.Length; status.I++)
            {
                if (status.Input[status.I] == '\\')
                {
                    if (status.I + 1 < status.Input.Length && status.Input[status.I + 1] == '"')
                    {
                        status.I++;
                    }
                    else if (status.I + 1 < status.Input.Length)
                    {
                        status.Errors.Add(new ParseError(
                            $"Invalid escape sequence '\\{status.Input[status.I + 1]}'",
                            status.I,
                            2
                        ));
                    }
                }
                else if (status.Input[status.I] == '"')
                {
                    // Check if this is an escaped quote ("")
                    if (status.I + 1 < status.Input.Length && status.Input[status.I + 1] == '"')
                    {
                        status.I++; // Skip the second quote
                    }
                    else
                    {
                        break; // End of string
                    }
                }
            }

            if (status.I == status.Input.Length)
            {
                status.Errors.Add(new ParseError(
                    "String not closed",
                    start,
                    1
                ));
                throw new ParseException();
            }
            status.I++;
            string result = status.Input.Substring(start, status.I - start - 1);

            // Replace escaped quotes ("") with single quote (")
            result = result.Replace("\"\"", "\"");

            if (result.StartsWith("\n"))
            {
                int minIndent = int.MaxValue;
                int lineStart = 1;
                while (lineStart < result.Length)
                {
                    int indent = 0;
                    while (lineStart + indent < result.Length &&
                           (result[lineStart + indent] == ' ' || result[lineStart + indent] == '\t'))
                    {
                        indent++;
                    }

                    if (lineStart + indent < result.Length &&
                        result[lineStart + indent] != '\n' && indent < minIndent)
                    {
                        minIndent = indent;
                    }

                    while (lineStart < result.Length && result[lineStart] != '\n')
                    {
                        lineStart++;
                    }
                    lineStart++;
                }

                if (minIndent < int.MaxValue)
                {
                    var trimmed = new System.Text.StringBuilder();
                    int linePos = 1;
                    while (linePos < result.Length)
                    {
                        if (result[linePos] == '\n')
                        {
                            trimmed.Append('\n');
                            linePos++;
                            if (linePos < result.Length)
                            {
                                int skip = Math.Min(minIndent, result.Length - linePos);
                                linePos += skip;
                            }
                        }
                        else
                        {
                            trimmed.Append(result[linePos]);
                            linePos++;
                        }
                    }
                    result = trimmed.ToString().TrimStart();
                }
            }

            return result;
        }

        private static void ParseComment(ParseDataStatus status)
        {
            for (; status.I < status.Input.Length; status.I++)
            {
                if (status.Input[status.I] == '\n')
                {
                    break;
                }
            }
        }

        private static void ParseMacro(ParseDataStatus status)
        {
            int start = status.I;
            while (status.I < status.Input.Length &&
                   !char.IsWhiteSpace(status.Input[status.I]) &&
                   status.Input[status.I] != '(' &&
                   status.Input[status.I] != '"')
            {
                status.I++;
            }
            string macro = status.Input.Substring(start, status.I - start);

            switch (macro)
            {
                case "schema":
                    if (status.I < status.Input.Length && status.Input[status.I] == '(')
                    {
                        Utils.Expect('(', status);
                        Utils.Trim(status);
                        while (status.I < status.Input.Length && status.Input[status.I] != ')')
                        {
                            status.I++;
                        }
                        Utils.Trim(status);
                        Utils.Expect(')', status);
                    }
                    else if (status.I < status.Input.Length && status.Input[status.I] == '"')
                    {
                        Utils.Expect('"', status);
                        Utils.Trim(status);
                        while (status.I < status.Input.Length && status.Input[status.I] != '"')
                        {
                            status.I++;
                        }
                        Utils.Trim(status);
                        Utils.Expect('"', status);
                    }
                    break;

                default:
                    if (status.I < status.Input.Length && status.Input[status.I] == '(')
                    {
                        Utils.Expect('(', status);
                    }
                    start = status.I - macro.Length;
                    int level = 1;
                    for (; status.I < status.Input.Length; status.I++)
                    {
                        char ch = status.Input[status.I];
                        if (ch == '(' && status.Input[status.I - 1] != '\\')
                        {
                            level++;
                        }
                        else if (ch == ')' && status.Input[status.I - 1] != '\\')
                        {
                            level--;
                            if (level == 0) break;
                        }
                    }
                    status.Errors.Add(new ParseError(
                        $"Unknown macro: '{macro}'",
                        start,
                        macro.Length
                    ));
                    break;
            }
        }
    }
}
