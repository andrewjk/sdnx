const std = @import("std");
const Allocator = std.mem.Allocator;

/// Value type for parsed SDN data
pub const Value = union(enum) {
    null: void,
    bool: bool,
    int: i64,
    num: f64,
    date: []const u8,
    string: []const u8,
    array: std.ArrayList(Value),
    object: std.StringArrayHashMap(Value),

    pub fn deinit(self: *const Value, allocator: Allocator) void {
        const self_mut: *Value = @ptrCast(@constCast(self));
        switch (self_mut.*) {
            .array => |*arr| {
                for (arr.items) |*item| {
                    item.deinit(allocator);
                }
                arr.deinit(allocator);
            },
            .object => |*obj| {
                var iter = obj.iterator();
                while (iter.next()) |entry| {
                    entry.value_ptr.deinit(allocator);
                    allocator.free(entry.key_ptr.*);
                }
                obj.deinit();
            },
            .date => |d| {
                allocator.free(d);
            },
            .string => |s| {
                allocator.free(s);
            },
            else => {},
        }
    }
};
