const std = @import("std");
const sdn = @import("sdn");
const parse = sdn.parse;
const parseSchema = sdn.parseSchema;
const check = sdn.check;

test "check: valid simple object" {
    const allocator = std.testing.allocator;

    const schema_input =
        \\{
        \\  name: string,
        \\  age: int,
        \\  active: bool,
        \\}
    ;

    const data_input =
        \\{
        \\  name: "John",
        \\  age: 30,
        \\  active: true,
        \\}
    ;

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .ok);
}

test "check: invalid type mismatch" {
    const allocator = std.testing.allocator;

    const schema_input =
        \\{
        \\  name: string,
        \\  age: int,
        \\  active: bool,
        \\}
    ;

    const data_input =
        \\{
        \\  name: "John",
        \\  age: "30",
        \\  active: true,
        \\}
    ;

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .err_list);
    try std.testing.expect(result.err_list.items.len > 0);
}

test "check: with validators" {
    const allocator = std.testing.allocator;

    const schema_input =
        \\{
        \\  name: string minlen(2) maxlen(20),
        \\  age: int min(0) max(150),
        \\}
    ;

    const data_input =
        \\{
        \\  name: "Alice",
        \\  age: 25,
        \\}
    ;

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .ok);
}

test "check: validator failure" {
    const allocator = std.testing.allocator;

    const schema_input =
        \\{
        \\  name: string minlen(5),
        \\  age: int max(20),
        \\}
    ;

    const data_input =
        \\{
        \\  name: "Bob",
        \\  age: 25,
        \\}
    ;

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .err_list);
    try std.testing.expect(result.err_list.items.len > 0);
}

test "check: null type valid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ meeting_at: null | date }";
    const data_input = "{ meeting_at: null }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .ok);
}

test "check: bool type valid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ is_active: bool }";
    const data_input = "{ is_active: true }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .ok);
}

test "check: bool type invalid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ is_active: bool }";
    const data_input = "{ is_active: 1 }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .err_list);
    try std.testing.expect(result.err_list.items.len == 1);
    try std.testing.expect(std.mem.eql(u8, result.err_list.items[0].message, "'is_active' must be a boolean value"));
}

test "check: int type valid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ age: int }";
    const data_input = "{ age: 25 }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .ok);
}

test "check: int type invalid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ age: int }";
    const data_input = "{ age: 25.5 }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .err_list);
    try std.testing.expect(result.err_list.items.len == 1);
    try std.testing.expect(std.mem.eql(u8, result.err_list.items[0].message, "'age' must be an integer value"));
}

test "check: num type valid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ rating: num }";
    const data_input = "{ rating: 4.5 }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .ok);
}

test "check: num type invalid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ rating: num }";
    const data_input = "{ rating: \"excellent\" }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .err_list);
    try std.testing.expect(result.err_list.items.len == 1);
    try std.testing.expect(std.mem.eql(u8, result.err_list.items[0].message, "'rating' must be a number value"));
}

test "check: date type valid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ birthday: date }";
    const data_input = "{ birthday: 2025-01-15 }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .ok);
}

test "check: date type invalid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ birthday: date }";
    const data_input = "{ birthday: \"2025-01-15\" }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .err_list);
    try std.testing.expect(result.err_list.items.len == 1);
    try std.testing.expect(std.mem.eql(u8, result.err_list.items[0].message, "'birthday' must be a date value"));
}

test "check: string type valid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ name: string }";
    const data_input = "{ name: \"Alice\" }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .ok);
}

test "check: string type invalid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ name: string }";
    const data_input = "{ name: 123 }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .err_list);
    try std.testing.expect(result.err_list.items.len == 1);
    try std.testing.expect(std.mem.eql(u8, result.err_list.items[0].message, "'name' must be a string value"));
}

test "check: int union" {
    const allocator = std.testing.allocator;

    const schema_input = "{ age: 15 | 16 | 17 }";
    const data_input = "{ age: 22 }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .err_list);
    try std.testing.expect(result.err_list.items.len == 1);
    try std.testing.expect(std.mem.eql(u8, result.err_list.items[0].message, "'age' must be '15' | 'age' must be '16' | 'age' must be '17'"));
}

test "check: int min validator valid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ age: int min(18) }";
    const data_input = "{ age: 20 }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .ok);
}

test "check: int min validator invalid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ age: int min(18) }";
    const data_input = "{ age: 15 }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .err_list);
    try std.testing.expect(result.err_list.items.len == 1);
    try std.testing.expect(std.mem.eql(u8, result.err_list.items[0].message, "'age' must be at least 18"));
}

test "check: int max validator valid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ age: int max(100) }";
    const data_input = "{ age: 50 }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .ok);
}

test "check: int max validator invalid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ age: int max(100) }";
    const data_input = "{ age: 120 }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .err_list);
    try std.testing.expect(result.err_list.items.len == 1);
    try std.testing.expect(std.mem.eql(u8, result.err_list.items[0].message, "'age' cannot be more than 100"));
}

test "check: num min validator valid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ rating: num min(0) }";
    const data_input = "{ rating: 4.5 }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .ok);
}

test "check: num min validator invalid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ rating: num min(0) }";
    const data_input = "{ rating: -0.5 }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .err_list);
    try std.testing.expect(result.err_list.items.len == 1);
    try std.testing.expect(std.mem.eql(u8, result.err_list.items[0].message, "'rating' must be at least 0"));
}

test "check: num max validator valid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ rating: num max(5) }";
    const data_input = "{ rating: 4.5 }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .ok);
}

test "check: num max validator invalid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ rating: num max(5) }";
    const data_input = "{ rating: 5.5 }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .err_list);
    try std.testing.expect(result.err_list.items.len == 1);
    try std.testing.expect(std.mem.eql(u8, result.err_list.items[0].message, "'rating' cannot be more than 5"));
}

test "check: field not found" {
    const allocator = std.testing.allocator;

    const schema_input = "{ name: string, age: int }";
    const data_input = "{ name: \"Alice\" }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .err_list);
    try std.testing.expect(result.err_list.items.len == 1);
    try std.testing.expect(std.mem.eql(u8, result.err_list.items[0].message, "Field not found: age"));
}

test "check: multiple fields valid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ name: string, age: int, is_active: bool }";
    const data_input = "{ name: \"Alice\", age: 25, is_active: true }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .ok);
}

test "check: multiple fields invalid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ name: string, age: int, is_active: bool }";
    const data_input = "{ name: \"Alice\", age: 25.5, is_active: \"yes\" }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .err_list);
    try std.testing.expect(result.err_list.items.len == 2);
}

test "check: array valid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ fruits: [string] }";
    const data_input = "{ fruits: [\"apple\", \"banana\"] }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .ok);
}

test "check: array invalid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ fruits: [string] }";
    const data_input = "{ fruits: [\"apple\", 5] }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .err_list);
    try std.testing.expect(result.err_list.items.len == 1);
    try std.testing.expect(std.mem.eql(u8, result.err_list.items[0].message, "'1' must be a string value"));
}

test "check: nested object valid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ child: { is_active: bool } }";
    const data_input = "{ child: { is_active: true } }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .ok);
}

test "check: nested object invalid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ child: { is_active: bool } }";
    const data_input = "{ child: { is_active: 1 } }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .err_list);
    try std.testing.expect(result.err_list.items.len == 1);
    try std.testing.expect(std.mem.eql(u8, result.err_list.items[0].message, "'is_active' must be a boolean value"));
}

test "check: nested array valid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ points: [[ int ]] }";
    const data_input = "{ points: [[0, 1], [1, 2]] }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .ok);
}

test "check: nested array invalid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ points: [[ int ]] }";
    const data_input = "{ points: [[0, 1], [\"one\", \"two\"]] }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .err_list);
    try std.testing.expect(result.err_list.items.len == 2);
    try std.testing.expect(std.mem.eql(u8, result.err_list.items[0].message, "'0' must be an integer value"));
    try std.testing.expect(std.mem.eql(u8, result.err_list.items[1].message, "'1' must be an integer value"));
}

test "check: object in array valid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ children: [ { name: string, age: int }] }";
    const data_input = "{ children: [ { name: \"Child A\", age: 12 }] }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .ok);
}

test "check: object in array invalid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ children: [ { name: string, age: int }] }";
    const data_input = "{ children: [ { name: 12, age: 12 }] }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .err_list);
    try std.testing.expect(result.err_list.items.len == 1);
    try std.testing.expect(std.mem.eql(u8, result.err_list.items[0].message, "'name' must be a string value"));
}

test "check: union type valid first" {
    const allocator = std.testing.allocator;

    const schema_input = "{ value: string | int }";
    const data_input = "{ value: \"hello\" }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .ok);
}

test "check: union type valid second" {
    const allocator = std.testing.allocator;

    const schema_input = "{ value: string | int }";
    const data_input = "{ value: 42 }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .ok);
}

test "check: union type invalid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ value: string | int }";
    const data_input = "{ value: true }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .err_list);
    try std.testing.expect(result.err_list.items.len == 1);
    try std.testing.expect(std.mem.eql(u8, result.err_list.items[0].message, "'value' must be a string value | 'value' must be an integer value"));
}

test "check: union of three types valid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ value: string | int | bool }";
    const data_input = "{ value: false }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .ok);
}

test "check: union type in array valid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ values: [string | int] }";
    const data_input = "{ values: [\"hello\", 45] }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .ok);
}

test "check: union type in array invalid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ values: [ string | int ] }";
    const data_input = "{ values: [ true ] }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .err_list);
    try std.testing.expect(result.err_list.items.len == 1);
    try std.testing.expect(std.mem.eql(u8, result.err_list.items[0].message, "'0' must be a string value | '0' must be an integer value"));
}

test "check: string min length valid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ name: string minlen(3) }";
    const data_input = "{ name: \"Alice\" }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .ok);
}

test "check: string min length invalid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ name: string minlen(3) }";
    const data_input = "{ name: \"Al\" }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .err_list);
    try std.testing.expect(result.err_list.items.len == 1);
    try std.testing.expect(std.mem.eql(u8, result.err_list.items[0].message, "'name' must be at least 3 characters"));
}

test "check: string max length valid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ name: string maxlen(10) }";
    const data_input = "{ name: \"Alice\" }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .ok);
}

test "check: string max length invalid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ name: string maxlen(5) }";
    const data_input = "{ name: \"Alexander\" }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .err_list);
    try std.testing.expect(result.err_list.items.len == 1);
    try std.testing.expect(std.mem.eql(u8, result.err_list.items[0].message, "'name' cannot be more than 5 characters"));
}

test "check: string regex valid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ email: string pattern(/^[^@]+@[^@]+$/) }";
    const data_input = "{ email: \"user@example.com\" }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .ok);
}

test "check: string regex invalid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ email: string pattern(/^[^@]+@[^@]+$/) }";
    const data_input = "{ email: \"not-an-email\" }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .err_list);
    try std.testing.expect(result.err_list.items.len == 1);
    try std.testing.expect(std.mem.eql(u8, result.err_list.items[0].message, "'email' doesn't match pattern '/^[^@]+@[^@]+$/'"));
}

test "check: date min valid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ birthday: date min(2000-01-01) }";
    const data_input = "{ birthday: 2005-06-15 }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .ok);
}

test "check: date min invalid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ birthday: date min(2000-01-01) }";
    const data_input = "{ birthday: 1995-06-15 }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .err_list);
    try std.testing.expect(result.err_list.items.len == 1);
    try std.testing.expect(std.mem.eql(u8, result.err_list.items[0].message, "'birthday' must be at least 2000-01-01"));
}

test "check: date max valid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ birthday: date max(2025-01-01) }";
    const data_input = "{ birthday: 2020-06-15 }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .ok);
}

test "check: date max invalid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ birthday: date max(2020-01-01) }";
    const data_input = "{ birthday: 2025-06-15 }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .err_list);
    try std.testing.expect(result.err_list.items.len == 1);
    try std.testing.expect(std.mem.eql(u8, result.err_list.items[0].message, "'birthday' cannot be after 2020-01-01"));
}

test "check: @mix valid first alternative" {
    const allocator = std.testing.allocator;

    const schema_input = "{ @mix({ role: \"admin\", level: int } | { role: \"user\", plan: string }) }";
    const data_input = "{ role: \"admin\", level: 5 }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .ok);
}

test "check: @mix valid second alternative" {
    const allocator = std.testing.allocator;

    const schema_input = "{ @mix({ role: \"admin\", level: int } | { role: \"user\", plan: string }) }";
    const data_input = "{ role: \"user\", plan: \"premium\" }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .ok);
}

test "check: @mix invalid all alternatives" {
    const allocator = std.testing.allocator;

    const schema_input = "{ @mix({ role: \"admin\", level: int } | { role: \"user\", plan: string }) }";
    const data_input = "{ role: \"guest\", plan: \"free\" }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .err_list);
    try std.testing.expect(result.err_list.items.len == 1);
    try std.testing.expect(std.mem.indexOf(u8, result.err_list.items[0].message, "'role' must be 'admin'") != null);
    try std.testing.expect(std.mem.indexOf(u8, result.err_list.items[0].message, "Field not found: level") != null);
    try std.testing.expect(std.mem.indexOf(u8, result.err_list.items[0].message, "'role' must be 'user'") != null);
}

test "check: @any no pattern valid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ @any(): string }";
    const data_input = "{ greeting: \"hello\", farewell: \"goodbye\" }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .ok);
}

test "check: @any no pattern invalid type" {
    const allocator = std.testing.allocator;

    const schema_input = "{ @any(): string }";
    const data_input = "{ greeting: \"hello\", count: 5 }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .err_list);
}

test "check: @any with pattern valid" {
    const allocator = std.testing.allocator;

    const schema_input = "{ @any(/v\\d/): string }";
    const data_input = "{ v1: \"version 1\", v2: \"version 2\" }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .ok);
}

test "check: @any with pattern invalid name" {
    const allocator = std.testing.allocator;

    const schema_input = "{ @any(/v\\d/): string }";
    const data_input = "{ version1: \"version 1\", v2: \"version 2\" }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .err_list);
    try std.testing.expect(result.err_list.items.len == 1);
    try std.testing.expect(std.mem.eql(u8, result.err_list.items[0].message, "'version1' name doesn't match pattern '/v\\d/'"));
}

test "check: @any with pattern invalid type" {
    const allocator = std.testing.allocator;

    const schema_input = "{ @any(/v\\d/): int }";
    const data_input = "{ v1: \"version 1\", v2: \"version 2\" }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .err_list);
    try std.testing.expect(result.err_list.items.len == 2);
    try std.testing.expect(std.mem.eql(u8, result.err_list.items[0].message, "'v1' must be an integer value"));
    try std.testing.expect(std.mem.eql(u8, result.err_list.items[1].message, "'v2' must be an integer value"));
}

test "check: multiple validators on int" {
    const allocator = std.testing.allocator;

    const schema_input = "{ age: int min(18) max(100) }";
    const data_input = "{ age: 25 }";

    var schema_result = parseSchema(allocator, schema_input);
    defer schema_result.deinit();
    try std.testing.expect(schema_result.ok);

    var data = parse(allocator, data_input);
    defer data.deinit();
    try std.testing.expect(data.ok);

    var result = try check(allocator, &data.data.?, &schema_result.schema.?);
    defer result.deinit(allocator);

    try std.testing.expect(result == .ok);
}
