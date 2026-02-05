namespace Sdnx.Core
{
    public record FieldSchema : SchemaValue
    {
        public required string Type { get; init; }
        public string? Description { get; init; }
        public Dictionary<string, Validator>? Validators { get; init; }
    }
}
