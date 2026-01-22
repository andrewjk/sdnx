const SchemaValue = @import("./SchemaValue.zig").SchemaValue;

/// Array schema represents an array with inner schema value
pub const ArraySchema = struct {
    type: []const u8,
    inner: *SchemaValue,
};
