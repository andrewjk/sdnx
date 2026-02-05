using System.Collections.Generic;

namespace Sdnx.Core
{
    public class CheckStatus
    {
        public List<string> Path { get; set; }
        public List<CheckError> Errors { get; set; }
        public Dictionary<string, Dictionary<string, SchemaValue>> Defs { get; set; }

        public CheckStatus()
        {
            Path = new List<string>();
            Errors = new List<CheckError>();
            Defs = new Dictionary<string, Dictionary<string, SchemaValue>>();
        }
    }
}
