using System;
using System.Collections.Generic;
using System.Text.RegularExpressions;
using Sdnx.Core;

namespace Sdnx.Core
{
    public delegate bool ValidatorFunction(
        string field,
        object? value,
        string raw,
        object? required,
        CheckStatus status
    );

    public static class Validators
    {
        // TODO: array minval, maxval

        public static readonly Dictionary<string, Dictionary<string, ValidatorFunction>> All = new()
        {
            ["bool"] = new Dictionary<string, ValidatorFunction>(),
            ["int"] = new Dictionary<string, ValidatorFunction>
            {
                ["min"] = Min,
                ["max"] = Max
            },
            ["num"] = new Dictionary<string, ValidatorFunction>
            {
                ["min"] = Min,
                ["max"] = Max
            },
            ["date"] = new Dictionary<string, ValidatorFunction>
            {
                ["min"] = MinDate,
                ["max"] = MaxDate
            },
            ["string"] = new Dictionary<string, ValidatorFunction>
            {
                ["minlen"] = Minlen,
                ["maxlen"] = Maxlen,
                ["pattern"] = Pattern
            },
            ["array"] = new Dictionary<string, ValidatorFunction>
            {
                ["minlen"] = MinlenArray,
                ["maxlen"] = MaxlenArray,
                ["unique"] = Unique
            }
        };

        public static bool Min(string field, object? value, string raw, object? required, CheckStatus status)
        {
            double numValue = 0;
            if (value is int intVal)
            {
                numValue = intVal;
            }
            else if (value is double doubleVal)
            {
                numValue = doubleVal;
            }
            else
            {
                return true;
            }

            double requiredValue = 0;
            if (required is int reqInt)
            {
                requiredValue = reqInt;
            }
            else if (required is double reqDouble)
            {
                requiredValue = reqDouble;
            }
            else
            {
                return true;
            }

            if (numValue < requiredValue)
            {
                status.Errors.Add(new CheckError(new List<string>(status.Path), $"'{field}' must be at least {raw}"));
                return false;
            }
            return true;
        }

        public static bool Max(string field, object? value, string raw, object? required, CheckStatus status)
        {
            double numValue = 0;
            if (value is int intVal)
            {
                numValue = intVal;
            }
            else if (value is double doubleVal)
            {
                numValue = doubleVal;
            }
            else
            {
                return true;
            }

            double requiredValue = 0;
            if (required is int reqInt)
            {
                requiredValue = reqInt;
            }
            else if (required is double reqDouble)
            {
                requiredValue = reqDouble;
            }
            else
            {
                return true;
            }

            if (numValue > requiredValue)
            {
                status.Errors.Add(new CheckError(new List<string>(status.Path), $"'{field}' cannot be more than {raw}"));
                return false;
            }
            return true;
        }

        public static bool MinDate(string field, object? value, string raw, object? required, CheckStatus status)
        {
            if (value is not DateTime dateValue)
            {
                return true;
            }

            DateTime requiredDate;
            if (required is DateTime reqDate)
            {
                requiredDate = reqDate;
            }
            else if (required is string reqStr && DateTime.TryParse(reqStr, out var parsedDate))
            {
                requiredDate = parsedDate;
            }
            else
            {
                return true;
            }

            if (dateValue < requiredDate)
            {
                status.Errors.Add(new CheckError(new List<string>(status.Path), $"'{field}' must be at least {raw}"));
                return false;
            }
            return true;
        }

        public static bool MaxDate(string field, object? value, string raw, object? required, CheckStatus status)
        {
            if (value is not DateTime dateValue)
            {
                return true;
            }

            DateTime requiredDate;
            if (required is DateTime reqDate)
            {
                requiredDate = reqDate;
            }
            else if (required is string reqStr && DateTime.TryParse(reqStr, out var parsedDate))
            {
                requiredDate = parsedDate;
            }
            else
            {
                return true;
            }

            if (dateValue > requiredDate)
            {
                status.Errors.Add(new CheckError(new List<string>(status.Path), $"'{field}' cannot be after {raw}"));
                return false;
            }
            return true;
        }

        public static bool Minlen(string field, object? value, string raw, object? required, CheckStatus status)
        {
            if (value is not string strValue)
            {
                return true;
            }

            int requiredValue = 0;
            if (required is int reqInt)
            {
                requiredValue = reqInt;
            }
            else if (required is double reqDouble)
            {
                requiredValue = (int)reqDouble;
            }
            else
            {
                return true;
            }

            if (strValue.Length < requiredValue)
            {
                status.Errors.Add(new CheckError(new List<string>(status.Path), $"'{field}' must be at least {raw} characters"));
                return false;
            }
            return true;
        }

        public static bool Maxlen(string field, object? value, string raw, object? required, CheckStatus status)
        {
            if (value is not string strValue)
            {
                return true;
            }

            int requiredValue = 0;
            if (required is int reqInt)
            {
                requiredValue = reqInt;
            }
            else if (required is double reqDouble)
            {
                requiredValue = (int)reqDouble;
            }
            else
            {
                return true;
            }

            if (strValue.Length > requiredValue)
            {
                status.Errors.Add(new CheckError(new List<string>(status.Path), $"'{field}' cannot be more than {raw} characters"));
                return false;
            }
            return true;
        }

        public static bool Pattern(string field, object? value, string raw, object? required, CheckStatus status)
        {
            if (value is string strValue && required is string patternStr)
            {
                var regex = Utils.CreateRegex(patternStr);
                if (regex == null)
                {
                    // This should never happen...
                    status.Errors.Add(new CheckError(new List<string>(status.Path), $"Unsupported pattern for '{field}': {raw}"));
                    return false;
                }

                if (!regex.IsMatch(strValue))
                {
                    status.Errors.Add(new CheckError(new List<string>(status.Path), $"'{field}' doesn't match pattern '{raw}'"));
                    return false;
                }
            }
            return true;
        }

        public static bool MinlenArray(string field, object? value, string raw, object? required, CheckStatus status)
        {
            if (value is Array arrValue && required is double requiredValue)
            {
                if (arrValue.Length < requiredValue)
                {
                    status.Errors.Add(new CheckError(new List<string>(status.Path), $"'{field}' must contain at least {raw} items"));
                    return false;
                }
            }
            return true;
        }

        public static bool MaxlenArray(string field, object? value, string raw, object? required, CheckStatus status)
        {
            if (value is Array arrValue && required is double requiredValue)
            {
                if (arrValue.Length > requiredValue)
                {
                    status.Errors.Add(new CheckError(new List<string>(status.Path), $"'{field}' cannot contain more than {raw} items"));
                    return false;
                }
            }
            return true;
        }

        public static bool Unique(string field, object? value, string raw, object? required, CheckStatus status)
        {
            // Maybe only use a Set if longer than a certain length?
            if (value is Array arrValue)
            {
                var set = new HashSet<object?>();
                bool ok = true;

                foreach (var item in arrValue)
                {
                    if (set.Contains(item))
                    {
                        status.Errors.Add(new CheckError(new List<string>(status.Path), $"'{field}' value '{item}' is not unique"));
                        ok = false;
                    }
                    else
                    {
                        set.Add(item);
                    }
                }

                return ok;
            }
            return true;
        }
    }
}
