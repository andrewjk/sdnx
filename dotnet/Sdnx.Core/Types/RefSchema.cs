namespace Sdnx.Core
{
    public record RefSchema : SchemaValue
    {
        public required string Type { get; init; }
        public required string Inner { get; init; }
        public string? Description { get; init; }
        public Dictionary<string, Validator>? Validators { get; init; }
    }
}
