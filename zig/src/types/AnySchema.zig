const SchemaValue = @import("./SchemaValue.zig").SchemaValue;

/// Any schema represents a custom type with pattern matching
pub const AnySchema = struct {
    type: []const u8,
    inner: *SchemaValue,
};
