using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using Sdnx.Core;

namespace Sdnx.Core
{
    public class CheckResult
    {
        public bool Ok { get; set; }
        public List<CheckError>? Errors { get; set; }

        public CheckResult()
        {
        }

        public CheckResult(bool ok, List<CheckError>? errors = null)
        {
            Ok = ok;
            Errors = errors;
        }
    }

    public static class CheckData
    {
        public static CheckResult Check(Dictionary<string, object?> input, Schema schema)
        {
            var status = new CheckStatus();

            CheckObject(input, schema.Fields, status);

            if (status.Errors.Count == 0)
            {
                return new CheckResult(true);
            }
            else
            {
                return new CheckResult(false, status.Errors);
            }
        }

        private static bool CheckObject(
            Dictionary<string, object?> input,
            Dictionary<string, SchemaValue> schema,
            CheckStatus status)
        {
            bool result = true;

            foreach (var kvp in schema)
            {
                string field = kvp.Key;
                SchemaValue fieldSchema = kvp.Value;

                status.Path.Add(field);

                if (field.StartsWith("def$"))
                {
                    if (fieldSchema is DefSchema defSchema)
                    {
                        status.Defs[defSchema.Name] = defSchema.Inner;
                    }
                }
                else if (field.StartsWith("ref$"))
                {
                    if (fieldSchema is RefSchema refSchema)
                    {
                        if (!CheckRef(input, refSchema, status))
                        {
                            result = false;
                        }
                    }
                }
                else if (field.StartsWith("mix$"))
                {
                    if (fieldSchema is MixSchema mixSchema)
                    {
                        if (!CheckMix(input, mixSchema, status))
                        {
                            result = false;
                        }
                    }
                }
                else if (field.StartsWith("props$"))
                {
                    if (fieldSchema is PropsSchema propsSchema)
                    {
                        if (!CheckProps(input, propsSchema, field, status))
                        {
                            result = false;
                        }
                    }
                }
                else
                {
                    object? value = null;
                    input.TryGetValue(field, out value);

                    if (!CheckField(value, fieldSchema, field, status))
                    {
                        result = false;
                    }
                }

                status.Path.RemoveAt(status.Path.Count - 1);
            }

            return result;
        }

        private static bool CheckArray(
            List<object?> input,
            SchemaValue innerSchema,
            string field,
            CheckStatus status)
        {
            bool result = true;

            for (int i = 0; i < input.Count; i++)
            {
                object? value = input[i];
                status.Path.Add(i.ToString());

                if (!CheckField(value, innerSchema, i.ToString(), status))
                {
                    result = false;
                }

                status.Path.RemoveAt(status.Path.Count - 1);
            }

            return result;
        }

        private static bool CheckUnion(
            object? value,
            UnionSchema schema,
            string field,
            CheckStatus status)
        {
            var fieldStatus = new CheckStatus
            {
                Path = new List<string>(status.Path),
                Errors = new List<CheckError>(),
                Defs = new Dictionary<string, Dictionary<string, SchemaValue>>(status.Defs)
            };

            bool ok = false;
            foreach (var fs in schema.Inner)
            {
                if (CheckField(value, fs, field, fieldStatus))
                {
                    ok = true;
                    break;
                }
            }

            if (!ok)
            {
                status.Errors.Add(new CheckError(
                    new List<string>(status.Path),
                    string.Join(" | ", fieldStatus.Errors.Select(e => e.Message))
                ));
            }

            return ok;
        }

        private static bool CheckRef(
            Dictionary<string, object?> input,
            RefSchema refSchema,
            CheckStatus status)
        {
            if (!status.Defs.TryGetValue(refSchema.Inner, out var def))
            {
                status.Errors.Add(new CheckError(
                    new List<string>(status.Path),
                    $"Undefined def: {refSchema.Inner}"
                ));
                return false;
            }

            return CheckObject(input, def, status);
        }

        private static bool CheckMix(
            Dictionary<string, object?> input,
            MixSchema schema,
            CheckStatus status)
        {
            var fieldErrors = new List<CheckError>();
            bool ok = false;

            foreach (var fs in schema.Inner)
            {
                var fieldStatus = new CheckStatus
                {
                    Path = new List<string>(status.Path),
                    Errors = new List<CheckError>(),
                    Defs = new Dictionary<string, Dictionary<string, SchemaValue>>(status.Defs)
                };

                if (CheckObject(input, fs, fieldStatus))
                {
                    ok = true;
                    break;
                }
                else
                {
                    fieldErrors.Add(new CheckError(
                        new List<string>(status.Path),
                        string.Join(" & ", fieldStatus.Errors.Select(e => e.Message))
                    ));
                }
            }

            if (!ok)
            {
                status.Errors.Add(new CheckError(
                    new List<string>(status.Path),
                    string.Join(" | ", fieldErrors.Select(e => e.Message))
                ));
            }

            return ok;
        }

        private static bool CheckProps(
            Dictionary<string, object?> input,
            PropsSchema schema,
            string field,
            CheckStatus status)
        {
            bool result = true;

            foreach (var kvp in input)
            {
                string anyField = kvp.Key;

                if (!string.IsNullOrEmpty(schema.Type))
                {
                    var regexp = Utils.CreateRegex(schema.Type);
                    if (regexp == null)
                    {
                        status.Errors.Add(new CheckError(
                            new List<string>(status.Path),
                            $"Unsupported pattern for '{field}': {schema.Type}"
                        ));
                        return false;
                    }

                    if (!regexp.IsMatch(anyField))
                    {
                        status.Errors.Add(new CheckError(
                            new List<string>(status.Path),
                            $"'{anyField}' name doesn't match pattern '{schema.Type}'"
                        ));
                        return false;
                    }
                }

                object? value = kvp.Value;

                if (!CheckField(value, schema.Inner, anyField, status))
                {
                    result = false;
                }
            }

            return result;
        }

        private static bool CheckField(
            object? value,
            SchemaValue schema,
            string field,
            CheckStatus status)
        {
            status.Path.Add(field);

            bool result;

            if (schema is ObjectSchema objectSchema)
            {
                if (!CheckUndefined(value, objectSchema, field, status))
                {
                    result = false;
                }
                else
                {
                    if (value == null || value is not Dictionary<string, object?>)
                    {
                        status.Errors.Add(new CheckError(
                            new List<string>(status.Path),
                            $"'{field}' must be an object"
                        ));
                        result = false;
                    }
                    else
                    {
                        result = CheckObject((Dictionary<string, object?>)value, objectSchema.Inner, status);
                    }
                }
            }
            else if (schema is ArraySchema arraySchema)
            {
                if (!CheckUndefined(value, arraySchema, field, status))
                {
                    result = false;
                }
                else
                {
                    if (value is not List<object?>)
                    {
                        status.Errors.Add(new CheckError(
                            new List<string>(status.Path),
                            $"'{field}' must be an array"
                        ));
                        result = false;
                    }
                    else
                    {
                        result = CheckArray((List<object?>)value, arraySchema.Inner, field, status);
                    }
                }
            }
            else if (schema is UnionSchema unionSchema)
            {
                result = CheckUnion(value, unionSchema, field, status);
            }
            else if (schema is FieldSchema fieldSchema)
            {
                result = CheckFieldSchema(value, fieldSchema, field, status);
            }
            else
            {
                result = true;
            }

            status.Path.RemoveAt(status.Path.Count - 1);
            return result;
        }

        private static bool CheckFieldSchema(
            object? value,
            FieldSchema schema,
            string field,
            CheckStatus status)
        {
            if (!CheckUndefined(value, schema, field, status))
            {
                return false;
            }

            switch (schema.Type)
            {
                case "undef":
                    if (value != null)
                    {
                        status.Errors.Add(new CheckError(
                            new List<string>(status.Path),
                            $"'{field}' must be undefined"
                        ));
                        return false;
                    }
                    return true;

                case "null":
                    if (value != null)
                    {
                        status.Errors.Add(new CheckError(
                            new List<string>(status.Path),
                            $"'{field}' must be null"
                        ));
                        return false;
                    }
                    return true;

                case "bool":
                    if (value is not bool)
                    {
                        status.Errors.Add(new CheckError(
                            new List<string>(status.Path),
                            $"'{field}' must be a boolean value"
                        ));
                        return false;
                    }
                    return RunValidators(value, schema, field, status);

                case "int":
                    if (value is not int)
                    {
                        status.Errors.Add(new CheckError(
                            new List<string>(status.Path),
                            $"'{field}' must be an integer value"
                        ));
                        return false;
                    }
                    return RunValidators(value, schema, field, status);

                case "num":
                    if (value is not double && value is not int && value is not float)
                    {
                        status.Errors.Add(new CheckError(
                            new List<string>(status.Path),
                            $"'{field}' must be a number value"
                        ));
                        return false;
                    }
                    return RunValidators(value, schema, field, status);

                case "date":
                    if (value is not DateTime)
                    {
                        status.Errors.Add(new CheckError(
                            new List<string>(status.Path),
                            $"'{field}' must be a date value"
                        ));
                        return false;
                    }
                    return RunValidators(value, schema, field, status);

                case "string":
                    if (value is not string)
                    {
                        status.Errors.Add(new CheckError(
                            new List<string>(status.Path),
                            $"'{field}' must be a string value"
                        ));
                        return false;
                    }
                    return RunValidators(value, schema, field, status);

                default:
                    string expectedType = schema.Type;

                    if (expectedType.StartsWith("\"") && expectedType.EndsWith("\""))
                    {
                        expectedType = expectedType.Substring(1, expectedType.Length - 2);
                    }

                    string valueStr;
                    if (value is bool boolValue)
                    {
                        valueStr = boolValue.ToString().ToLowerInvariant();
                    }
                    else
                    {
                        valueStr = value?.ToString() ?? "null";
                    }

                    if (expectedType != valueStr)
                    {
                        status.Errors.Add(new CheckError(
                            new List<string>(status.Path),
                            $"'{field}' must be '{expectedType}'"
                        ));
                        return false;
                    }

                    return true;
            }
        }

        private static bool RunValidators(
            object? value,
            FieldSchema schema,
            string field,
            CheckStatus status)
        {
            if (schema.Validators == null)
            {
                return true;
            }

            foreach (var kvp in schema.Validators)
            {
                string method = kvp.Key;
                Validator validator = kvp.Value;

                if (method == "type" || method == "description")
                {
                    continue;
                }

                if (!Validators.All.TryGetValue(schema.Type, out var typeValidators) ||
                    typeValidators == null ||
                    !typeValidators.TryGetValue(method, out var validate))
                {
                    continue;
                }

                if (validate == null)
                {
                    status.Errors.Add(new CheckError(
                        new List<string>(status.Path),
                        $"Unsupported validation method for '{field}': {method}"
                    ));
                    return false;
                }

                if (!validate(field, value, validator.Raw, validator.Required, status))
                {
                    return false;
                }
            }

            return true;
        }

        private static bool CheckUndefined(
            object? value,
            SchemaValue schema,
            string field,
            CheckStatus status)
        {
            if (value == null && schema is not FieldSchema)
            {
                status.Errors.Add(new CheckError(
                    new List<string>(status.Path),
                    $"Field not found: {field}"
                ));
                return false;
            }

            if (schema is FieldSchema fieldSchema)
            {
                if (value == null && fieldSchema.Type != "undef" && fieldSchema.Type != "null")
                {
                    status.Errors.Add(new CheckError(
                        new List<string>(status.Path),
                        $"Field not found: {field}"
                    ));
                    return false;
                }
            }

            return true;
        }
    }
}
