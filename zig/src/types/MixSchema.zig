const std = @import("std");

const Schema = @import("./Schema.zig").Schema;

/// Mix schema represents a mix of multiple object schemas
pub const MixSchema = struct {
    type: []const u8,
    inner: std.ArrayList(Schema),
};
