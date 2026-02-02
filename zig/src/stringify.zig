const std = @import("std");
const Allocator = std.mem.Allocator;
const Value = @import("./types/Value.zig").Value;
const parse = @import("parse.zig");

/// Options for stringification
pub const Options = struct {
    ansi: bool = false,
    indent: []const u8 = "\t",
};

/// Status tracks stringification state
const Status = struct {
    indent: usize,
    result: std.ArrayListUnmanaged(u8),
    ansi: bool,
    indentText: []const u8,
    allocator: Allocator,

    pub fn init(allocator: Allocator, ansi: bool, indentText: []const u8) Status {
        return Status{
            .indent = 0,
            .result = .empty,
            .ansi = ansi,
            .indentText = indentText,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Status) void {
        self.result.deinit(self.allocator);
    }
};

/// Converts a Value into a string containing Structured Data Notation
pub fn stringify(allocator: Allocator, value: Value, options: ?*const Options) ![]const u8 {
    const opts = options orelse &Options{};
    var status = Status.init(allocator, opts.ansi, opts.indent);
    defer status.deinit();

    try printValue(allocator, value, &status);

    return status.result.toOwnedSlice(allocator);
}

fn printValue(allocator: Allocator, value: Value, status: *Status) !void {
    switch (value) {
        .array => |arr| {
            try status.result.append(allocator, '[');
            status.indent += 1;

            for (arr.items, 0..) |item, i| {
                try status.result.append(allocator, '\n');
                indent(status);
                try printValue(allocator, item, status);
                if (i < arr.items.len - 1) {
                    try status.result.append(allocator, ',');
                }
            }

            status.indent -= 1;
            try status.result.append(allocator, '\n');
            indent(status);
            try status.result.append(allocator, ']');
        },
        .date => |d| {
            if (status.ansi) {
                const formatted = try std.fmt.allocPrint(allocator, "\x1b[35m{s}\x1b[0m", .{d});
                defer allocator.free(formatted);
                try status.result.appendSlice(allocator, formatted);
            } else {
                try status.result.appendSlice(allocator, d);
            }
        },
        .object => |obj| {
            try status.result.append(allocator, '{');
            status.indent += 1;

            var iter = obj.iterator();
            var keys: std.ArrayListUnmanaged([]const u8) = .empty;
            defer {
                for (keys.items) |k| {
                    allocator.free(k);
                }
                keys.deinit(allocator);
            }

            while (iter.next()) |entry| {
                const key_copy = try allocator.dupe(u8, entry.key_ptr.*);
                try keys.append(allocator, key_copy);
            }

            for (keys.items, 0..) |key, i| {
                try status.result.append(allocator, '\n');
                indent(status);
                const key_part = try std.fmt.allocPrint(allocator, "{s}: ", .{key});
                defer allocator.free(key_part);
                try status.result.appendSlice(allocator, key_part);
                try printValue(allocator, obj.get(key).?, status);
                if (i < keys.items.len - 1) {
                    try status.result.append(allocator, ',');
                }
            }

            status.indent -= 1;
            try status.result.append(allocator, '\n');
            indent(status);
            try status.result.append(allocator, '}');
        },
        .string => |s| {
            if (status.ansi) {
                const formatted = try std.fmt.allocPrint(allocator, "\x1b[32m\"{s}\"\x1b[0m", .{s});
                defer allocator.free(formatted);
                try status.result.appendSlice(allocator, formatted);
            } else {
                const formatted = try std.fmt.allocPrint(allocator, "\"{s}\"", .{s});
                defer allocator.free(formatted);
                try status.result.appendSlice(allocator, formatted);
            }
        },
        .int => |n| {
            if (status.ansi) {
                const formatted = try std.fmt.allocPrint(allocator, "\x1b[33m{d}\x1b[0m", .{n});
                defer allocator.free(formatted);
                try status.result.appendSlice(allocator, formatted);
            } else {
                const formatted = try std.fmt.allocPrint(allocator, "{d}", .{n});
                defer allocator.free(formatted);
                try status.result.appendSlice(allocator, formatted);
            }
        },
        .num => |n| {
            if (status.ansi) {
                const formatted = try std.fmt.allocPrint(allocator, "\x1b[33m{d}\x1b[0m", .{n});
                defer allocator.free(formatted);
                try status.result.appendSlice(allocator, formatted);
            } else {
                const formatted = try std.fmt.allocPrint(allocator, "{d}", .{n});
                defer allocator.free(formatted);
                try status.result.appendSlice(allocator, formatted);
            }
        },
        .bool => |b| {
            if (status.ansi) {
                const formatted = try std.fmt.allocPrint(allocator, "\x1b[34m{any}\x1b[0m", .{b});
                defer allocator.free(formatted);
                try status.result.appendSlice(allocator, formatted);
            } else {
                const formatted = try std.fmt.allocPrint(allocator, "{any}", .{b});
                defer allocator.free(formatted);
                try status.result.appendSlice(allocator, formatted);
            }
        },
        .null => {
            try status.result.appendSlice(allocator, "null");
        },
    }
}

fn indent(status: *Status) void {
    for (0..status.indent) |_| {
        status.result.appendSlice(status.allocator, status.indentText) catch unreachable;
    }
}
