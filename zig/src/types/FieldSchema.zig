const std = @import("std");
const Validator = @import("./Validator.zig").Validator;

/// Field schema represents a single field with type and validators
pub const FieldSchema = struct {
    type: []const u8,
    description: ?[]const u8 = null,
    validators: ?std.StringArrayHashMap(Validator) = null,
};
