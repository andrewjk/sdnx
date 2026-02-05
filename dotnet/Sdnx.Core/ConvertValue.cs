using System;
using System.Collections.Generic;
using System.Text.RegularExpressions;
using Sdnx.Core;

namespace Sdnx.Core
{
    public static class ConvertValue
    {
        private static readonly Regex IntRegex = new Regex(@"^(\+|-)?[\d_]+$");
        private static readonly Regex HexRegex = new Regex(@"^(\+|-)?0x[0-9a-f]+$", RegexOptions.IgnoreCase);
        private static readonly Regex FloatRegex = new Regex(@"^(\+|-)?[\d_]+\.[\d_]+$");
        private static readonly Regex ScientificRegex = new Regex(@"^(\+|-)?\d+(?:\.\d+)?[eE]-?\d+$");
        private static readonly Regex StringRegex = new Regex(@"^"".*""$");
        private static readonly Regex RegexRegex = new Regex(@"^\/.*\/[gmixsuAJD]*$");
        private static readonly Regex DateRegex = new Regex(@"\d{4}-\d{2}-\d{2}");
        private static readonly Regex TimeRegex = new Regex(@"\d{2}:\d{2}(?:\d{2})? ?(?:U|L|(?:(?:\+|-)\d{2}:\d{2}))?");
        private static readonly Regex DateTimeRegex = new Regex(@"\d{4}-\d{2}-\d{2}(?:T| )\d{2}:\d{2}(?:\d{2})? ?(?:U|L|(?:(?:\+|-)\d{2}:\d{2}))?");

        public static object? Convert(string value, int start, List<ParseError> errors)
        {
            if (value == "null")
            {
                return null;
            }
            else if (value == "true")
            {
                return true;
            }
            else if (value == "false")
            {
                return false;
            }
            else if (StringRegex.IsMatch(value))
            {
                return value.Substring(1, value.Length - 2);
            }
            else if (RegexRegex.IsMatch(value))
            {
                return value;
            }
            else if (ScientificRegex.IsMatch(value))
            {
                return double.Parse(value.Replace("_", ""));
            }
            else if (IntRegex.IsMatch(value))
            {
                string cleanValue = value.Replace("_", "");
                if (long.TryParse(cleanValue, out var longValue))
                {
                    if (longValue >= int.MinValue && longValue <= int.MaxValue)
                    {
                        return (int)longValue;
                    }
                    else
                    {
                        return longValue;
                    }
                }
                return null;
            }
            else if (HexRegex.IsMatch(value))
            {
                return System.Convert.ToInt32(value.Replace("_", ""), 16);
            }
            else if (FloatRegex.IsMatch(value))
            {
                return double.Parse(value.Replace("_", ""));
            }
            else if (DateRegex.IsMatch(value) || DateTimeRegex.IsMatch(value))
            {
                string dateStr = value.Replace("U", "Z").Replace("L", "");
                if (DateTime.TryParse(dateStr, out var date))
                {
                    return date;
                }
                else
                {
                    errors.Add(new ParseError(
                        $"Invalid date '{value}'",
                        start,
                        value.Length
                    ));
                    return null;
                }
            }
            else if (TimeRegex.IsMatch(value))
            {
                // HACK: Is there a better way to store a time without a date in C#?
                string timeStr = "1900-01-01T" + value.Replace("U", "Z").Replace("L", "").Replace(" ", "");
                if (DateTime.TryParse(timeStr, out var time))
                {
                    return time;
                }
                else
                {
                    errors.Add(new ParseError(
                        $"Invalid time '{value}'",
                        start,
                        value.Length
                    ));
                    return null;
                }
            }
            else
            {
                errors.Add(new ParseError(
                    $"Unsupported value type '{value}'",
                    start,
                    value.Length
                ));
                return null;
            }
        }
    }
}
