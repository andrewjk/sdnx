const std = @import("std");
const SchemaValue = @import("./SchemaValue.zig").SchemaValue;
const Validator = @import("./Validator.zig").Validator;

/// Array schema represents an array with inner schema value
pub const ArraySchema = struct {
    type: []const u8,
    inner: *SchemaValue,
    validators: ?std.StringArrayHashMap(Validator) = null,

    pub fn deinit(self: *ArraySchema, allocator: std.mem.Allocator) void {
        allocator.free(self.type);
        self.inner.deinit(allocator);
        allocator.destroy(self.inner);
        if (self.validators) |*vals| {
            var iter = vals.iterator();
            while (iter.next()) |entry| {
                allocator.free(entry.key_ptr.*);
                allocator.free(entry.value_ptr.raw);
            }
            vals.deinit();
        }
    }
};
