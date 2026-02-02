const std = @import("std");
const sdn = @import("sdn");
const parseSchema = sdn.parseSchema;

test "schema syntax errors: no opening brace at top level" {
    const input = "age: int";
    var result = parseSchema(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "schema syntax errors: no closing brace at top level" {
    const input = "{ age: int ";
    var result = parseSchema(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "schema syntax errors: no closing array brace" {
    const input = "{ foods: [string }";
    var result = parseSchema(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "schema syntax errors: no field value" {
    const input = "{ foods, things: boolean }";
    var result = parseSchema(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "schema syntax errors: unsupported value type" {
    const input = "{ foods: things }";
    var result = parseSchema(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "schema syntax errors: empty input" {
    const input = "";
    var result = parseSchema(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "schema syntax errors: just whitespace" {
    const input = "   \n\t  ";
    var result = parseSchema(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "schema syntax errors: field name starts with number" {
    const input = "{ 1field: string }";
    var result = parseSchema(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "schema syntax errors: field name with special chars" {
    const input = "{ field-name: string }";
    var result = parseSchema(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "schema syntax errors: unclosed string" {
    const input = "{ name: \"Alice }";
    var result = parseSchema(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "schema syntax errors: invalid escape sequence" {
    const input = "{ quote: \"Hel\\lo\" }";
    var result = parseSchema(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "schema syntax errors: number with decimal but no digits" {
    const input = "{ value: 123. }";
    var result = parseSchema(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "schema syntax errors: hex number with invalid chars" {
    const input = "{ color: 0xGHIJKL }";
    var result = parseSchema(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "schema syntax errors: invalid date format" {
    const input = "{ dob: 2025-13-01 }";
    var result = parseSchema(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "schema syntax errors: boolean with wrong case" {
    const input = "{ active: True }";
    var result = parseSchema(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "schema syntax errors: negative without digits" {
    const input = "{ value: - }";
    var result = parseSchema(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "schema syntax errors: scientific notation missing exponent" {
    const input = "{ value: 1.5e }";
    var result = parseSchema(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "schema syntax errors: multiple colons in field" {
    const input = "{ name:: string }";
    var result = parseSchema(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "schema syntax errors: array with trailing comma not followed by item" {
    const input = "{ items: [\"a\",] }";
    var result = parseSchema(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "schema syntax errors: nested object not closed" {
    const input = "{ data: { nested: string }";
    var result = parseSchema(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "schema syntax errors: nested array not closed" {
    const input = "{ matrix: [[int] }";
    var result = parseSchema(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "schema syntax errors: object with missing colon after field name" {
    const input = "{ name string }";
    var result = parseSchema(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "schema syntax errors: array with just opening brace" {
    const input = "{ items: [ }";
    var result = parseSchema(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "schema syntax errors: array with missing opening brace" {
    const input = "{ items: int] }";
    var result = parseSchema(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "schema syntax errors: field name with starting underscore" {
    const input = "{ _private: string }";
    var result = parseSchema(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(result.ok);
}

test "schema syntax errors: field name in quotes" {
    const input = "{ \"private-field\": string }";
    var result = parseSchema(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(result.ok);
}

test "schema syntax errors: multiple commas in object" {
    const input = "{ name: string,, age: int }";
    var result = parseSchema(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "schema syntax errors: comma at start of object" {
    const input = "{ , name: string }";
    var result = parseSchema(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "schema syntax errors: invalid time format" {
    const input = "{ time: 25:00 }";
    var result = parseSchema(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "schema syntax errors: invalid datetime format" {
    const input = "{ created: 2025-01-15T14:90+02:00 }";
    var result = parseSchema(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "schema syntax errors: string with unescaped quote" {
    const input = "{ text: \"Hello \"World\"\" }";
    var result = parseSchema(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "schema syntax errors: unknown validator" {
    const input = "{ text: string required }";
    var result = parseSchema(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}
