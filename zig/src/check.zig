const std = @import("std");
const Allocator = std.mem.Allocator;
const mvzr = @import("mvzr");

const Schema = @import("./types/Schema.zig").Schema;
const SchemaValue = @import("./types/SchemaValue.zig").SchemaValue;
const ObjectSchema = @import("./types/ObjectSchema.zig").ObjectSchema;
const ArraySchema = @import("./types/ArraySchema.zig").ArraySchema;
const FieldSchema = @import("./types/FieldSchema.zig").FieldSchema;
const UnionSchema = @import("./types/UnionSchema.zig").UnionSchema;
const MixSchema = @import("./types/MixSchema.zig").MixSchema;
const PropsSchema = @import("./types/PropsSchema.zig").PropsSchema;
const DefSchema = @import("./types/DefSchema.zig").DefSchema;
const RefSchema = @import("./types/RefSchema.zig").RefSchema;
const Validator = @import("./types/Validator.zig").Validator;
const Value = @import("./types/Value.zig").Value;

pub const CheckError = error{
    FieldNotFound,
    TypeMismatch,
    UnsupportedPattern,
    UnsupportedValidator,
    InvalidCharacter,
    Overflow,
} || std.mem.Allocator.Error;

pub const ValidationError = struct {
    path: std.ArrayList([]const u8),
    message: []const u8,
    allocator: Allocator,

    pub fn init(allocator: Allocator) ValidationError {
        return ValidationError{
            .path = .empty,
            .message = "",
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *ValidationError) void {
        for (self.path.items) |item| {
            self.allocator.free(item);
        }
        self.path.deinit(self.allocator);
        if (self.message.len > 0) {
            self.allocator.free(self.message);
        }
    }
};

pub const CheckResult = union(enum) {
    ok: void,
    err_list: std.ArrayList(ValidationError),

    pub fn deinit(self: *CheckResult, allocator: Allocator) void {
        switch (self.*) {
            .err_list => |*err_list| {
                for (err_list.items) |*err| {
                    err.deinit();
                }
                err_list.deinit(allocator);
            },
            .ok => {},
        }
    }
};

pub fn check(allocator: Allocator, input: *const Value, schema: *const Schema) CheckError!CheckResult {
    var errors: std.ArrayList(ValidationError) = .empty;
    errdefer {
        for (errors.items) |*err| {
            err.deinit();
        }
        errors.deinit(allocator);
    }

    _ = try checkObjectSchemaInner(allocator, input, schema, &errors, schema);

    if (errors.items.len == 0) {
        return CheckResult{ .ok = {} };
    } else {
        return CheckResult{ .err_list = errors };
    }
}

fn checkObjectSchemaInner(
    allocator: Allocator,
    input: *const Value,
    schema: *const Schema,
    errors: *std.ArrayList(ValidationError),
    full_schema: *const Schema,
) CheckError!bool {
    switch (input.*) {
        .object => |obj| {
            var iter = schema.iterator();
            var result = true;
            while (iter.next()) |entry| {
                const field = entry.key_ptr.*;
                const field_schema = entry.value_ptr.*;

                if (std.mem.startsWith(u8, field, "mix$")) {
                    if (!try checkMixSchema(allocator, input, field_schema.mix, errors, full_schema)) {
                        result = false;
                    }
                } else if (std.mem.startsWith(u8, field, "props$")) {
                    if (!try checkPropsSchema(allocator, &obj, field_schema.props, field, errors, full_schema)) {
                        result = false;
                    }
                } else if (std.mem.startsWith(u8, field, "ref$")) {
                    if (field_schema == .ref) {
                        if (!try checkRefSchema(allocator, input, field_schema.ref, errors, full_schema)) {
                            result = false;
                        }
                    }
                } else if (std.mem.startsWith(u8, field, "def$")) {
                    continue;
                } else {
                    const value = obj.get(field);
                    if (!try checkFieldSchema(allocator, if (value) |v| &v else null, field_schema, field, errors, full_schema)) {
                        result = false;
                    }
                }
            }
            return result;
        },
        else => {
            var err = ValidationError.init(allocator);
            err.message = "Input must be an object";
            try errors.append(allocator, err);
        },
    }
    return false;
}

fn checkArraySchema(
    allocator: Allocator,
    input: *const Value,
    schema: ArraySchema,
    errors: *std.ArrayList(ValidationError),
    full_schema: *const Schema,
) CheckError!bool {
    switch (input.*) {
        .array => |arr| {
            var result = true;
            for (arr.items, 0..) |item, i| {
                const field = try std.fmt.allocPrint(allocator, "{d}", .{i});
                defer allocator.free(field);
                if (!try checkFieldSchema(allocator, &item, schema.inner.*, field, errors, full_schema)) {
                    result = false;
                }
            }
            return result;
        },
        else => {
            var err = ValidationError.init(allocator);
            err.message = "Input must be an array";
            try errors.append(allocator, err);
            return false;
        },
    }
}

fn checkUnionSchema(
    allocator: Allocator,
    value: *const Value,
    schema: UnionSchema,
    field: []const u8,
    errors: *std.ArrayList(ValidationError),
    full_schema: *const Schema,
) CheckError!bool {
    var field_errors: std.ArrayList(ValidationError) = .empty;
    defer {
        for (field_errors.items) |*err| {
            err.deinit();
        }
        field_errors.deinit(allocator);
    }

    var ok = false;
    for (schema.inner.items) |fs| {
        if (try checkFieldSchema(allocator, value, fs, field, &field_errors, full_schema)) {
            ok = true;
            break;
        }
    }

    if (!ok) {
        var err = ValidationError.init(allocator);
        var msg_list: std.ArrayList([]const u8) = .empty;

        for (field_errors.items) |e| {
            try msg_list.append(allocator, e.message);
        }

        const joined = try std.mem.join(allocator, " | ", msg_list.items);
        msg_list.deinit(allocator);
        err.message = joined;
        try errors.append(allocator, err);
    }

    return ok;
}

fn checkMixSchema(
    allocator: Allocator,
    input: *const Value,
    schema: MixSchema,
    errors: *std.ArrayList(ValidationError),
    full_schema: *const Schema,
) CheckError!bool {
    var field_errors: std.ArrayList(ValidationError) = .empty;
    defer {
        for (field_errors.items) |*err| {
            err.deinit();
        }
        field_errors.deinit(allocator);
    }

    var ok = false;
    for (schema.inner.items) |alt_schema| {
        var mix_errors: std.ArrayList(ValidationError) = .empty;
        defer {
            for (mix_errors.items) |*err| {
                err.deinit();
            }
            mix_errors.deinit(allocator);
        }

        const result = try checkObjectSchemaInner(allocator, input, &alt_schema, &mix_errors, full_schema);

        if (result) {
            ok = true;
            break;
        } else {
            var err = ValidationError.init(allocator);
            var msg_list: std.ArrayList([]const u8) = .empty;

            for (mix_errors.items) |e| {
                try msg_list.append(allocator, e.message);
            }

            const joined = try std.mem.join(allocator, " & ", msg_list.items);
            msg_list.deinit(allocator);
            err.message = joined;
            try field_errors.append(allocator, err);
        }
    }

    if (!ok) {
        var err = ValidationError.init(allocator);
        var msg_list: std.ArrayList([]const u8) = .empty;

        for (field_errors.items) |e| {
            try msg_list.append(allocator, e.message);
        }

        const joined = try std.mem.join(allocator, " | ", msg_list.items);
        msg_list.deinit(allocator);
        err.message = joined;
        try errors.append(allocator, err);
    }

    return ok;
}

fn checkPropsSchema(
    allocator: Allocator,
    input: *const std.StringArrayHashMap(Value),
    schema: PropsSchema,
    field: []const u8,
    errors: *std.ArrayList(ValidationError),
    full_schema: *const Schema,
) CheckError!bool {
    _ = field;
    var result = true;
    var iter = input.iterator();
    while (iter.next()) |entry| {
        const any_field = entry.key_ptr.*;
        const value = &entry.value_ptr.*;

        if (schema.type.len > 0) {
            if (!try matchesPattern(any_field, schema.type)) {
                var err = ValidationError.init(allocator);
                err.message = try std.fmt.allocPrint(allocator, "'{s}' name doesn't match pattern '{s}'", .{ any_field, schema.type });
                try errors.append(allocator, err);
                return false;
            }
        }

        if (!try checkFieldSchema(allocator, value, schema.inner.*, any_field, errors, full_schema)) {
            result = false;
        }
    }
    return result;
}

fn checkFieldSchema(
    allocator: Allocator,
    value_opt: ?*const Value,
    schema: SchemaValue,
    field: []const u8,
    errors: *std.ArrayList(ValidationError),
    full_schema: *const Schema,
) CheckError!bool {
    switch (schema) {
        .object => |obj_schema| {
            if (value_opt == null or value_opt.?.* != .object) {
                var err = ValidationError.init(allocator);
                err.message = try std.fmt.allocPrint(allocator, "'{s}' must be an object", .{field});
                try errors.append(allocator, err);
                return false;
            }
            _ = &value_opt.?.object;
            return try checkObjectSchemaInner(allocator, value_opt.?, &obj_schema.inner, errors, full_schema);
        },
        .array => |arr_schema| {
            if (value_opt == null or value_opt.?.* != .array) {
                var err = ValidationError.init(allocator);
                err.message = try std.fmt.allocPrint(allocator, "'{s}' must be an array", .{field});
                try errors.append(allocator, err);
                return false;
            }
            return try checkArraySchema(allocator, value_opt.?, arr_schema, errors, full_schema);
        },
        .union_type => |union_schema| {
            if (value_opt == null) {
                for (union_schema.inner.items) |fs| {
                    if (fs == .field and std.mem.eql(u8, fs.field.type, "undef")) {
                        return true;
                    }
                }
                var err = ValidationError.init(allocator);
                err.message = try std.fmt.allocPrint(allocator, "Field not found: {s}", .{field});
                try errors.append(allocator, err);
                return false;
            }
            return try checkUnionSchema(allocator, value_opt.?, union_schema, field, errors, full_schema);
        },
        .field => |field_schema| {
            return try checkFieldSchemaValue(allocator, value_opt, field_schema, field, errors);
        },
        .mix => {
            const value = value_opt orelse {
                var err = ValidationError.init(allocator);
                err.message = try std.fmt.allocPrint(allocator, "Field not found: {s}", .{field});
                try errors.append(allocator, err);
                return false;
            };
            return try checkMixSchema(allocator, value, schema.mix, errors, full_schema);
        },
        .props => {
            if (value_opt == null) {
                var err = ValidationError.init(allocator);
                err.message = try std.fmt.allocPrint(allocator, "Field not found: {s}", .{field});
                try errors.append(allocator, err);
                return false;
            }
            const obj_val = if (value_opt.?.* == .object) &value_opt.?.object else {
                var err = ValidationError.init(allocator);
                err.message = try std.fmt.allocPrint(allocator, "'{s}' must be an object", .{field});
                try errors.append(allocator, err);
                return false;
            };
            return try checkPropsSchema(allocator, obj_val, schema.props, field, errors, full_schema);
        },
        .def => {
            return true;
        },
        .ref => {
            return true;
        },
    }
}

fn checkRefSchema(
    allocator: Allocator,
    input: *const Value,
    ref_schema: RefSchema,
    errors: *std.ArrayList(ValidationError),
    full_schema: *const Schema,
) CheckError!bool {
    const ref_name = ref_schema.inner;
    var iter = full_schema.iterator();
    while (iter.next()) |entry| {
        if (std.mem.startsWith(u8, entry.key_ptr.*, "def$")) {
            if (entry.value_ptr.* == .def and std.mem.eql(u8, entry.value_ptr.*.def.name, ref_name)) {
                return try checkObjectSchemaInner(allocator, input, &entry.value_ptr.*.def.inner, errors, full_schema);
            }
        }
    }
    var err = ValidationError.init(allocator);
    err.message = try std.fmt.allocPrint(allocator, "Unknown reference: {s}", .{ref_name});
    try errors.append(allocator, err);
    return false;
}

fn checkFieldSchemaValue(
    allocator: Allocator,
    value_opt: ?*const Value,
    schema: FieldSchema,
    field: []const u8,
    errors: *std.ArrayList(ValidationError),
) CheckError!bool {
    const value = value_opt orelse {
        if (!std.mem.eql(u8, schema.type, "undef")) {
            var err = ValidationError.init(allocator);
            err.message = try std.fmt.allocPrint(allocator, "Field not found: {s}", .{field});
            try errors.append(allocator, err);
            return false;
        }
        return true;
    };

    if (std.mem.eql(u8, schema.type, "undef")) {
        if (value.* != .null) {
            var err = ValidationError.init(allocator);
            err.message = try std.fmt.allocPrint(allocator, "'{s}' must be undefined", .{field});
            try errors.append(allocator, err);
            return false;
        }
        return true;
    }

    if (std.mem.eql(u8, schema.type, "bool")) {
        if (value.* != .bool) {
            var err = ValidationError.init(allocator);
            err.message = try std.fmt.allocPrint(allocator, "'{s}' must be a boolean value", .{field});
            try errors.append(allocator, err);
            return false;
        }
    } else if (std.mem.eql(u8, schema.type, "int")) {
        if (value.* != .int) {
            var err = ValidationError.init(allocator);
            err.message = try std.fmt.allocPrint(allocator, "'{s}' must be an integer value", .{field});
            try errors.append(allocator, err);
            return false;
        }
    } else if (std.mem.eql(u8, schema.type, "num")) {
        if (value.* != .int and value.* != .num) {
            var err = ValidationError.init(allocator);
            err.message = try std.fmt.allocPrint(allocator, "'{s}' must be a number value", .{field});
            try errors.append(allocator, err);
            return false;
        }
    } else if (std.mem.eql(u8, schema.type, "date")) {
        if (value.* != .date) {
            var err = ValidationError.init(allocator);
            err.message = try std.fmt.allocPrint(allocator, "'{s}' must be a date value", .{field});
            try errors.append(allocator, err);
            return false;
        }
    } else if (std.mem.eql(u8, schema.type, "string")) {
        if (value.* != .string) {
            var err = ValidationError.init(allocator);
            err.message = try std.fmt.allocPrint(allocator, "'{s}' must be a string value", .{field});
            try errors.append(allocator, err);
            return false;
        }
    } else {
        const expected_type = if (schema.type.len >= 2 and schema.type[0] == '"' and schema.type[schema.type.len - 1] == '"')
            schema.type[1 .. schema.type.len - 1]
        else
            schema.type;

        var value_str: []const u8 = undefined;
        var is_allocated = false;

        switch (value.*) {
            .string => |s| {
                value_str = s;
                is_allocated = false;
            },
            .int => |i| {
                value_str = try std.fmt.allocPrint(allocator, "{d}", .{i});
                is_allocated = true;
            },
            .bool => |b| {
                value_str = if (b) "true" else "false";
                is_allocated = false;
            },
            .null => {
                value_str = "null";
                is_allocated = false;
            },
            else => {
                var err = ValidationError.init(allocator);
                err.message = try std.fmt.allocPrint(allocator, "'{s}' must be '{s}'", .{ field, expected_type });
                try errors.append(allocator, err);
                return false;
            },
        }

        defer {
            if (is_allocated) {
                allocator.free(value_str);
            }
        }

        if (!std.mem.eql(u8, expected_type, value_str)) {
            var err = ValidationError.init(allocator);
            err.message = try std.fmt.allocPrint(allocator, "'{s}' must be '{s}'", .{ field, expected_type });
            try errors.append(allocator, err);
            return false;
        }

        return true;
    }

    if (schema.validators) |validators_map| {
        var iter = validators_map.iterator();
        while (iter.next()) |entry| {
            const method = entry.key_ptr.*;
            if (std.mem.eql(u8, method, "type") or std.mem.eql(u8, method, "description")) {
                continue;
            }

            const validator = entry.value_ptr.*;
            const validate_result = try runValidator(allocator, schema.type, method, field, value.*, validator.raw, errors);
            if (!validate_result) {
                return false;
            }
        }
    }

    return true;
}

fn runValidator(
    allocator: Allocator,
    type_name: []const u8,
    method: []const u8,
    field: []const u8,
    value: Value,
    raw: []const u8,
    errors: *std.ArrayList(ValidationError),
) CheckError!bool {
    if (std.mem.eql(u8, type_name, "int") or std.mem.eql(u8, type_name, "num")) {
        const num_val = switch (value) {
            .int => |i| @as(f64, @floatFromInt(i)),
            .num => |n| n,
            else => return false,
        };

        const required_val = try std.fmt.parseFloat(f64, raw);

        if (std.mem.eql(u8, method, "min")) {
            if (num_val < required_val) {
                var err = ValidationError.init(allocator);
                err.message = try std.fmt.allocPrint(allocator, "'{s}' must be at least {s}", .{ field, raw });
                try errors.append(allocator, err);
                return false;
            }
        } else if (std.mem.eql(u8, method, "max")) {
            if (num_val > required_val) {
                var err = ValidationError.init(allocator);
                err.message = try std.fmt.allocPrint(allocator, "'{s}' cannot be more than {s}", .{ field, raw });
                try errors.append(allocator, err);
                return false;
            }
        }
    } else if (std.mem.eql(u8, type_name, "date")) {
        if (value != .date) {
            return false;
        }

        if (std.mem.eql(u8, method, "min") or std.mem.eql(u8, method, "max")) {
            const date_val = value.date;
            const required_date = raw;
            const comparison = std.mem.order(u8, date_val, required_date);
            const is_min = std.mem.eql(u8, method, "min");

            if ((is_min and comparison == .lt) or (!is_min and comparison == .gt)) {
                if (is_min) {
                    var err = ValidationError.init(allocator);
                    err.message = try std.fmt.allocPrint(allocator, "'{s}' must be at least {s}", .{ field, raw });
                    try errors.append(allocator, err);
                } else {
                    var err = ValidationError.init(allocator);
                    err.message = try std.fmt.allocPrint(allocator, "'{s}' cannot be after {s}", .{ field, raw });
                    try errors.append(allocator, err);
                }
                return false;
            }
        }
    } else if (std.mem.eql(u8, type_name, "string")) {
        const str_val = switch (value) {
            .string => |s| s,
            else => return false,
        };

        if (std.mem.eql(u8, method, "minlen")) {
            const required_val = try std.fmt.parseInt(usize, raw, 10);
            if (str_val.len < required_val) {
                var err = ValidationError.init(allocator);
                err.message = try std.fmt.allocPrint(allocator, "'{s}' must be at least {s} characters", .{ field, raw });
                try errors.append(allocator, err);
                return false;
            }
        } else if (std.mem.eql(u8, method, "maxlen")) {
            const required_val = try std.fmt.parseInt(usize, raw, 10);
            if (str_val.len > required_val) {
                var err = ValidationError.init(allocator);
                err.message = try std.fmt.allocPrint(allocator, "'{s}' cannot be more than {s} characters", .{ field, raw });
                try errors.append(allocator, err);
                return false;
            }
        } else if (std.mem.eql(u8, method, "pattern")) {
            if (!try matchesPattern(str_val, raw)) {
                var err = ValidationError.init(allocator);
                err.message = try std.fmt.allocPrint(allocator, "'{s}' doesn't match pattern '{s}'", .{ field, raw });
                try errors.append(allocator, err);
                return false;
            }
        }
    } else {
        var err = ValidationError.init(allocator);
        err.message = try std.fmt.allocPrint(allocator, "Unsupported validation method for '{s}': {s}", .{ field, method });
        try errors.append(allocator, err);
        return false;
    }

    return true;
}

fn matchesPattern(input: []const u8, pattern: []const u8) CheckError!bool {
    if (pattern.len == 0) return true;

    if (pattern[0] == '/') {
        // Find the last '/' that marks the end of the regex pattern
        // (flags may follow, like /pattern/i for case-insensitive)
        var last_slash: usize = 0;
        for (pattern, 0..) |c, i| {
            if (c == '/' and i > 0) {
                last_slash = i;
            }
        }
        if (last_slash > 0) {
            const regex_pattern = pattern[1..last_slash];
            const regex = mvzr.compile(regex_pattern) orelse return false;
            return regex.isMatch(input);
        }
    }

    return std.mem.eql(u8, input, pattern);
}
