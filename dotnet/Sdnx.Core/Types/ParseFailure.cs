namespace Sdnx.Core
{
    public class ParseFailure
    {
        public bool Ok => false;
        public List<ParseError> Errors { get; set; }

        public ParseFailure()
        {
            Errors = new List<ParseError>();
        }

        public ParseFailure(List<ParseError> errors)
        {
            Errors = new List<ParseError>(errors);
        }
    }
}
