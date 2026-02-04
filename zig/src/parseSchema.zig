const std = @import("std");
const Allocator = std.mem.Allocator;

const Schema = @import("./types/Schema.zig").Schema;
const SchemaValue = @import("./types/SchemaValue.zig").SchemaValue;
const ObjectSchema = @import("./types/ObjectSchema.zig").ObjectSchema;
const ArraySchema = @import("./types/ArraySchema.zig").ArraySchema;
const FieldSchema = @import("./types/FieldSchema.zig").FieldSchema;
const UnionSchema = @import("./types/UnionSchema.zig").UnionSchema;
const MixSchema = @import("./types/MixSchema.zig").MixSchema;
const AnySchema = @import("./types/AnySchema.zig").AnySchema;
const Validator = @import("./types/Validator.zig").Validator;
const convertValue = @import("./convertValue.zig").convertValue;
const isTruthy = @import("./convertValue.zig").isTruthy;

/// Error information with position details
pub const SchemaParseErrorInfo = struct {
    message: []const u8,
    index: usize,
    length: usize,

    pub fn deinit(self: *SchemaParseErrorInfo, allocator: Allocator) void {
        allocator.free(self.message);
    }
};

/// Result type for schema parse operations
pub const SchemaParseResult = struct {
    ok: bool,
    schema: ?Schema,
    errors: std.ArrayListUnmanaged(SchemaParseErrorInfo),
    allocator: Allocator,

    pub fn deinit(self: *SchemaParseResult) void {
        for (self.errors.items) |*err| {
            err.deinit(self.allocator);
        }
        self.errors.deinit(self.allocator);
        if (self.schema) |*s| {
            deinitSchema(s, self.allocator);
        }
    }
};

/// Status tracks the current parsing position for schema parsing
pub const Status = struct {
    input: []const u8,
    i: usize,
    description: []const u8 = "",
    mix_counter: usize,
    any_counter: usize,
    errors: std.ArrayListUnmanaged(SchemaParseErrorInfo),
    allocator: Allocator,

    pub fn deinit(self: *Status) void {
        for (self.errors.items) |*err| {
            err.deinit(self.allocator);
        }
        self.errors.deinit(self.allocator);
    }
};

/// Properly deinitialize a Schema, freeing all keys and values
pub fn deinitSchema(schema: *Schema, allocator: Allocator) void {
    var iter = schema.iterator();
    while (iter.next()) |entry| {
        allocator.free(entry.key_ptr.*);
        entry.value_ptr.deinit(allocator);
    }
    schema.deinit();
}

/// Add an error to the status
fn addError(status: *Status, message: []const u8, index: usize, length: usize) void {
    const msg = std.fmt.allocPrint(status.allocator, "{s}", .{message}) catch return;
    status.errors.append(status.allocator, .{
        .message = msg,
        .index = index,
        .length = length,
    }) catch {
        status.allocator.free(msg);
    };
}

/// Trim whitespace from current position
fn trim(status: *Status) void {
    while (status.i < status.input.len and std.ascii.isWhitespace(status.input[status.i])) {
        status.i += 1;
    }
}

/// Accept a specific character and advance if found
fn accept(ch: u8, status: *Status) bool {
    if (status.i < status.input.len and status.input[status.i] == ch) {
        status.i += 1;
        return true;
    }
    return false;
}

/// Expect a specific character, record error if not found
fn expect(ch: u8, status: *Status) void {
    if (status.i < status.input.len and status.input[status.i] == ch) {
        status.i += 1;
        return;
    }
    const msg = std.fmt.allocPrint(status.allocator, "Expected '{c}' but found '{c}'", .{ ch, if (status.i < status.input.len) status.input[status.i] else '?' }) catch return;
    status.errors.append(status.allocator, .{
        .message = msg,
        .index = status.i,
        .length = 1,
    }) catch {
        status.allocator.free(msg);
    };
}

/// Parse schema from input string
pub fn parseSchema(allocator: Allocator, input: []const u8) SchemaParseResult {
    var status = Status{
        .input = input,
        .i = 0,
        .description = "",
        .mix_counter = 1,
        .any_counter = 1,
        .errors = .empty,
        .allocator = allocator,
    };
    defer status.deinit();

    trim(&status);

    if (accept('{', &status)) {
        const result = parseObject(allocator, &status);

        // Move errors from status to result
        var errors_copy: std.ArrayListUnmanaged(SchemaParseErrorInfo) = .empty;
        for (status.errors.items) |err| {
            const msg = allocator.dupe(u8, err.message) catch continue;
            errors_copy.append(allocator, .{
                .message = msg,
                .index = err.index,
                .length = err.length,
            }) catch {
                allocator.free(msg);
                continue;
            };
        }

        if (result) |schema| {
            return SchemaParseResult{
                .ok = errors_copy.items.len == 0,
                .schema = schema,
                .errors = errors_copy,
                .allocator = allocator,
            };
        } else |_| {
            return SchemaParseResult{
                .ok = false,
                .schema = null,
                .errors = errors_copy,
                .allocator = allocator,
            };
        }
    } else {
        const msg = std.fmt.allocPrint(allocator, "Expected '{{' but found '{c}'", .{if (status.i < status.input.len) status.input[status.i] else '?'}) catch "Expected '{'";
        var errors: std.ArrayListUnmanaged(SchemaParseErrorInfo) = .empty;
        errors.append(allocator, .{
            .message = msg,
            .index = 0,
            .length = 1,
        }) catch allocator.free(msg);

        return SchemaParseResult{
            .ok = false,
            .schema = null,
            .errors = errors,
            .allocator = allocator,
        };
    }
}

fn parseObject(allocator: Allocator, status: *Status) anyerror!Schema {
    var result = Schema.init(allocator);
    errdefer {
        var iter = result.iterator();
        while (iter.next()) |entry| {
            allocator.free(entry.key_ptr.*);
            entry.value_ptr.deinit(allocator);
        }
        result.deinit();
    }

    const start = status.i;
    _ = start;
    while (true) {
        trim(status);
        if (accept('}', status)) {
            break;
        } else if (status.i >= status.input.len or accept(']', status)) {
            addError(status, "Object not closed", status.i, 1);
            return error.ParseError;
        }

        parseField(allocator, status, &result);

        trim(status);
        _ = accept(',', status);
    }
    return result;
}

fn parseArray(allocator: Allocator, status: *Status) anyerror!*SchemaValue {
    trim(status);
    const start = status.i;
    _ = start;

    if (accept(']', status)) {
        addError(status, "Array cannot be empty", status.i, 1);
        return error.ParseError;
    } else if (accept('}', status)) {
        addError(status, "Array not closed", status.i, 1);
        return error.ParseError;
    }

    var value = parseValue(allocator, status) catch |err| return err;

    trim(status);
    if (status.i >= status.input.len or !accept(']', status)) {
        value.deinit(allocator);
        addError(status, "Array not closed", status.i, 1);
        return error.ParseError;
    }

    const result_ptr = try allocator.create(SchemaValue);
    result_ptr.* = value;
    return result_ptr;
}

fn parseField(allocator: Allocator, status: *Status, result: *Schema) void {
    trim(status);

    const start = status.i;

    // Check for comments
    if (accept('#', status)) {
        const add_description = accept('#', status);
        while (status.i < status.input.len and status.input[status.i] != '\n') {
            status.i += 1;
        }
        if (add_description) {
            const comment = status.input[start + 2 .. status.i];
            status.description = comment;
        }
        return;
    }

    // Check for macros
    if (accept('@', status)) {
        const macro_start = status.i;
        while (status.i < status.input.len and !std.ascii.isWhitespace(status.input[status.i]) and status.input[status.i] != '(') {
            status.i += 1;
        }
        const macro = status.input[macro_start..status.i];
        trim(status);
        expect('(', status);

        if (std.mem.eql(u8, macro, "mix")) {
            trim(status);
            expect('{', status);
            var inner_list: std.ArrayList(Schema) = .empty;
            errdefer {
                for (inner_list.items) |*item| {
                    var iter = item.iterator();
                    while (iter.next()) |entry| {
                        allocator.free(entry.key_ptr.*);
                        entry.value_ptr.deinit(allocator);
                    }
                    item.deinit();
                }
                inner_list.deinit(allocator);
            }

            const type_dup = allocator.dupe(u8, "mix") catch return;
            var mix_result = MixSchema{
                .type = type_dup,
                .inner = inner_list,
            };

            const inner_schema = parseObject(allocator, status) catch {
                allocator.free(mix_result.type);
                return;
            };
            mix_result.inner.append(allocator, inner_schema) catch {
                allocator.free(mix_result.type);
                return;
            };

            trim(status);
            while (accept('|', status)) {
                trim(status);
                expect('{', status);
                const alt_schema = parseObject(allocator, status) catch continue;
                mix_result.inner.append(allocator, alt_schema) catch continue;
                trim(status);
            }

            expect(')', status);

            const key = std.fmt.allocPrint(allocator, "mix${d}", .{status.mix_counter}) catch return;
            status.mix_counter += 1;
            result.put(key, .{ .mix = mix_result }) catch {
                allocator.free(key);
                mix_result.deinit(allocator);
            };
        } else if (std.mem.eql(u8, macro, "props")) {
            trim(status);

            const pattern_start = status.i;
            var level: usize = 1;
            while (status.i < status.input.len) {
                const ch = status.input[status.i];
                if (ch == '(' and (status.i == 0 or status.input[status.i - 1] != '\\')) {
                    level += 1;
                } else if (ch == ')' and (status.i == 0 or status.input[status.i - 1] != '\\')) {
                    level -= 1;
                    if (level == 0) break;
                } else if (std.ascii.isWhitespace(ch)) {
                    break;
                }
                status.i += 1;
            }
            const pattern = status.input[pattern_start..status.i];
            trim(status);
            expect(')', status);
            trim(status);
            expect(':', status);

            const inner_value = parseValue(allocator, status) catch return;
            const inner = allocator.create(SchemaValue) catch return;
            inner.* = inner_value;

            const key = std.fmt.allocPrint(allocator, "props${d}", .{status.any_counter}) catch return;
            status.any_counter += 1;

            const pattern_dup = allocator.dupe(u8, pattern) catch return;

            result.put(key, .{
                .any = AnySchema{
                    .type = pattern_dup,
                    .inner = inner,
                },
            }) catch {
                allocator.free(key);
                allocator.free(pattern_dup);
                inner.deinit(allocator);
                allocator.destroy(inner);
            };
        } else {
            addError(status, "Unknown macro", macro_start, macro.len);
        }

        return;
    }

    // Parse field name
    const name = blk: {
        if (accept('"', status)) {
            const parsed = parseString(allocator, status, false);
            if (parsed) |p| {
                break :blk p;
            } else |_| {
                return;
            }
        } else {
            if (status.i >= status.input.len or !isAlphaOrUnderscore(status.input[status.i])) {
                addError(status, "Field must start with quote or alpha", start, 1);
                status.i += 1;
                return;
            }
            status.i += 1;
            while (status.i < status.input.len and isAlphaNumericOrUnderscore(status.input[status.i])) {
                status.i += 1;
            }
            const name_str = status.input[start..status.i];
            break :blk allocator.dupe(u8, name_str) catch return;
        }
    };
    errdefer allocator.free(name);

    // Check if field name is followed by invalid characters (like hyphen in field-name)
    // Only return InvalidFieldName if we see alphanumeric or underscore (field name continues)
    // or hyphen (invalid character in field name). Let delimiters pass through to expect(':').
    if (status.i < status.input.len and
        (status.input[status.i] == '-' or isAlphaNumericOrUnderscore(status.input[status.i])))
    {
        addError(status, "Invalid field name", start, status.i - start + 1);
        allocator.free(name);
        return;
    }

    trim(status);
    expect(':', status);

    const value = parseValue(allocator, status) catch {
        addError(status, "Unsupported value type", status.i, 0);
        allocator.free(name);
        return;
    };

    // After parsing a value, check if it's a string type followed immediately by an alphabetic character
    // This indicates an unescaped quote issue like: "Hello "World""
    if (value == .field and std.mem.startsWith(u8, value.field.type, "\"") and
        status.i < status.input.len and std.ascii.isAlphabetic(status.input[status.i]))
    {
        // Clean up the parsed value before returning error
        var val_copy = value;
        val_copy.deinit(allocator);
        allocator.free(name);
        addError(status, "Expected ':'", status.i, 1);
        return;
    }

    result.put(name, value) catch {
        allocator.free(name);
        var val_copy = value;
        val_copy.deinit(allocator);
    };
}

fn parseValue(allocator: Allocator, status: *Status) anyerror!SchemaValue {
    var value = try parseSingleValue(allocator, status);

    trim(status);
    if (accept('|', status)) {
        var union_values: std.ArrayList(SchemaValue) = .empty;
        errdefer {
            for (union_values.items) |*item| {
                item.deinit(allocator);
            }
            union_values.deinit(allocator);
        }

        try union_values.append(allocator, value);

        while (true) {
            trim(status);
            const next_value = parseSingleValue(allocator, status) catch break;
            try union_values.append(allocator, next_value);
            trim(status);

            if (!accept('|', status)) {
                break;
            }
        }

        value = .{ .union_type = UnionSchema{
            .type = try allocator.dupe(u8, "union"),
            .inner = union_values,
        } };
    }

    return value;
}

fn parseSingleValue(allocator: Allocator, status: *Status) anyerror!SchemaValue {
    trim(status);
    if (accept('{', status)) {
        const inner = try parseObject(allocator, status);
        return .{
            .object = ObjectSchema{
                .type = try allocator.dupe(u8, "object"),
                .inner = inner,
            },
        };
    } else if (accept('[', status)) {
        const inner = try parseArray(allocator, status);
        return .{
            .array = ArraySchema{
                .type = try allocator.dupe(u8, "array"),
                .inner = inner,
            },
        };
    } else if (accept('"', status)) {
        const parsed = try parseString(allocator, status, true);
        return .{ .field = FieldSchema{
            .type = parsed,
        } };
    } else {
        return parseType(allocator, status);
    }
}

fn parseType(allocator: Allocator, status: *Status) anyerror!SchemaValue {
    const start = status.i;
    while (status.i < status.input.len and !isDelim(status.input[status.i]) and !std.ascii.isWhitespace(status.input[status.i])) {
        status.i += 1;
    }
    const type_str = std.mem.trim(u8, status.input[start..status.i], &std.ascii.whitespace);

    if (!isBasicType(type_str)) {
        _ = convertValue(allocator, type_str) catch {
            addError(status, "Invalid type name", start, type_str.len);
            return error.ParseError;
        };
    }

    var result = FieldSchema{
        .type = try allocator.dupe(u8, type_str),
    };
    errdefer {
        allocator.free(result.type);
        if (result.description) |desc| {
            allocator.free(desc);
        }
        if (result.validators) |*vals| {
            var iter = vals.iterator();
            while (iter.next()) |entry| {
                allocator.free(entry.key_ptr.*);
                allocator.free(entry.value_ptr.raw);
            }
            vals.deinit();
        }
    }

    if (status.description.len > 0) {
        const desc = std.mem.trim(u8, status.description, &std.ascii.whitespace);
        result.description = try allocator.dupe(u8, desc);
        status.description = "";
    }

    trim(status);
    while (status.i < status.input.len and !isDelim(status.input[status.i])) {
        const validator_start = status.i;
        while (status.i < status.input.len and !isDelim(status.input[status.i]) and status.input[status.i] != '(') {
            status.i += 1;
        }
        const validator = std.mem.trim(u8, status.input[validator_start..status.i], &std.ascii.whitespace);

        if (isTypeWithValidators(type_str) and !isValidatorSupported(type_str, validator)) {
            addError(status, "Unsupported validator", validator_start, validator.len);
            continue;
        }

        var raw: []const u8 = "true";
        var raw_allocated = false;
        var required = true;

        trim(status);
        if (accept('(', status)) {
            trim(status);
            if (accept('"', status)) {
                raw = try parseString(allocator, status, true);
                raw_allocated = true;
                required = isTruthy(raw);
            } else if (accept('/', status)) {
                raw = try parseRegex(allocator, status);
                raw_allocated = true;
                required = isTruthy(raw);
            } else {
                const raw_start = status.i;
                while (status.i < status.input.len and !std.ascii.isWhitespace(status.input[status.i]) and status.input[status.i] != ')') {
                    status.i += 1;
                }
                raw = std.mem.trim(u8, status.input[raw_start..status.i], &std.ascii.whitespace);
                required = isTruthy(raw);
            }
            trim(status);
            expect(')', status);
            trim(status);
        }

        if (result.validators == null) {
            result.validators = std.StringArrayHashMap(Validator).init(allocator);
        }

        if (raw_allocated) {
            try result.validators.?.put(
                try allocator.dupe(u8, validator),
                Validator{
                    .raw = raw,
                    .required = required,
                },
            );
        } else {
            try result.validators.?.put(
                try allocator.dupe(u8, validator),
                Validator{
                    .raw = try allocator.dupe(u8, raw),
                    .required = required,
                },
            );
        }
    }

    return .{ .field = result };
}

fn parseString(allocator: Allocator, status: *Status, with_quotes: bool) anyerror![]const u8 {
    const start = if (with_quotes) status.i - 1 else status.i;

    while (status.i < status.input.len) {
        if (status.input[status.i] == '\\') {
            status.i += 1;
            if (status.i >= status.input.len) {
                addError(status, "Invalid escape sequence", status.i - 1, 2);
                return error.ParseError;
            }
            // Only " is a valid escape sequence
            if (status.input[status.i] != '"') {
                addError(status, "Invalid escape sequence", status.i - 1, 2);
                return error.ParseError;
            }
            status.i += 1;
            continue;
        }
        if (status.input[status.i] == '"') {
            break;
        }
        status.i += 1;
    }

    if (status.i >= status.input.len) {
        addError(status, "String not closed", start, status.i - start);
        return error.ParseError;
    }

    status.i += 1;
    const end = if (with_quotes) status.i else status.i - 1;
    return try allocator.dupe(u8, status.input[start..end]);
}

fn parseRegex(allocator: Allocator, status: *Status) anyerror![]const u8 {
    const start = status.i - 1;

    while (status.i < status.input.len and !(status.input[status.i] == '/' and (status.i == 0 or status.input[status.i - 1] != '\\'))) {
        status.i += 1;
    }

    if (status.i >= status.input.len) {
        addError(status, "Invalid regex", start, status.i - start);
        return error.ParseError;
    }

    while (status.i < status.input.len and !std.ascii.isWhitespace(status.input[status.i]) and status.input[status.i] != ')') {
        status.i += 1;
    }

    return try allocator.dupe(u8, status.input[start..status.i]);
}

/// Check if type is a basic type
fn isBasicType(type_str: []const u8) bool {
    return std.mem.eql(u8, type_str, "undef") or
        std.mem.eql(u8, type_str, "null") or
        std.mem.eql(u8, type_str, "bool") or
        std.mem.eql(u8, type_str, "int") or
        std.mem.eql(u8, type_str, "num") or
        std.mem.eql(u8, type_str, "string") or
        std.mem.eql(u8, type_str, "date");
}

/// Check if type has validators
fn isTypeWithValidators(type_str: []const u8) bool {
    return std.mem.eql(u8, type_str, "bool") or
        std.mem.eql(u8, type_str, "int") or
        std.mem.eql(u8, type_str, "num") or
        std.mem.eql(u8, type_str, "date") or
        std.mem.eql(u8, type_str, "string");
}

/// Check if validator is supported for type
fn isValidatorSupported(type_str: []const u8, validator: []const u8) bool {
    if (std.mem.eql(u8, type_str, "int")) {
        return std.mem.eql(u8, validator, "min") or std.mem.eql(u8, validator, "max");
    }
    if (std.mem.eql(u8, type_str, "num")) {
        return std.mem.eql(u8, validator, "min") or std.mem.eql(u8, validator, "max");
    }
    if (std.mem.eql(u8, type_str, "date")) {
        return std.mem.eql(u8, validator, "min") or std.mem.eql(u8, validator, "max");
    }
    if (std.mem.eql(u8, type_str, "string")) {
        return std.mem.eql(u8, validator, "minlen") or std.mem.eql(u8, validator, "maxlen") or std.mem.eql(u8, validator, "pattern");
    }
    return true;
}

/// Helper function to check if character is alphabetic or underscore
fn isAlphaOrUnderscore(ch: u8) bool {
    return ch == '_' or std.ascii.isAlphabetic(ch);
}

/// Helper function to check if character is alphanumeric or underscore
fn isAlphaNumericOrUnderscore(ch: u8) bool {
    return ch == '_' or std.ascii.isAlphanumeric(ch);
}

/// Helper function to check if character is a delimiter
fn isDelim(ch: u8) bool {
    return ch == '|' or ch == ',' or ch == '}' or ch == ']';
}

/// Helper function to check if character is a delimiter or parenthesis
fn isDelimOrParen(ch: u8) bool {
    return isDelim(ch) or ch == '(' or ch == ')';
}
