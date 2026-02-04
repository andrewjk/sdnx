const SchemaValue = @import("./SchemaValue.zig").SchemaValue;

/// Props schema represents a property pattern schema
pub const PropsSchema = struct {
    type: []const u8,
    inner: *SchemaValue,
};
