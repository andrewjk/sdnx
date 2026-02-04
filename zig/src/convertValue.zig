const std = @import("std");
const Allocator = std.mem.Allocator;

const Value = @import("./types/Value.zig").Value;

const UnsupportedValueError = error{UnsupportedValueType};

/// Convert a string value to its appropriate Value type
/// Returns UnsupportedValueError if the value type is unsupported
pub fn convertValue(allocator: Allocator, value: []const u8) !Value {
    // Check for null
    if (std.mem.eql(u8, value, "null")) {
        return .null;
    }

    // Check for boolean
    if (std.mem.eql(u8, value, "true")) {
        return .{ .bool = true };
    }
    if (std.mem.eql(u8, value, "false")) {
        return .{ .bool = false };
    }

    // Check for string (quoted)
    if (isString(value)) {
        return .{ .string = tryParseStringContent(allocator, value) };
    }

    // Check for regex
    if (isRegex(value)) {
        return .{ .string = try allocator.dupe(u8, value) };
    }

    // Check for integer
    if (isInt(value)) {
        const without_underscores = removeUnderscores(value);
        if (std.fmt.parseInt(i64, without_underscores, 0)) |int_val| {
            return .{ .int = int_val };
        } else |_| {}
    }

    // Check for float or scientific notation
    if (isFloat(value) or isScientific(value)) {
        const without_underscores = removeUnderscores(value);
        if (std.fmt.parseFloat(f64, without_underscores)) |float_val| {
            return .{ .num = float_val };
        } else |_| {}
    }

    // Unsupported value type
    return UnsupportedValueError.UnsupportedValueType;
}

/// Check if a value is "truthy" (used for validator values)
/// Returns true if the value represents a truthy value (true, non-zero number, non-empty string)
pub fn isTruthy(value: []const u8) bool {
    // Boolean true
    if (std.mem.eql(u8, value, "true")) {
        return true;
    }
    // Boolean false
    if (std.mem.eql(u8, value, "false")) {
        return false;
    }

    // Check for number
    const without_underscores = removeUnderscores(value);
    if (std.fmt.parseInt(i64, without_underscores, 0)) |int_val| {
        return int_val != 0;
    } else |_| {}
    if (std.fmt.parseFloat(f64, without_underscores)) |float_val| {
        return float_val != 0.0;
    } else |_| {}

    // Non-empty string is truthy
    return value.len > 0;
}

/// Check if string is a quoted string
fn isString(s: []const u8) bool {
    return s.len >= 2 and s[0] == '"' and s[s.len - 1] == '"';
}

/// Extract content from quoted string (without the quotes)
fn tryParseStringContent(allocator: Allocator, s: []const u8) []const u8 {
    if (s.len < 2) return "";
    return allocator.dupe(u8, s[1 .. s.len - 1]) catch "";
}

/// Check if string is a regex pattern
fn isRegex(s: []const u8) bool {
    if (s.len < 2) return false;
    if (s[0] != '/') return false;

    var i: usize = 1;
    while (i < s.len) {
        if (s[i] == '/') {
            // Found closing slash, check for flags
            i += 1;
            while (i < s.len) {
                const c = s[i];
                if (!(c == 'g' or c == 'm' or c == 'i' or c == 'x' or c == 's' or c == 'u' or c == 'U' or c == 'A' or c == 'J' or c == 'D')) {
                    return false;
                }
                i += 1;
            }
            return true;
        }
        i += 1;
    }
    return false;
}

/// Check if string is an integer (including hex)
fn isInt(s: []const u8) bool {
    if (s.len == 0) return false;
    var i: usize = 0;
    if (s[0] == '+' or s[0] == '-') {
        i = 1;
        if (i >= s.len) return false;
    }
    // Check for hex
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
    // Decimal
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
