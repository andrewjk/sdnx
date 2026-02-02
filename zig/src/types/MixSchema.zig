const std = @import("std");
const Allocator = std.mem.Allocator;

const Schema = @import("./Schema.zig").Schema;

/// Mix schema represents a mix of multiple object schemas
pub const MixSchema = struct {
    type: []const u8,
    inner: std.ArrayList(Schema),

    pub fn deinit(self: *MixSchema, allocator: Allocator) void {
        allocator.free(self.type);
        for (self.inner.items) |*item| {
            var iter = item.iterator();
            while (iter.next()) |entry| {
                allocator.free(entry.key_ptr.*);
                entry.value_ptr.deinit(allocator);
            }
            item.deinit();
        }
        self.inner.deinit(allocator);
    }
};
