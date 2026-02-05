using System;
using System.Text.RegularExpressions;
using Sdnx.Core;

namespace Sdnx.Core
{
    public static class Utils
    {
        public static void Trim(ParseStatus status)
        {
            while (status.I < status.Input.Length && char.IsWhiteSpace(status.Input[status.I]))
            {
                status.I++;
            }
        }

        public static bool Accept(char ch, ParseStatus status)
        {
            if (status.I < status.Input.Length && status.Input[status.I] == ch)
            {
                status.I++;
                return true;
            }
            return false;
        }

        public static void Expect(char ch, ParseStatus status)
        {
            if (status.I < status.Input.Length && status.Input[status.I] == ch)
            {
                status.I++;
                return;
            }

            char found = status.I < status.Input.Length ? status.Input[status.I] : '\0';
            string message = $"Expected '{ch}' but found '{found}'";
            status.Errors.Add(new ParseError(message, status.I, 1));
            throw new ParseException();
        }

        public static Regex? CreateRegex(string input)
        {
            Match match = Regex.Match(input, @"/(.+?)/(.+?)*");
            if (!match.Success)
            {
                return null;
            }

            string pattern = match.Groups[1].Value;
            string flags = match.Groups[2].Value;
            return new Regex(pattern, flags.ToRegexOptions());
        }
    }

    internal static class RegexExtensions
    {
        public static RegexOptions ToRegexOptions(this string flags)
        {
            var options = RegexOptions.None;

            if (string.IsNullOrEmpty(flags))
            {
                return options;
            }

            foreach (char flag in flags)
            {
                options |= flag switch
                {
                    'i' => RegexOptions.IgnoreCase,
                    'm' => RegexOptions.Multiline,
                    's' => RegexOptions.Singleline,
                    'n' => RegexOptions.ExplicitCapture,
                    'x' => RegexOptions.IgnorePatternWhitespace,
                    _ => RegexOptions.None
                };
            }

            return options;
        }
    }
}
