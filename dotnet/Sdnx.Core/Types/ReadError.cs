namespace Sdnx.Core
{
    public class ReadError : ParseError
    {
        public string Line { get; set; } = string.Empty;
        public int Char { get; set; }

        public ReadError()
        {
        }

        public ReadError(string message, int index, int length, string line, int ch) : base(message, index, length)
        {
            Line = line;
            Char = ch;
        }
    }
}
