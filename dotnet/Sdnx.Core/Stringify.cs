using System;
using System.Collections.Generic;
using System.Globalization;

namespace Sdnx.Core
{
    public class StringifyOptions
    {
        public bool Ansi { get; set; } = false;
        public string Indent { get; set; } = "\t";
    }

    public static class Stringify
    {
        private class Status
        {
            public int Indent { get; set; }
            public string Result { get; set; } = string.Empty;
            public bool Ansi { get; set; }
            public string IndentText { get; set; }

            public Status(bool ansi, string indentText)
            {
                Ansi = ansi;
                IndentText = indentText;
            }
        }

        /// <summary>
        /// Converts an object into a string containing Structured Data Notation.
        /// </summary>
        public static string Convert(Dictionary<string, object?> obj, StringifyOptions? options = null)
        {
            var status = new Status(
                options?.Ansi ?? false,
                options?.Indent ?? "\t"
            );

            PrintValue(obj, status);

            return status.Result;
        }

        private static void PrintValue(object? obj, Status status)
        {
            if (obj == null)
            {
                status.Result += "null";
            }
            else if (obj is List<object?> list)
            {
                status.Result += "[";
                status.Indent += 1;

                for (int i = 0; i < list.Count; i++)
                {
                    status.Result += "\n";
                    Indent(status);
                    PrintValue(list[i], status);
                    if (i < list.Count - 1)
                    {
                        status.Result += ",";
                    }
                }

                status.Indent -= 1;
                status.Result += "\n";
                Indent(status);
                status.Result += "]";
            }
            else if (obj is DateTime date)
            {
                string dateStr = FormatDate(date);
                status.Result += status.Ansi ? $"\u001b[35m{dateStr}\u001b[0m" : dateStr;
            }
            else if (obj is Dictionary<string, object?> dict)
            {
                status.Result += "{";
                status.Indent += 1;

                var keys = new List<string>(dict.Keys);
                for (int i = 0; i < keys.Count; i++)
                {
                    status.Result += "\n";
                    string key = keys[i];
                    Indent(status);
                    status.Result += key + ": ";
                    PrintValue(dict[key], status);
                    if (i < keys.Count - 1)
                    {
                        status.Result += ",";
                    }
                }

                status.Indent -= 1;
                status.Result += "\n";
                Indent(status);
                status.Result += "}";
            }
            else if (obj is string str)
            {
                status.Result += status.Ansi ? $"\u001b[32m\"{str}\"\u001b[0m" : $"\"{str}\"";
            }
            else if (obj is double num)
            {
                status.Result += status.Ansi ? $"\u001b[33m{num}\u001b[0m" : num.ToString();
            }
            else if (obj is int intNum)
            {
                status.Result += status.Ansi ? $"\u001b[33m{intNum}\u001b[0m" : intNum.ToString();
            }
            else if (obj is bool boolean)
            {
                var boolStr = boolean.ToString().ToLowerInvariant();
                status.Result += status.Ansi ? $"\u001b[34m{boolStr}\u001b[0m" : boolStr;
            }
            else
            {
                status.Result += obj.ToString();
            }
        }

        private static void Indent(Status status)
        {
            status.Result += new string(status.IndentText[0], status.Indent * status.IndentText.Length);
        }

        private static string FormatDate(DateTime date)
        {
            string year = date.Year.ToString();
            string month = date.Month.ToString().PadLeft(2, '0');
            string day = date.Day.ToString().PadLeft(2, '0');
            string hours = date.Hour.ToString().PadLeft(2, '0');
            string minutes = date.Minute.ToString().PadLeft(2, '0');
            string seconds = date.Second.ToString().PadLeft(2, '0');

            if (hours == "00" && minutes == "00" && seconds == "00")
            {
                return $"{year}-{month}-{day}";
            }
            else
            {
                return $"{year}-{month}-{day}T{hours}:{minutes}";
            }
        }
    }
}
