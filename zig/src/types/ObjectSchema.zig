const Schema = @import("./Schema.zig").Schema;

/// Object schema represents an object with inner schema
pub const ObjectSchema = struct {
    type: []const u8,
    inner: Schema,
};
