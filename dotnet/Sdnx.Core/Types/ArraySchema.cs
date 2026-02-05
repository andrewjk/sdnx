namespace Sdnx.Core
{
    public record ArraySchema : SchemaValue
    {
        public required string Type { get; init; } = "array";
        public required SchemaValue Inner { get; init; }
        public string? Description { get; init; }
        public Dictionary<string, Validator>? Validators { get; init; }
    }
}
