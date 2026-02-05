namespace Sdnx.Core
{
    public record ObjectSchema : SchemaValue
    {
        public required string Type { get; init; } = "object";
        public required Dictionary<string, SchemaValue> Inner { get; init; }
        public string? Description { get; init; }
        public Dictionary<string, Validator>? Validators { get; init; }
    }
}
