namespace Sdnx.Core
{
    public record PropsSchema : SchemaValue
    {
        public required string Type { get; init; } = "props";
        public required SchemaValue Inner { get; init; }
        public string? Description { get; init; }
        public Dictionary<string, Validator>? Validators { get; init; }
    }
}
