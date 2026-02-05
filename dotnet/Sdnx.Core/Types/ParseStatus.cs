using System.Collections.Generic;

namespace Sdnx.Core
{
    public class ParseStatus
    {
        public string Input { get; set; } = string.Empty;
        public int I { get; set; }
        public List<ParseError> Errors { get; set; }

        public ParseStatus()
        {
            Errors = new List<ParseError>();
        }

        public ParseStatus(string input) : this()
        {
            Input = input;
            I = 0;
        }
    }
}
