namespace Sdnx.Core
{
    public record MixSchema : SchemaValue
    {
        public required string Type { get; init; } = "mix";
        public required List<Dictionary<string, SchemaValue>> Inner { get; init; }
        public string? Description { get; init; }
        public Dictionary<string, Validator>? Validators { get; init; }
    }
}
