const std = @import("std");
const Allocator = std.mem.Allocator;

const FieldSchema = @import("./FieldSchema.zig").FieldSchema;
const ObjectSchema = @import("./ObjectSchema.zig").ObjectSchema;
const ArraySchema = @import("./ArraySchema.zig").ArraySchema;
const UnionSchema = @import("./UnionSchema.zig").UnionSchema;
const MixSchema = @import("./MixSchema.zig").MixSchema;
const AnySchema = @import("./AnySchema.zig").AnySchema;

/// Schema value types
pub const SchemaValue = union(enum) {
    field: FieldSchema,
    object: ObjectSchema,
    array: ArraySchema,
    union_type: UnionSchema,
    mix: MixSchema,
    any: AnySchema,

    pub fn deinit(self: *SchemaValue, allocator: Allocator) void {
        switch (self.*) {
            .field => |*f| {
                allocator.free(f.type);
                if (f.description) |desc| {
                    allocator.free(desc);
                }
                if (f.validators) |*vals| {
                    var iter = vals.iterator();
                    while (iter.next()) |entry| {
                        allocator.free(entry.key_ptr.*);
                        allocator.free(entry.value_ptr.raw);
                    }
                    vals.deinit();
                }
            },
            .object => |*o| {
                allocator.free(o.type);
                var iter = o.inner.iterator();
                while (iter.next()) |entry| {
                    allocator.free(entry.key_ptr.*);
                    entry.value_ptr.deinit(allocator);
                }
                o.inner.deinit();
            },
            .array => |*a| {
                allocator.free(a.type);
                a.inner.deinit(allocator);
                allocator.destroy(a.inner);
            },
            .union_type => |*u| {
                allocator.free(u.type);
                for (u.inner.items) |*item| {
                    item.deinit(allocator);
                }
                u.inner.deinit(allocator);
            },
            .mix => |*m| {
                allocator.free(m.type);
                for (m.inner.items) |*item| {
                    var iter = item.iterator();
                    while (iter.next()) |entry| {
                        allocator.free(entry.key_ptr.*);
                        entry.value_ptr.deinit(allocator);
                    }
                    item.deinit();
                }
                m.inner.deinit(allocator);
            },
            .any => |*a| {
                allocator.free(a.type);
                a.inner.deinit(allocator);
                allocator.destroy(a.inner);
            },
        }
    }
};
