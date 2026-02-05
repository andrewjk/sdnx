using System.Collections.Generic;
using Sdnx.Core;

namespace Sdnx.Core
{
    public class ParseResult<T>
    {
        public bool Ok { get; set; }
        public T? Data { get; set; }
        public List<ParseError> Errors { get; set; }

        public ParseResult()
        {
            Errors = new List<ParseError>();
            Data = default;
        }

        public ParseResult(bool ok, T? data)
        {
            Ok = ok;
            Data = data;
            Errors = new List<ParseError>();
        }

        public ParseResult(bool ok, List<ParseError> errors)
        {
            Ok = ok;
            Errors = new List<ParseError>(errors);
            Data = default;
        }

        public ParseResult(bool ok, List<ParseError> errors, T? data)
        {
            Ok = ok;
            Errors = new List<ParseError>(errors);
            Data = data;
        }
    }
}
