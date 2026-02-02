const std = @import("std");
const Io = std.Io;

const sdn = @import("sdn");

pub fn main(init: std.process.Init) !void {
    const arena = init.arena.allocator();
    const io = init.io;

    // Get command-line arguments
    const args = try init.minimal.args.toSlice(arena);
    if (args.len < 2) {
        printUsage(io);
        return error.MissingArgument;
    }

    const file_path = args[1];

    var schema: ?*const sdn.Schema = null;
    if (args.len >= 3) {
        const schema_path = args[2];
        const cwd = std.Io.Dir.cwd();
        const resolved_schema = try sdn.locate(io, arena, schema_path);
        defer arena.free(resolved_schema);

        const schema_contents = try cwd.readFileAlloc(io, resolved_schema, arena, .unlimited);
        defer arena.free(schema_contents);

        const schema_parsed = sdn.parseSchema(arena, schema_contents);
        if (schema_parsed.ok) {
            schema = &schema_parsed.schema.?;
        } else {
            try printSchemaErrors(io, schema_parsed);
            return error.SchemaParseError;
        }
    }

    var result = try sdn.read(io, arena, file_path, schema);
    defer result.deinit();

    if (result.ok) {
        try printSuccess(io, arena, result.data.?);
    } else {
        try printErrors(io, result);
        return error.ParseError;
    }
}

fn printUsage(io: std.Io) void {
    var buffer: [1024]u8 = undefined;
    const stderr_file = std.Io.File.stderr();
    var stderr_writer = stderr_file.writer(io, &buffer);
    const stderr = &stderr_writer.interface;
    stderr.writeAll("Usage: sdnx <file> [schema]\n") catch {};
    stderr.writeAll("  file   - Path to the SDN file to read\n") catch {};
    stderr.writeAll("  schema - Optional path to the schema file (can be specified in file with @schema directive)\n") catch {};
    stderr_writer.flush() catch {};
}

fn printSuccess(io: std.Io, allocator: std.mem.Allocator, value: *const sdn.Value) !void {
    var buffer: [8192]u8 = undefined;
    const stdout_file = std.Io.File.stdout();
    var stdout_writer = stdout_file.writer(io, &buffer);
    const stdout = &stdout_writer.interface;

    try stdout.writeAll("\nFile read with no errors.\n\n");

    var opts = sdn.StringifyOptions{ .ansi = true, .indent = "    " };
    const output = try sdn.stringify(allocator, value.*, &opts);
    defer allocator.free(output);
    try stdout.writeAll(output);
    try stdout_writer.flush();
}

fn printErrors(io: std.Io, result: sdn.ReadResult) !void {
    var buffer: [1024]u8 = undefined;
    const stderr_file = std.Io.File.stderr();
    var stderr_writer = stderr_file.writer(io, &buffer);
    const stderr = &stderr_writer.interface;

    defer stderr_writer.flush() catch {};

    if (result.schemaErrors.items.len > 0) {
        try printReadErrors(stderr, result.schemaErrors, "schema file");
    }

    if (result.dataErrors.items.len > 0) {
        try printReadErrors(stderr, result.dataErrors, "data file");
    }

    if (result.checkErrors.items.len > 0) {
        try printCheckErrors(stderr, result.checkErrors);
    }
}

fn printSchemaErrors(io: std.Io, result: sdn.SchemaParseResult) !void {
    var buffer: [1024]u8 = undefined;
    const stderr_file = std.Io.File.stderr();
    var stderr_writer = stderr_file.writer(io, &buffer);
    const stderr = &stderr_writer.interface;

    defer stderr_writer.flush() catch {};

    try stderr.print("\n{d} error{s} in schema file:\n", .{ result.errors.items.len, if (result.errors.items.len == 1) "" else "s" });

    for (result.errors.items) |err| {
        try stderr.print("{d}: {s}\n", .{ err.index, err.message });
    }
}

fn printReadErrors(stderr: *std.Io.Writer, errors: std.ArrayListUnmanaged(sdn.ReadErrorInfo), error_type: []const u8) !void {
    const error_count = errors.items.len;
    try stderr.print("\n{d} error{s} in {s}:\n", .{ error_count, if (error_count == 1) "" else "s", error_type });

    for (errors.items) |err| {
        try stderr.print("{d}: {s}\n", .{ err.index, err.message });
        try stderr.writeAll(err.line);
        try stderr.writeAll("\n");
        var i: usize = 0;
        while (i < err.char) : (i += 1) {
            try stderr.writeByte(' ');
        }
        i = 0;
        while (i < err.length) : (i += 1) {
            try stderr.writeByte('~');
        }
        try stderr.writeAll("\n");
    }
}

fn printCheckErrors(stderr: *std.Io.Writer, errors: std.ArrayListUnmanaged(sdn.ValidationError)) !void {
    const error_count = errors.items.len;
    try stderr.print("\n{d} error{s} in data:\n", .{ error_count, if (error_count == 1) "" else "s" });

    for (errors.items) |err| {
        var path_str: []const u8 = "";
        if (err.path.items.len > 0) {
            var path_parts = std.ArrayListUnmanaged([]const u8){};
            defer path_parts.deinit(err.allocator);
            for (err.path.items) |item| {
                try path_parts.append(err.allocator, item);
            }
            const joined = try std.mem.join(err.allocator, ".", path_parts.items);
            defer err.allocator.free(joined);
            path_str = joined;
        }
        try stderr.print("{s}: {s}\n", .{ path_str, err.message });
    }
}
