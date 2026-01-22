const std = @import("std");

/// Adds spaces around structural characters: {}[]:,
/// Preserves content inside strings and comments
pub fn space(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    const spaced_chars = "{}[]():,";
    var result: std.ArrayList(u8) = .empty;
    errdefer result.deinit(allocator);

    var i: usize = 0;
    while (i < input.len) {
        const char = input[i];

        if (char == '"') {
            // Handle string literals - preserve content
            try result.appendSlice(allocator, " \"");
            i += 1;
            while (i < input.len) {
                const current = input[i];
                try result.append(allocator, current);
                if (current == '"' and (i == 0 or input[i - 1] != '\\')) {
                    break;
                }
                i += 1;
            }
        } else if (char == '#') {
            // Handle comments - preserve content
            try result.appendSlice(allocator, " #");
            i += 1;
            while (i < input.len and input[i] != '\n') {
                try result.append(allocator, input[i]);
                i += 1;
            }
            if (i < input.len) {
                try result.append(allocator, input[i]); // Add the newline
            }
        } else if (std.mem.indexOf(u8, spaced_chars, &[1]u8{char}) != null) {
            // Add spaces around structural characters
            try result.append(allocator, ' ');
            try result.append(allocator, char);
            try result.append(allocator, ' ');
        } else {
            try result.append(allocator, char);
        }

        if (i < input.len) {
            i += 1;
        }
    }

    return result.toOwnedSlice(allocator);
}

/// Removes unnecessary whitespace while preserving content inside strings and comments
pub fn unspace(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    var result: std.ArrayList(u8) = .empty;
    errdefer result.deinit(allocator);

    var i: usize = 0;
    while (i < input.len) {
        const char = input[i];

        if (char == '"') {
            // Handle string literals - preserve content
            try result.append(allocator, char);
            i += 1;
            while (i < input.len) {
                const current = input[i];
                try result.append(allocator, current);
                if (current == '"' and (i == 0 or input[i - 1] != '\\')) {
                    break;
                }
                i += 1;
            }
        } else if (char == '#') {
            // Handle comments - preserve content with space before #
            try result.appendSlice(allocator, " #");
            i += 1;
            while (i < input.len and input[i] != '\n') {
                try result.append(allocator, input[i]);
                i += 1;
            }
            if (i < input.len) {
                try result.append(allocator, input[i]); // Add the newline
            }
        } else if (char != ' ' and char != '\t' and char != '\n') {
            // Keep non-whitespace characters
            try result.append(allocator, char);
        }

        if (i < input.len) {
            i += 1;
        }
    }

    return result.toOwnedSlice(allocator);
}

/// Replaces all occurrences of a pattern with a replacement string
/// Caller owns returned memory
pub fn replaceAll(allocator: std.mem.Allocator, input: []const u8, pattern: []const u8, replacement: []const u8) ![]u8 {
    var result: std.ArrayList(u8) = .empty;
    errdefer result.deinit(allocator);

    var i: usize = 0;
    while (i < input.len) {
        if (i + pattern.len <= input.len and std.mem.eql(u8, input[i .. i + pattern.len], pattern)) {
            try result.appendSlice(allocator, replacement);
            i += pattern.len;
        } else {
            try result.append(allocator, input[i]);
            i += 1;
        }
    }

    return result.toOwnedSlice(allocator);
}

/// Applies validator replacements needed after unspacing schema strings
/// Replaces patterns like "min(" with " min(" to fix validator parsing
pub fn applyUnspaceReplacements(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    var result = try allocator.dupe(u8, input);
    errdefer allocator.free(result);

    // Apply replacements in order (must match TypeScript: min, max, len, minlen)
    const replacements = .{
        .{ "min(", " min(" },
        .{ "max(", " max(" },
        .{ "len(", " len(" },
        .{ "min len(", " minlen(" },
    };

    inline for (replacements) |rep| {
        const temp = try replaceAll(allocator, result, rep[0], rep[1]);
        allocator.free(result);
        result = temp;
    }

    return result;
}
