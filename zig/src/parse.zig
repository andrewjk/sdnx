const std = @import("std");
const Allocator = std.mem.Allocator;

const Value = @import("./types/Value.zig").Value;

/// Status tracks the current parsing position
pub const Status = struct {
    input: []const u8,
    i: usize,
};

const ParseError = error{
    UnexpectedEnd,
    ObjectNotClosed,
    ArrayNotClosed,
    ValueNotSet,
    UnterminatedString,
    InvalidCharacter,
    ExpectedBrace,
    ExpectedChar,
    InvalidFieldName,
    InvalidEscapeSequence,
    Overflow,
    UnsupportedValueType,
} || std.mem.Allocator.Error;

/// Trim whitespace from current position
pub fn trim(status: *Status) void {
    while (status.i < status.input.len and std.ascii.isWhitespace(status.input[status.i])) {
        status.i += 1;
    }
}

/// Accept a specific character and advance if found
pub fn accept(ch: u8, status: *Status) bool {
    if (status.i < status.input.len and status.input[status.i] == ch) {
        status.i += 1;
        return true;
    }
    return false;
}

/// Expect a specific character, throw error if not found
pub fn expect(ch: u8, status: *Status) !void {
    if (status.i < status.input.len and status.input[status.i] == ch) {
        status.i += 1;
        return;
    }
    return error.ExpectedChar;
}

/// Parse structured data from input string into a value
pub fn parse(allocator: Allocator, input: []const u8) ParseError!Value {
    var status = Status{
        .input = input,
        .i = 0,
    };

    trim(&status);

    while (accept('#', &status)) {
        parseComment(&status);
        trim(&status);
    }

    if (accept('{', &status)) {
        return parseObject(allocator, &status);
    } else {
        return error.ExpectedBrace;
    }
}

fn parseObject(allocator: Allocator, status: *Status) ParseError!Value {
    var result = std.StringHashMap(Value).init(allocator);
    errdefer {
        var iter = result.iterator();
        while (iter.next()) |entry| {
            entry.value_ptr.deinit(allocator);
            allocator.free(entry.key_ptr.*);
        }
        result.deinit();
    }

    while (true) {
        trim(status);
        if (accept('}', status)) {
            break;
        } else if (status.i >= status.input.len or accept(']', status)) {
            return error.ObjectNotClosed;
        }

        try parseField(allocator, status, &result);

        trim(status);
        _ = accept(',', status);
    }

    return .{ .object = result };
}

fn parseArray(allocator: Allocator, status: *Status) ParseError!Value {
    var result: std.ArrayList(Value) = .empty;
    errdefer {
        for (result.items) |*item| {
            item.deinit(allocator);
        }
        result.deinit(allocator);
    }

    while (true) {
        trim(status);
        if (accept(']', status)) {
            break;
        } else if (status.i >= status.input.len or accept('}', status)) {
            return error.ArrayNotClosed;
        } else if (result.items.len > 0) {
            // After an item, we expect either ']' or ','
            if (status.i < status.input.len and status.input[status.i] == ',') {
                status.i += 1;
                trim(status);
            } else if (status.i < status.input.len and status.input[status.i] == ']') {
                // Trailing comma case: allow comma before ]
                continue;
            } else {
                // Invalid character after array item (not comma or closing bracket)
                return error.InvalidCharacter;
            }
        }

        const value = try parseValue(allocator, status);
        try result.append(allocator, value);
    }

    return .{ .array = result };
}

fn parseField(allocator: Allocator, status: *Status, result: *std.StringHashMap(Value)) !void {
    trim(status);

    if (accept('#', status)) {
        parseComment(status);
        return;
    }

    const start = status.i;
    const name = blk: {
        if (accept('"', status)) {
            while (status.i < status.input.len) {
                if (status.input[status.i] == '\\') {
                    status.i += 1;
                    if (status.i >= status.input.len) {
                        return error.InvalidEscapeSequence;
                    }
                } else if (status.input[status.i] == '"') {
                    status.i += 1;
                    break;
                }
                status.i += 1;
            }
            if (status.i >= status.input.len) {
                return error.UnterminatedString;
            }
            break :blk status.input[start..status.i];
        } else if (status.i < status.input.len and isAlphaOrUnderscore(status.input[status.i])) {
            status.i += 1;
            while (status.i < status.input.len and isAlphaNumericOrUnderscore(status.input[status.i])) {
                status.i += 1;
            }
            break :blk status.input[start..status.i];
        } else {
            return error.InvalidFieldName;
        }
    };

    // Check if field name is followed by invalid characters (like hyphen in field-name)
    // Only return InvalidFieldName if we see alphanumeric or underscore (field name continues)
    // or hyphen (invalid character in field name). Let delimiters pass through to expect(':').
    if (status.i < status.input.len and
        (status.input[status.i] == '-' or isAlphaNumericOrUnderscore(status.input[status.i])))
    {
        return error.InvalidFieldName;
    }

    // Check for double colon (e.g., "name::" instead of "name:")
    if (status.i + 1 < status.input.len and
        status.input[status.i] == ':' and status.input[status.i + 1] == ':')
    {
        return error.InvalidFieldName;
    }

    trim(status);
    try expect(':', status);

    const value = try parseValue(allocator, status);
    const name_dup = try allocator.dupe(u8, name);
    errdefer allocator.free(name_dup);

    // After parsing a value, check if it's a string followed immediately by an alphabetic character
    // This indicates an unescaped quote issue like: "Hello "World""
    if (value == .string and std.mem.startsWith(u8, value.string, "\"") and
        status.i < status.input.len and std.ascii.isAlphabetic(status.input[status.i]))
    {
        // Clean up the parsed value before returning error
        value.deinit(allocator);
        return error.ExpectedChar;
    }

    try result.put(name_dup, value);
}

fn parseValue(allocator: Allocator, status: *Status) ParseError!Value {
    trim(status);
    if (accept('{', status)) {
        return parseObject(allocator, status);
    } else if (accept('[', status)) {
        return parseArray(allocator, status);
    } else if (accept('"', status)) {
        return .{ .string = try parseString(status) };
    } else {
        const start = status.i;
        while (status.i < status.input.len and !isValueTerminator(status.input[status.i])) {
            status.i += 1;
        }
        const value_str = std.mem.trim(u8, status.input[start..status.i], &std.ascii.whitespace);

        if (isDateString(value_str) and (isValidDateOrDateTime(value_str) or isValidTime(value_str))) {
            return .{ .date = try allocator.dupe(u8, value_str) };
        }

        const value = try convertValue(value_str);
        return value;
    }
}

fn parseString(status: *Status) ParseError![]const u8 {
    const start = status.i;

    while (status.i < status.input.len) {
        if (status.input[status.i] == '\\') {
            status.i += 1;
            if (status.input[status.i] != '"') {
                return error.InvalidEscapeSequence;
            }
        } else if (status.input[status.i] == '"') {
            status.i += 1;
            break;
        }

        status.i += 1;
    }

    if (status.i >= status.input.len) {
        return error.UnterminatedString;
    }

    var value = status.input[start .. status.i - 1];

    // Trim leading spaces from multiline strings
    if (value.len > 0 and value[0] == '\n') {
        const space = value[0 .. std.mem.indexOfScalar(u8, value, ' ') orelse 0];
        value = value[space.len..];
        if (value.len > 0 and value[0] == ' ') {
            value = value[1..];
        }
    }

    return value;
}

fn parseComment(status: *Status) void {
    while (status.i < status.input.len and status.input[status.i] != '\n') {
        status.i += 1;
    }
}

/// Helper function to check if character is alphabetic or underscore
fn isAlphaOrUnderscore(ch: u8) bool {
    return ch == '_' or std.ascii.isAlphabetic(ch);
}

/// Helper function to check if character is alphanumeric or underscore
fn isAlphaNumericOrUnderscore(ch: u8) bool {
    return ch == '_' or std.ascii.isAlphanumeric(ch);
}

/// Helper function to check if character terminates a value
fn isValueTerminator(ch: u8) bool {
    return std.ascii.isWhitespace(ch) or ch == ',' or ch == '}' or ch == ']';
}

fn isDateString(input: []const u8) bool {
    // Date: YYYY-MM-DD
    if (input.len == 10 and input[4] == '-' and input[7] == '-') return true;
    // Time: HH:MM or HH:MM:SS
    if (input.len >= 5 and input.len <= 8 and input[2] == ':') return true;
    // Datetime without seconds: YYYY-MM-DDTHH:MM (16 chars minimum, plus optional timezone)
    if (input.len >= 16 and input[4] == '-' and input[7] == '-' and input[10] == 'T' and input[13] == ':') return true;
    // Datetime with seconds: YYYY-MM-DDTHH:MM:SS (19 chars minimum, plus optional timezone)
    if (input.len >= 19 and input[4] == '-' and input[7] == '-' and input[10] == 'T' and input[13] == ':' and input[16] == ':') return true;
    return false;
}

/// Convert a string value to appropriate type
fn convertValue(value_str: []const u8) ParseError!Value {
    if (std.mem.eql(u8, value_str, "null")) {
        return .{ .null = {} };
    } else if (std.mem.eql(u8, value_str, "true")) {
        return .{ .bool = true };
    } else if (std.mem.eql(u8, value_str, "false")) {
        return .{ .bool = false };
    } else if (value_str.len >= 2 and value_str[0] == '"' and value_str[value_str.len - 1] == '"') {
        return .{ .string = value_str[1 .. value_str.len - 1] };
    } else if (value_str.len >= 2 and value_str[0] == '/') {
        return .{ .string = value_str };
    } else if (isInt(value_str)) {
        const cleaned = removeUnderscores(value_str);
        if (std.mem.indexOfScalar(u8, value_str, 'x') != null or std.mem.indexOfScalar(u8, value_str, 'X') != null) {
            const hex_str = if (cleaned.len >= 2 and cleaned[0] == '0' and (cleaned[1] == 'x' or cleaned[1] == 'X')) cleaned[2..] else cleaned;
            const int_val = try std.fmt.parseInt(i64, hex_str, 16);
            return .{ .int = int_val };
        }
        const int_val = try std.fmt.parseInt(i64, cleaned, 10);
        return .{ .int = int_val };
    } else if (isFloat(value_str) or isScientific(value_str)) {
        const cleaned = removeUnderscores(value_str);
        const float_val = try std.fmt.parseFloat(f64, cleaned);
        return .{ .num = float_val };
    } else if (isValidDateOrDateTime(value_str) or isValidTime(value_str)) {
        return .{ .string = value_str };
    } else {
        return error.UnsupportedValueType;
    }
}

/// Check if string is an integer
fn isInt(s: []const u8) bool {
    if (s.len == 0) return false;
    var i: usize = 0;
    if (s[0] == '+' or s[0] == '-') {
        i = 1;
        if (i >= s.len) return false;
    }
    if (s.len >= 2 and s[i] == '0' and (s[i + 1] == 'x' or s[i + 1] == 'X')) {
        i += 2;
        while (i < s.len) {
            if (!(std.ascii.isDigit(s[i]) or (s[i] >= 'a' and s[i] <= 'f') or (s[i] >= 'A' and s[i] <= 'F'))) {
                if (s[i] != '_') return false;
            }
            i += 1;
        }
        return true;
    }
    while (i < s.len) {
        if (!std.ascii.isDigit(s[i]) and s[i] != '_') {
            return false;
        }
        i += 1;
    }
    return true;
}

/// Check if string is a float
fn isFloat(s: []const u8) bool {
    if (s.len == 0) return false;
    var i: usize = 0;
    if (s[0] == '+' or s[0] == '-') {
        i = 1;
        if (i >= s.len) return false;
    }
    var has_dot = false;
    var has_digit_before = false;
    var has_digit_after = false;
    while (i < s.len) {
        if (s[i] == '.') {
            if (has_dot) return false;
            has_dot = true;
        } else if (std.ascii.isDigit(s[i])) {
            if (has_dot) {
                has_digit_after = true;
            } else {
                has_digit_before = true;
            }
        } else if (s[i] != '_') {
            return false;
        }
        i += 1;
    }
    return has_dot and has_digit_before and has_digit_after;
}

/// Check if string is scientific notation
fn isScientific(s: []const u8) bool {
    const has_e = std.mem.indexOfScalar(u8, s, 'e') != null or std.mem.indexOfScalar(u8, s, 'E') != null;
    if (!has_e) return false;

    var i: usize = 0;
    if (s[0] == '+' or s[0] == '-') {
        i = 1;
    }
    var has_dot = false;
    var found_e = false;
    var has_exponent_digit = false;

    while (i < s.len) {
        if (s[i] == 'e' or s[i] == 'E') {
            if (found_e) return false;
            found_e = true;
            i += 1;
            if (i < s.len and (s[i] == '+' or s[i] == '-')) {
                i += 1;
            }
            continue;
        }
        if (found_e) {
            if (!std.ascii.isDigit(s[i])) return false;
            has_exponent_digit = true;
        } else {
            if (s[i] == '.') {
                if (has_dot) return false;
                has_dot = true;
            } else if (!std.ascii.isDigit(s[i]) and s[i] != '_') {
                return false;
            }
        }
        i += 1;
    }
    return found_e and has_exponent_digit;
}

/// Validate date format: YYYY-MM-DD
fn isValidDate(s: []const u8) bool {
    if (s.len < 10) return false;

    // Check format: YYYY-MM-DD
    if (s[4] != '-' or s[7] != '-') return false;

    // Parse year
    const year = std.fmt.parseInt(u32, s[0..4], 10) catch return false;
    _ = year;

    // Parse month
    const month = std.fmt.parseInt(u32, s[5..7], 10) catch return false;
    if (month < 1 or month > 12) return false;

    // Parse day
    const day = std.fmt.parseInt(u32, s[8..10], 10) catch return false;
    if (day < 1 or day > 31) return false;

    return true;
}

/// Validate time format: HH:MM or HH:MM:SS
fn isValidTime(s: []const u8) bool {
    if (s.len < 5) return false;
    if (s[2] != ':') return false;

    // Parse hour
    const hour = std.fmt.parseInt(u32, s[0..2], 10) catch return false;
    if (hour > 23) return false;

    // Parse minute
    const minute = std.fmt.parseInt(u32, s[3..5], 10) catch return false;
    if (minute > 59) return false;

    // If seconds present, validate them
    if (s.len >= 8) {
        if (s[5] != ':') return false;
        const second = std.fmt.parseInt(u32, s[6..8], 10) catch return false;
        if (second > 59) return false;
    }

    return true;
}

/// Validate datetime format: YYYY-MM-DDTHH:MM or YYYY-MM-DDTHH:MM:SS or with timezone
fn isValidDateTime(s: []const u8) bool {
    // Find separator (T or space)
    const sep_index = std.mem.indexOfScalar(u8, s, 'T') orelse std.mem.indexOfScalar(u8, s, ' ') orelse return false;

    // Validate date part
    const date_part = s[0..sep_index];
    if (!isValidDate(date_part)) return false;

    // Validate time part
    var time_part = s[sep_index + 1 ..];
    if (time_part.len < 5) return false;

    // Handle ISO 8601 timezone indicators: U (UTC), L (local time)
    if (time_part.len > 0 and (time_part[time_part.len - 1] == 'U' or time_part[time_part.len - 1] == 'L')) {
        time_part = time_part[0 .. time_part.len - 1];
    }

    // Handle timezone offset if present (e.g., +02:00, -05:00)
    var time_only = time_part;
    if (time_part.len > 0) {
        // Look for + or - after position 0 (could be start of timezone offset)
        var tz_start: usize = time_part.len;
        for (time_part, 0..) |c, i| {
            if (i > 0 and (c == '+' or c == '-')) {
                tz_start = i;
                break;
            }
        }
        if (tz_start < time_part.len) {
            time_only = time_part[0..tz_start];
        }
    }

    return isValidTime(time_only);
}

/// Check if string is a valid date or datetime
fn isValidDateOrDateTime(s: []const u8) bool {
    // Check for datetime separator
    const has_datetime_sep = std.mem.indexOfScalar(u8, s, 'T') != null or std.mem.indexOfScalar(u8, s, ' ') != null;

    // If it has datetime separator, validate the full datetime format
    if (has_datetime_sep) {
        return isValidDateTime(s);
    }

    // Check if it looks like a date (has dashes)
    if (std.mem.count(u8, s, "-") >= 2) {
        return isValidDate(s);
    }

    return false;
}

/// Remove underscores from a string
fn removeUnderscores(s: []const u8) []const u8 {
    var has_underscore = false;
    for (s) |ch| {
        if (ch == '_') {
            has_underscore = true;
            break;
        }
    }
    if (!has_underscore) return s;

    var buf: [256]u8 = undefined;
    var buf_len: usize = 0;
    for (s) |ch| {
        if (ch != '_') {
            buf[buf_len] = ch;
            buf_len += 1;
        }
    }
    return buf[0..buf_len];
}
