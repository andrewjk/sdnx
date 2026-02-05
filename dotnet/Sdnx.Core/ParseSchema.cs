using System;
using System.Collections.Generic;
using System.Text.RegularExpressions;
using Sdnx.Core;

namespace Sdnx.Core
{
    public class ParseSchemaStatus : ParseStatus
    {
        public string Description { get; set; } = string.Empty;
        public int Def { get; set; } = 1;
        public int Mix { get; set; } = 1;
        public int Any { get; set; } = 1;
        public HashSet<string> Refs { get; set; }

        public ParseSchemaStatus() : base()
        {
            Refs = new HashSet<string>();
        }

        public ParseSchemaStatus(string input) : base(input)
        {
            Refs = new HashSet<string>();
        }
    }

    public static class ParseSchema
    {
        /// <summary>
        /// Parses some structured data from a string into an object.
        /// </summary>
        /// <param name="input">The input string.</param>
        public static ParseResult<Schema> Parse(string input)
        {
            var status = new ParseSchemaStatus(input);

            Utils.Trim(status);

            try
            {
                if (Utils.Accept('{', status))
                {
                    var data = ParseObject(status);
                    if (status.Errors.Count == 0)
                    {
                        return new ParseResult<Schema>
                        {
                            Ok = true,
                            Data = new Schema(data)
                        };
                    }
                    else
                    {
                        return new ParseResult<Schema>
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
                // Handle our errors and throw others
                return new ParseResult<Schema>
                {
                    Ok = false,
                    Errors = status.Errors
                };
            }
        }

        private static Dictionary<string, SchemaValue> ParseObject(ParseSchemaStatus status)
        {
            var result = new Dictionary<string, SchemaValue>();
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
                        "Schema object not closed",
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

        private static SchemaValue ParseArray(ParseSchemaStatus status)
        {
            Utils.Trim(status);
            int start = status.I;

            if (Utils.Accept(']', status))
            {
                status.Errors.Add(new ParseError(
                    "Schema array empty",
                    start,
                    status.I - start
                ));
            }
            else if (Utils.Accept('}', status))
            {
                status.Errors.Add(new ParseError(
                    "Schema array not closed",
                    start,
                    1
                ));
                throw new ParseException();
            }

            var value = ParseValue(status);

            Utils.Trim(status);
            if (status.I >= status.Input.Length || !Utils.Accept(']', status))
            {
                status.Errors.Add(new ParseError(
                    "Schema array not closed",
                    start,
                    1
                ));
                throw new ParseException();
            }

            return value;
        }

        private static void ParseField(Dictionary<string, SchemaValue> result, ParseSchemaStatus status)
        {
            Utils.Trim(status);

            int start = status.I;

            // Check for comments
            if (Utils.Accept('#', status))
            {
                bool addDescription = Utils.Accept('#', status);
                for (; status.I < status.Input.Length; status.I++)
                {
                    if (status.Input[status.I] == '\n')
                    {
                        break;
                    }
                }
                if (addDescription)
                {
                    status.Description += status.Input.Substring(start + 2, status.I - (start + 2));
                }
                return;
            }

            // Check for macros
            if (Utils.Accept('@', status))
            {
                // Consume until space or `(`
                int macroStart = status.I;
                while (status.I < status.Input.Length &&
                       !char.IsWhiteSpace(status.Input[status.I]) &&
                       status.Input[status.I] != '(')
                {
                    status.I++;
                }
                string macro = status.Input.Substring(macroStart, status.I - macroStart);
                Utils.Trim(status);
                Utils.Expect('(', status);

                switch (macro)
                {
                    case "def":
                        Utils.Trim(status);
                        int refNameStart = status.I;
                        while (status.I < status.Input.Length && status.Input[status.I] != ')')
                        {
                            status.I++;
                        }
                        string @ref = status.Input.Substring(refNameStart, status.I - refNameStart).Trim();

                        // TODO: Should allow any valid prop name, including surrounded by quotes
                        if (Regex.IsMatch(@ref, @"[:\s]"))
                        {
                            status.Errors.Add(new ParseError(
                                $"Invalid reference name '{@ref}'",
                                refNameStart,
                                @ref.Length
                            ));
                        }
                        status.I++;
                        Utils.Trim(status);
                        Utils.Expect(':', status);
                        Utils.Trim(status);
                        Utils.Expect('{', status);
                        status.Refs.Add(@ref);

                        var defSchema = new DefSchema
                        {
                            Type = "def",
                            Name = @ref,
                            Inner = ParseObject(status)
                        };
                        result[$"def${status.Def++}"] = defSchema;
                        break;

                    case "mix":
                        Utils.Trim(status);
                        var mixInner = new List<Dictionary<string, SchemaValue>>();

                        while (true)
                        {
                            Utils.Trim(status);
                            if (Utils.Accept('{', status))
                            {
                                mixInner.Add(ParseObject(status));
                            }
                            else
                            {
                                int refNameStart2 = status.I;
                                while (status.I < status.Input.Length &&
                                       status.Input[status.I] != '|' &&
                                       status.Input[status.I] != ')')
                                {
                                    status.I++;
                                }
                                string refName2 = status.Input.Substring(refNameStart2, status.I - refNameStart2).Trim();

                                if (status.Refs.Contains(refName2))
                                {
                                    var refSchema = new RefSchema
                                    {
                                        Type = "ref",
                                        Inner = refName2
                                    };
                                    var refResult = new Dictionary<string, SchemaValue>
                                    {
                                        ["ref$1"] = refSchema
                                    };
                                    mixInner.Add(refResult);
                                }
                                else
                                {
                                    status.Errors.Add(new ParseError(
                                        $"Unknown reference: '{refName2}'",
                                        refNameStart2,
                                        refName2.Length
                                    ));
                                }
                            }
                            Utils.Trim(status);
                            if (!Utils.Accept('|', status))
                            {
                                break;
                            }
                        }
                        Utils.Expect(')', status);

                        var mixSchema = new MixSchema
                        {
                            Type = "mix",
                            Inner = mixInner
                        };
                        result[$"mix${status.Mix++}"] = mixSchema;
                        break;

                    case "props":
                        Utils.Trim(status);
                        // Consume until space or `)`
                        int patternStart = status.I;
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
                            else if (char.IsWhiteSpace(ch))
                            {
                                break;
                            }
                        }
                        string pattern = status.Input.Substring(patternStart, status.I - patternStart);
                        Utils.Trim(status);
                        Utils.Expect(')', status);
                        Utils.Trim(status);
                        Utils.Expect(':', status);

                        var propsSchema = new PropsSchema
                        {
                            Type = pattern,
                            Inner = ParseValue(status)
                        };
                        result[$"props${status.Mix++}"] = propsSchema;
                        break;

                    default:
                        // Consume until `)`
                        int macroErrorStart = status.I - macro.Length;
                        level = 1;
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
                            macroErrorStart,
                            macro.Length
                        ));
                        break;
                }
                return;
            }

            string name;
            if (Utils.Accept('"', status))
            {
                name = ParseString(status);
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

        private static SchemaValue ParseValue(ParseSchemaStatus status)
        {
            var value = ParseSingleValue(status);

            Utils.Trim(status);
            if (Utils.Accept('|', status))
            {
                var unionInner = new List<SchemaValue> { value };
                while (true)
                {
                    Utils.Trim(status);
                    unionInner.Add(ParseSingleValue(status));
                    Utils.Trim(status);

                    if (!Utils.Accept('|', status))
                    {
                        break;
                    }
                }
                value = new UnionSchema
                {
                    Type = "union",
                    Inner = unionInner
                };
            }

            return value;
        }

        private static SchemaValue ParseSingleValue(ParseSchemaStatus status)
        {
            Utils.Trim(status);
            if (Utils.Accept('{', status))
            {
                return new ObjectSchema
                {
                    Type = "object",
                    Inner = ParseObject(status)
                };
            }
            else if (Utils.Accept('[', status))
            {
                var result = new ArraySchema
                {
                    Type = "array",
                    Inner = ParseArray(status)
                };
                return ParseValidators(result, status);
            }
            else if (Utils.Accept('"', status))
            {
                string typeValue = ParseString(status);
                return new FieldSchema
                {
                    Type = typeValue
                };
            }
            else
            {
                return ParseType(status);
            }
        }

        private static SchemaValue ParseType(ParseSchemaStatus status)
        {
            // Parse and check the type
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
            string type = status.Input.Substring(start, status.I - start).Trim();

            var validTypes = new HashSet<string> { "undef", "null", "bool", "int", "num", "string", "date" };
            if (!validTypes.Contains(type) && !status.Refs.Contains(type))
            {
                ConvertValue.Convert(type, start, status.Errors);
            }

            // Create a field schema
            FieldSchema result = new FieldSchema
            {
                Type = type
            };

            if (!string.IsNullOrEmpty(status.Description))
            {
                result = result with { Description = status.Description.Trim() };
                status.Description = string.Empty;
            }

            return ParseValidators(result, status);
        }

        private static SchemaValue ParseValidators(SchemaValue field, ParseSchemaStatus status)
        {
            // Only certain schema types support validators - skip array, object, def, etc.
            if (field is ArraySchema)
            {
                return field;
            }
            if (field is ObjectSchema)
            {
                return field;
            }
            if (field is DefSchema)
            {
                return field;
            }
            if (field is MixSchema)
            {
                return field;
            }
            if (field is PropsSchema)
            {
                return field;
            }
            if (field is RefSchema)
            {
                return field;
            }
            if (field is UnionSchema)
            {
                return field;
            }

            if (field is not FieldSchema baseField)
            {
                return field;
            }

            // Add validators
            Utils.Trim(status);
            while (status.I < status.Input.Length &&
                   status.Input[status.I] != '|' &&
                   status.Input[status.I] != ',' &&
                   status.Input[status.I] != '}' &&
                   status.Input[status.I] != ']')
            {
                // Parse and check the validator
                int start = status.I;
                while (status.I < status.Input.Length &&
                       status.Input[status.I] != ' ' &&
                       status.Input[status.I] != '\t' &&
                       status.Input[status.I] != '|' &&
                       status.Input[status.I] != ',' &&
                       status.Input[status.I] != '}' &&
                       status.Input[status.I] != ']' &&
                       status.Input[status.I] != '(')
                {
                    status.I++;
                }
                string validator = status.Input.Substring(start, status.I - start);

                if (Validators.All.TryGetValue(baseField.Type, out var typeValidators) &&
                    typeValidators != null &&
                    !typeValidators.ContainsKey(validator))
                {
                    status.Errors.Add(new ParseError(
                        $"Unsupported validator '{validator}'",
                        start,
                        status.I - start
                    ));
                }

                string raw = "true";
                object? required = true;

                Utils.Trim(status);
                if (Utils.Accept('(', status))
                {
                    Utils.Trim(status);
                    int valueStart = status.I;

                    if (Utils.Accept('"', status))
                    {
                        raw = ParseString(status);
                        required = ConvertValue.Convert(raw, start, status.Errors);
                    }
                    else if (Utils.Accept('/', status))
                    {
                        raw = ParseRegex(status);
                        required = ConvertValue.Convert(raw, start, status.Errors);
                    }
                    else
                    {
                        // Consume until a space or closing bracket
                        int valueStart2 = status.I;
                        while (status.I < status.Input.Length &&
                               !char.IsWhiteSpace(status.Input[status.I]) &&
                               status.Input[status.I] != ')')
                        {
                            status.I++;
                        }
                        raw = status.Input.Substring(valueStart2, status.I - valueStart2);
                        required = ConvertValue.Convert(raw, start, status.Errors);
                    }
                    Utils.Trim(status);
                    Utils.Expect(')', status);
                    Utils.Trim(status);
                }

                var validators = baseField.Validators ?? new Dictionary<string, Validator>();
                validators[validator] = new Validator
                {
                    Raw = raw,
                    Required = required
                };
                baseField = baseField with { Validators = validators };
            }

            return baseField;
        }

        private static string ParseString(ParseSchemaStatus status)
        {
            int start = status.I - 1;
            for (; status.I < status.Input.Length; status.I++)
            {
                if (status.Input[status.I] == '\\')
                {
                    status.I++;
                    if (status.I < status.Input.Length && status.Input[status.I] != '"')
                    {
                        status.Errors.Add(new ParseError(
                            $"Invalid escape sequence '\\{status.Input[status.I]}'",
                            status.I - 1,
                            2
                        ));
                    }
                }
                else if (status.Input[status.I] == '"')
                {
                    break;
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
            return status.Input.Substring(start, status.I - start);
        }

        private static string ParseRegex(ParseSchemaStatus status)
        {
            int start = status.I - 1;
            while (status.I < status.Input.Length &&
                   !(status.Input[status.I] == '/' && status.Input[status.I - 1] != '\\'))
            {
                status.I++;
            }

            if (status.I == status.Input.Length)
            {
                status.Errors.Add(new ParseError(
                    "Pattern not closed",
                    start,
                    1
                ));
                throw new ParseException();
            }

            while (status.I < status.Input.Length &&
                   !char.IsWhiteSpace(status.Input[status.I]) &&
                   status.Input[status.I] != ')')
            {
                status.I++;
            }

            return status.Input.Substring(start, status.I - start);
        }
    }
}
