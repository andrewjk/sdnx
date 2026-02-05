namespace Sdnx.Core
{
    public record DefSchema : SchemaValue
    {
        public required string Type { get; init; } = "def";
        public required string Name { get; init; }
        public required Dictionary<string, SchemaValue> Inner { get; init; }
        public string? Description { get; init; }
        public Dictionary<string, Validator>? Validators { get; init; }
    }
}
