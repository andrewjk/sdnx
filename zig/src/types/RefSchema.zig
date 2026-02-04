const std = @import("std");

/// Ref schema represents a reference to a def
pub const RefSchema = struct {
    type: []const u8,
    inner: []const u8,
};
