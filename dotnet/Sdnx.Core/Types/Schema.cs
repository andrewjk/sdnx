using System.Collections.Generic;

namespace Sdnx.Core
{
    public class Schema
    {
        public Dictionary<string, SchemaValue> Fields { get; set; }

        public Schema()
        {
            Fields = new Dictionary<string, SchemaValue>();
        }

        public Schema(Dictionary<string, SchemaValue> fields)
        {
            Fields = new Dictionary<string, SchemaValue>(fields);
        }
    }
}
