using System.Collections.Generic;

namespace Sdnx.Core
{
    public class CheckError
    {
        public List<string> Path { get; set; }
        public string Message { get; set; } = string.Empty;

        public CheckError()
        {
            Path = new List<string>();
        }

        public CheckError(List<string> path, string message)
        {
            Path = new List<string>(path);
            Message = message;
        }
    }
}
