namespace Sdnx.Core
{
    public class ParseError
    {
        public string Message { get; set; } = string.Empty;
        public int Index { get; set; }
        public int Length { get; set; }

        public ParseError()
        {
        }

        public ParseError(string message, int index, int length)
        {
            Message = message;
            Index = index;
            Length = length;
        }
    }
}
