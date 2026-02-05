namespace Sdnx.Core
{
    public record UnionSchema : SchemaValue
    {
        public required string Type { get; init; } = "union";
        public required List<SchemaValue> Inner { get; init; }
        public string? Description { get; init; }
        public Dictionary<string, Validator>? Validators { get; init; }
    }
}
