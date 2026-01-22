const std = @import("std");

const SchemaValue = @import("./SchemaValue.zig").SchemaValue;

/// Union schema represents a union of multiple types
pub const UnionSchema = struct {
    type: []const u8,
    inner: std.ArrayList(SchemaValue),
};
