const std = @import("std");
const Allocator = std.mem.Allocator;

const sdn = @import("sdn");
const read_mod = sdn.read_mod;
const read = sdn.read;
const parse = sdn.parse;
const parseSchema = sdn.parseSchema;
const ParseResult = parse.ParseResult;
const SchemaParseResult = parseSchema.SchemaParseResult;
const Schema = sdn.parseSchema_mod.Schema;

const test_io = std.testing.io;
const test_allocator = std.testing.allocator;

var tmp_dir: std.Io.Dir = undefined;
var tmp_dir_path: []const u8 = undefined;

const cwd = std.Io.Dir.cwd();

fn setupTmpDir(_: Allocator) !void {
    tmp_dir = try cwd.createDirPathOpen(std.testing.io, "zig-test-tmp", .{});
    tmp_dir_path = "zig-test-tmp";
}

fn cleanupTmpDir(_: Allocator) void {
    if (tmp_dir_path.len > 0) {
        tmp_dir.deleteTree(std.testing.io, tmp_dir_path) catch {};
        tmp_dir.close(std.testing.io);
        cwd.deleteTree(std.testing.io, tmp_dir_path) catch {};
        tmp_dir_path = "";
    }
}

fn writeFile(rel_path: []const u8, content: []const u8) !void {
    // Use tmp_dir (the test temp directory) instead of cwd
    // Try to write directly first
    tmp_dir.writeFile(std.testing.io, .{ .sub_path = rel_path, .data = content }) catch |err| {
        if (err == error.FileNotFound) {
            // Directory doesn't exist, create it
            const dir_path = std.fs.path.dirname(rel_path) orelse ".";
            try tmp_dir.createDirPath(std.testing.io, dir_path);
            // Now try writing again
            try tmp_dir.writeFile(std.testing.io, .{ .sub_path = rel_path, .data = content });
            return;
        }
        return err;
    };
}

test "read: successful with @schema directive" {
    try setupTmpDir(test_allocator);
    defer cleanupTmpDir(test_allocator);

    const schema_content = "{ name: string, age: int }";
    const data_content =
        \\@schema("./schema.sdnx")
        \\{ name: "Alice", age: 30 }
    ;

    try writeFile("schema.sdnx", schema_content);
    try writeFile("data.sdn", data_content);

    const data_path = try std.fs.path.join(test_allocator, &.{ tmp_dir_path, "data.sdn" });
    defer test_allocator.free(data_path);

    var result = try read_mod.read(test_io, test_allocator, data_path, null);
    defer result.deinit();

    try std.testing.expect(result.ok);
    try std.testing.expect(result.data != null);
    if (result.data) |d| {
        try std.testing.expect(d.object.get("name") != null);
        try std.testing.expect(d.object.get("age") != null);
        try std.testing.expectEqual(@as(i64, 30), d.object.get("age").?.int);
    }
}

test "read: successful with explicit schema path" {
    try setupTmpDir(test_allocator);
    defer cleanupTmpDir(test_allocator);

    const schema_content = "{ name: string, age: int }";
    const data_content = "{ name: \"Bob\", age: 25 }";

    try writeFile("schema.sdnx", schema_content);
    try writeFile("data.sdn", data_content);

    const schema_path = try std.fs.path.join(test_allocator, &.{ tmp_dir_path, "schema.sdnx" });
    defer test_allocator.free(schema_path);
    const data_path = try std.fs.path.join(test_allocator, &.{ tmp_dir_path, "data.sdn" });
    defer test_allocator.free(data_path);

    // For this test, we'll parse the schema first
    const schema_contents = try std.Io.Dir.cwd().readFileAlloc(test_io, schema_path, test_allocator, .unlimited);
    defer test_allocator.free(schema_contents);
    var schema_parsed = parseSchema(test_allocator, schema_contents);
    defer schema_parsed.deinit();

    var result = try read_mod.read(test_io, test_allocator, data_path, &schema_parsed.schema.?);
    defer result.deinit();

    try std.testing.expect(result.ok);
    try std.testing.expect(result.data != null);
}

test "read: successful with Schema object" {
    try setupTmpDir(test_allocator);
    defer cleanupTmpDir(test_allocator);

    const schema_content = "{ name: string, age: int }";
    var schema_parsed = parseSchema(test_allocator, schema_content);
    defer schema_parsed.deinit();

    const data_content = "{ name: \"Charlie\", age: 35 }";
    try writeFile("data.sdn", data_content);

    const data_path = try std.fs.path.join(test_allocator, &.{ tmp_dir_path, "data.sdn" });
    defer test_allocator.free(data_path);

    var result = try read_mod.read(test_io, test_allocator, data_path, &schema_parsed.schema.?);
    defer result.deinit();

    try std.testing.expect(result.ok);
    try std.testing.expect(result.data != null);
}

test "read: fails with data parse errors" {
    try setupTmpDir(test_allocator);
    defer cleanupTmpDir(test_allocator);

    const schema_content = "{ name: string, age: int }";
    const data_content =
        \\@schema("./schema.sdnx")
        \\{ name: "Alice", age: }
    ;

    try writeFile("schema.sdnx", schema_content);
    try writeFile("data.sdn", data_content);

    const data_path = try std.fs.path.join(test_allocator, &.{ tmp_dir_path, "data.sdn" });
    defer test_allocator.free(data_path);

    var result = try read_mod.read(test_io, test_allocator, data_path, null);
    defer result.deinit();

    try std.testing.expect(!result.ok);
    try std.testing.expect(result.schemaErrors.items.len == 0);
    try std.testing.expect(result.dataErrors.items.len > 0);
    try std.testing.expect(result.checkErrors.items.len == 0);
}

test "read: fails with schema parse errors" {
    try setupTmpDir(test_allocator);
    defer cleanupTmpDir(test_allocator);

    const schema_content = "{ name: string, age: }";
    const data_content =
        \\@schema("./schema.sdnx")
        \\{ name: "Alice", age: 30 }
    ;

    try writeFile("schema.sdnx", schema_content);
    try writeFile("data.sdn", data_content);

    const data_path = try std.fs.path.join(test_allocator, &.{ tmp_dir_path, "data.sdn" });
    defer test_allocator.free(data_path);

    var result = try read_mod.read(test_io, test_allocator, data_path, null);
    defer result.deinit();

    try std.testing.expect(!result.ok);
    try std.testing.expect(result.schemaErrors.items.len > 0);
    try std.testing.expect(result.dataErrors.items.len == 0);
    try std.testing.expect(result.checkErrors.items.len == 0);
}

test "read: fails with validation errors" {
    try setupTmpDir(test_allocator);
    defer cleanupTmpDir(test_allocator);

    const schema_content = "{ name: string, age: int min(18) }";
    const data_content =
        \\@schema("./schema.sdnx")
        \\{ name: "Alice", age: 15 }
    ;

    try writeFile("schema.sdnx", schema_content);
    try writeFile("data.sdn", data_content);

    const data_path = try std.fs.path.join(test_allocator, &.{ tmp_dir_path, "data.sdn" });
    defer test_allocator.free(data_path);

    var result = try read_mod.read(test_io, test_allocator, data_path, null);
    defer result.deinit();

    try std.testing.expect(!result.ok);
    try std.testing.expect(result.schemaErrors.items.len == 0);
    try std.testing.expect(result.dataErrors.items.len == 0);
    try std.testing.expect(result.checkErrors.items.len > 0);
}

test "read: throws error when file not found" {
    const result_not_found = read_mod.read(test_io, test_allocator, "/nonexistent/path/to/file.sdn", null);
    try std.testing.expectError(error.FileNotFound, result_not_found);
}

test "read: resolves relative schema path correctly" {
    try setupTmpDir(test_allocator);
    defer cleanupTmpDir(test_allocator);

    const schema_content = "{ name: string }";
    const data_content =
        \\@schema("./schema.sdnx")
        \\{ name: "Alice" }
    ;

    try writeFile("schema.sdnx", schema_content);
    try writeFile("data.sdn", data_content);

    const data_path = try std.fs.path.join(test_allocator, &.{ tmp_dir_path, "data.sdn" });
    defer test_allocator.free(data_path);

    var result = try read_mod.read(test_io, test_allocator, data_path, null);
    defer result.deinit();

    try std.testing.expect(result.ok);
    try std.testing.expect(result.data != null);
}

test "read: handles nested schema path" {
    try setupTmpDir(test_allocator);
    defer cleanupTmpDir(test_allocator);

    const schema_content = "{ name: string }";
    const data_content =
        \\@schema("./schemas/schema.sdnx")
        \\{ name: "Alice" }
    ;

    try writeFile("schemas/schema.sdnx", schema_content);
    try writeFile("data.sdn", data_content);

    const data_path = try std.fs.path.join(test_allocator, &.{ tmp_dir_path, "data.sdn" });
    defer test_allocator.free(data_path);

    var result = try read_mod.read(test_io, test_allocator, data_path, null);
    defer result.deinit();

    try std.testing.expect(result.ok);
    try std.testing.expect(result.data != null);
}

test "read: handles complex nested data" {
    try setupTmpDir(test_allocator);
    defer cleanupTmpDir(test_allocator);

    const schema_content =
        \\{
        \\name: string,
        \\age: int,
        \\address: { street: string, city: string },
        \\tags: [string]
        \\}
    ;
    const data_content =
        \\@schema("./schema.sdnx")
        \\{
        \\name: "Alice",
        \\age: 30,
        \\address: { street: "123 Main St", city: "NYC" },
        \\tags: ["developer", "engineer"]
        \\}
    ;

    try writeFile("schema.sdnx", schema_content);
    try writeFile("data.sdn", data_content);

    const data_path = try std.fs.path.join(test_allocator, &.{ tmp_dir_path, "data.sdn" });
    defer test_allocator.free(data_path);

    var result = try read_mod.read(test_io, test_allocator, data_path, null);
    defer result.deinit();

    try std.testing.expect(result.ok);
    try std.testing.expect(result.data != null);
}

test "read: includes line and char info in parse errors" {
    try setupTmpDir(test_allocator);
    defer cleanupTmpDir(test_allocator);

    const schema_content = "{ name: string }";
    const data_content =
        \\@schema("./schema.sdnx")
        \\{ name: "Alice",
        \\age: invalid
        \\}
    ;

    try writeFile("schema.sdnx", schema_content);
    try writeFile("data.sdn", data_content);

    const data_path = try std.fs.path.join(test_allocator, &.{ tmp_dir_path, "data.sdn" });
    defer test_allocator.free(data_path);

    var result = try read_mod.read(test_io, test_allocator, data_path, null);
    defer result.deinit();

    try std.testing.expect(!result.ok);
    try std.testing.expect(result.dataErrors.items.len > 0);
    const err = result.dataErrors.items[0];
    try std.testing.expect(err.line.len > 0);
    try std.testing.expect(err.message.len > 0);
    try std.testing.expect(err.index > 0);
}

test "read: handles empty data file" {
    try setupTmpDir(test_allocator);
    defer cleanupTmpDir(test_allocator);

    const schema_content = "{ name: string }";
    const data_content =
        \\@schema("./schema.sdnx")
        \\{}
    ;

    try writeFile("schema.sdnx", schema_content);
    try writeFile("data.sdn", data_content);

    const data_path = try std.fs.path.join(test_allocator, &.{ tmp_dir_path, "data.sdn" });
    defer test_allocator.free(data_path);

    var result = try read_mod.read(test_io, test_allocator, data_path, null);
    defer result.deinit();

    try std.testing.expect(!result.ok);
    try std.testing.expect(result.checkErrors.items.len > 0);
}

test "read: handles schema with union types" {
    try setupTmpDir(test_allocator);
    defer cleanupTmpDir(test_allocator);

    const schema_content = "{ value: int | string }";
    const data_content =
        \\@schema("./schema.sdnx")
        \\{ value: 42 }
    ;

    try writeFile("schema.sdnx", schema_content);
    try writeFile("data.sdn", data_content);

    const data_path = try std.fs.path.join(test_allocator, &.{ tmp_dir_path, "data.sdn" });
    defer test_allocator.free(data_path);

    var result = try read_mod.read(test_io, test_allocator, data_path, null);
    defer result.deinit();

    try std.testing.expect(result.ok);
    try std.testing.expect(result.data != null);
}

test "read: handles schema with array of objects" {
    try setupTmpDir(test_allocator);
    defer cleanupTmpDir(test_allocator);

    const schema_content = "{ users: [{ name: string, age: int }] }";
    const data_content =
        \\@schema("./schema.sdnx")
        \\{
        \\users: [
        \\{ name: "Alice", age: 30 },
        \\{ name: "Bob", age: 25 }
        \\]
        \\}
    ;

    try writeFile("schema.sdnx", schema_content);
    try writeFile("data.sdn", data_content);

    const data_path = try std.fs.path.join(test_allocator, &.{ tmp_dir_path, "data.sdn" });
    defer test_allocator.free(data_path);

    var result = try read_mod.read(test_io, test_allocator, data_path, null);
    defer result.deinit();

    try std.testing.expect(result.ok);
    try std.testing.expect(result.data != null);
}
