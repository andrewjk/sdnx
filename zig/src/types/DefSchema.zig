const std = @import("std");
const Allocator = std.mem.Allocator;

const Schema = @import("./Schema.zig").Schema;

/// Def schema represents a reusable schema definition
pub const DefSchema = struct {
    type: []const u8,
    name: []const u8,
    inner: Schema,

    pub fn deinit(self: *DefSchema, allocator: Allocator) void {
        allocator.free(self.type);
        allocator.free(self.name);
        var iter = self.inner.iterator();
        while (iter.next()) |entry| {
            allocator.free(entry.key_ptr.*);
            entry.value_ptr.deinit(allocator);
        }
        self.inner.deinit();
    }
};
