const std = @import("std");
const Allocator = std.mem.Allocator;
const path = std.fs.path;
const fs = std.fs;

const parse = @import("./parse.zig");
const parse_mod = parse;
const parseSchema = @import("./parseSchema.zig");
const check = @import("./check.zig");

const Value = @import("./types/Value.zig").Value;
const Schema = @import("./types/Schema.zig").Schema;
const SchemaValue = @import("./types/SchemaValue.zig").SchemaValue;

pub const ReadError = error{
    FileNotFound,
    SchemaRequired,
} || std.mem.Allocator.Error || anyerror;

/// Read error information with position details
pub const ReadErrorInfo = struct {
    message: []const u8,
    index: usize,
    length: usize,
    line: []const u8,
    char: usize,

    pub fn deinit(self: *ReadErrorInfo, allocator: Allocator) void {
        allocator.free(self.message);
        allocator.free(self.line);
    }
};

/// Result type for read operations
pub const ReadResult = struct {
    ok: bool,
    data: ?*Value,
    contents: ?[]const u8,
    schemaErrors: std.ArrayListUnmanaged(ReadErrorInfo),
    dataErrors: std.ArrayListUnmanaged(ReadErrorInfo),
    checkErrors: std.ArrayListUnmanaged(check.ValidationError),
    allocator: Allocator,

    pub fn deinit(self: *ReadResult) void {
        for (self.schemaErrors.items) |*err| {
            err.deinit(self.allocator);
        }
        self.schemaErrors.deinit(self.allocator);
        for (self.dataErrors.items) |*err| {
            err.deinit(self.allocator);
        }
        self.dataErrors.deinit(self.allocator);
        for (self.checkErrors.items) |*err| {
            err.deinit();
        }
        self.checkErrors.deinit(self.allocator);
        if (self.data) |d| {
            d.deinit(self.allocator);
            self.allocator.destroy(d);
        }
        if (self.contents) |c| {
            self.allocator.free(c);
        }
    }
};

/// Read and parse a file, validate it against a schema
pub fn read(io: std.Io, allocator: Allocator, file_path: []const u8, schema_in: ?*const Schema) ReadError!ReadResult {
    const cwd = std.Io.Dir.cwd();

    const resolved_path = try locate(io, allocator, file_path);
    defer allocator.free(resolved_path);

    const contents = try cwd.readFileAlloc(io, resolved_path, allocator, .unlimited);

    // Check for @schema directive and extract schema path if present
    var schema_path_from_directive: ?[]const u8 = null;
    defer if (schema_path_from_directive) |p| allocator.free(p);

    const data_contents = blk: {
        // Look for @schema directive at the beginning (possibly with leading whitespace)
        var start_idx: usize = 0;
        while (start_idx < contents.len and std.ascii.isWhitespace(contents[start_idx])) {
            start_idx += 1;
        }
        const trimmed = contents[start_idx..];

        if (std.mem.startsWith(u8, trimmed, "@schema(\"")) {
            // Find the end of the directive
            const start_len = "@schema(\"".len;
            if (std.mem.indexOfScalar(u8, trimmed[start_len..], '\"')) |end_idx| {
                const schema_path = trimmed[start_len .. start_len + end_idx];
                schema_path_from_directive = try allocator.dupe(u8, schema_path);

                // Find the end of the directive line (including the closing paren)
                const after_directive = trimmed[start_len + end_idx + 2 ..]; // +2 for ")
                // Skip to the next line
                if (std.mem.indexOfScalar(u8, after_directive, '\n')) |newline_idx| {
                    break :blk after_directive[newline_idx + 1 ..];
                } else {
                    break :blk "";
                }
            }
        }
        break :blk contents;
    };

    var parsed = parse.parse(allocator, data_contents);
    defer parsed.deinit();

    var result = ReadResult{
        .ok = false,
        .data = null,
        .contents = null,
        .schemaErrors = .empty,
        .dataErrors = .empty,
        .checkErrors = .empty,
        .allocator = allocator,
    };

    if (!parsed.ok) {
        for (parsed.errors.items) |err| {
            const read_err = try buildReadError(allocator, err, data_contents);
            try result.dataErrors.append(allocator, read_err);
        }
        allocator.free(contents);
        return result;
    }

    var final_schema: ?*const Schema = schema_in;

    if (final_schema == null) {
        if (schema_path_from_directive) |m| {
            const schema_path = try path.resolve(allocator, &.{ path.dirname(resolved_path) orelse ".", m });
            defer allocator.free(schema_path);

            const resolved_schema = try locate(io, allocator, schema_path);
            defer allocator.free(resolved_schema);

            const schema_contents = try cwd.readFileAlloc(io, resolved_schema, allocator, .unlimited);
            defer allocator.free(schema_contents);

            const schema_parsed = parseSchema.parseSchema(allocator, schema_contents);

            if (schema_parsed.ok) {
                final_schema = &schema_parsed.schema.?;
            } else {
                defer @constCast(&schema_parsed).deinit();
                for (schema_parsed.errors.items) |err| {
                    const read_err = try buildReadError(allocator, err, schema_contents);
                    try result.schemaErrors.append(allocator, read_err);
                }
                result.contents = contents;
                return result;
            }
        } else {
            return error.SchemaRequired;
        }
    }

    var checked = try check.check(allocator, &parsed.data.?, final_schema.?);
    defer checked.deinit(allocator);

    if (checked == .ok) {
        result.ok = true;
        result.contents = contents;
        const data_ptr = try allocator.create(Value);
        data_ptr.* = parsed.data.?;
        parsed.data = null;
        result.data = data_ptr;

        // Deinit the schema if it was parsed within this function (not from caller)
        if (schema_in == null and schema_path_from_directive != null) {
            const schema_ptr = @constCast(final_schema.?);
            parseSchema.deinitSchema(schema_ptr, allocator);
        }

        return result;
    } else {
        // Deinit schema if it was parsed within this function (not from caller)
        if (schema_in == null and schema_path_from_directive != null) {
            const schema_ptr = @constCast(final_schema.?);
            parseSchema.deinitSchema(schema_ptr, allocator);
        }

        for (checked.err_list.items) |*err| {
            var new_err = check.ValidationError.init(allocator);
            new_err.message = try allocator.dupe(u8, err.message);
            try result.checkErrors.append(allocator, new_err);
        }
        allocator.free(contents);
        return result;
    }
}

/// Locate a file, checking if it exists relative to current directory or cwd
pub fn locate(io: std.Io, allocator: Allocator, file_path: []const u8) ![]const u8 {
    const cwd = std.Io.Dir.cwd();
    if (cwd.openFile(io, file_path, .{})) |_| {
        return allocator.dupe(u8, file_path);
    } else |_| {
        const cwd_path = try cwd.realPathFileAlloc(io, ".", allocator);
        defer allocator.free(cwd_path);
        const resolved = try path.resolve(allocator, &.{ cwd_path, file_path });
        defer allocator.free(resolved);
        if (cwd.openFile(io, resolved, .{})) |_| {
            return allocator.dupe(u8, resolved);
        } else |_| {
            return error.FileNotFound;
        }
    }
}

/// Find @schema("...") directive in file contents
fn findSchemaDirective(contents: []const u8) !?[]const u8 {
    const pattern = "@schema(\"";
    const start = std.mem.indexOf(u8, contents, pattern) orelse return null;
    const pattern_end = contents[start + pattern.len ..];
    const end = std.mem.indexOfScalar(u8, pattern_end, '\"') orelse return null;
    return pattern_end[0..end];
}

/// Build a ReadErrorInfo from a ParseErrorInfo or SchemaParseErrorInfo
fn buildReadError(allocator: Allocator, parse_err: anytype, contents: []const u8) !ReadErrorInfo {
    var line_index = parse_err.index;
    while (line_index > 0 and contents[line_index - 1] != '\n') {
        line_index -= 1;
    }

    var line_end_index = parse_err.index;
    while (line_end_index < contents.len and contents[line_end_index] != '\n') {
        line_end_index += 1;
    }

    const line = try allocator.dupe(u8, contents[line_index..line_end_index]);
    const message = try allocator.dupe(u8, parse_err.message);

    return ReadErrorInfo{
        .message = message,
        .index = parse_err.index,
        .length = parse_err.length,
        .line = line,
        .char = parse_err.index - line_index,
    };
}
