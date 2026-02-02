const std = @import("std");
const sdn = @import("sdn");
const parse = sdn.parse;

test "syntax errors: no opening brace at top level" {
    const input = "age: 5";
    var result = parse(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "syntax errors: no closing brace at top level" {
    const input = "{ age: 5";
    var result = parse(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "syntax errors: no closing array brace" {
    const input = "{ foods: [\"ice cream\", \"strudel\" }";
    var result = parse(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "syntax errors: no field value" {
    const input = "{ foods, things: true }";
    var result = parse(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "syntax errors: unsupported value type" {
    const input = "{ foods: things }";
    var result = parse(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "syntax errors: empty input" {
    const input = "";
    var result = parse(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "syntax errors: just whitespace" {
    const input = "   \n\t  ";
    var result = parse(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "syntax errors: field name starts with number" {
    const input = "{ 1field: \"value\" }";
    var result = parse(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "syntax errors: field name with special chars" {
    const input = "{ field-name: \"value\" }";
    var result = parse(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "syntax errors: unclosed string" {
    const input = "{ name: \"Alice }";
    var result = parse(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "syntax errors: invalid escape sequence" {
    const input = "{ quote: \"Hel\\lo\" }";
    var result = parse(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "syntax errors: number with decimal but no digits" {
    const input = "{ value: 123. }";
    var result = parse(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "syntax errors: hex number with invalid chars" {
    const input = "{ color: 0xGHIJKL }";
    var result = parse(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "syntax errors: invalid date format" {
    const input = "{ dob: 2025-13-01 }";
    var result = parse(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "syntax errors: boolean with wrong case" {
    const input = "{ active: True }";
    var result = parse(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "syntax errors: negative without digits" {
    const input = "{ value: - }";
    var result = parse(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "syntax errors: scientific notation missing exponent" {
    const input = "{ value: 1.5e }";
    var result = parse(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "syntax errors: multiple colons in field" {
    const input = "{ name:: \"Alice\" }";
    var result = parse(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "syntax errors: array missing separator" {
    const input = "{ items: [\"a\" \"b\"] }";
    var result = parse(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "syntax errors: array with trailing comma not followed by item" {
    const input = "{ items: [\"a\",] }";
    var result = parse(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "syntax errors: nested object not closed" {
    const input = "{ data: { nested: \"value\" }";
    var result = parse(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "syntax errors: nested array not closed" {
    const input = "{ matrix: [[1,2] }";
    var result = parse(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "syntax errors: object with missing colon after field name" {
    const input = "{ name \"Alice\" }";
    var result = parse(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "syntax errors: array with just opening brace" {
    const input = "{ items: [ }";
    var result = parse(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "syntax errors: array with missing opening brace" {
    const input = "{ items: 1,2,3] }";
    var result = parse(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "syntax errors: field name with starting underscore" {
    const input = "{ _private: \"value\" }";
    var result = parse(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(result.ok);
    try std.testing.expect(result.data.?.object.get("_private") != null);
    try std.testing.expect(result.data.?.object.get("_private").?.string.len > 0);
}

test "syntax errors: field name in quotes" {
    const input = "{ \"private-field\": \"hidden\" }";
    var result = parse(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(result.ok);
    try std.testing.expect(result.data.?.object.get("\"private-field\"") != null);
    try std.testing.expect(result.data.?.object.get("\"private-field\"").?.string.len > 0);
}

test "syntax errors: multiple commas in object" {
    const input = "{ name: \"Alice\",, age: 30 }";
    var result = parse(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "syntax errors: comma at start of object" {
    const input = "{ , name: \"Alice\" }";
    var result = parse(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "syntax errors: invalid time format" {
    const input = "{ time: 25:00 }";
    var result = parse(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "syntax errors: invalid datetime format" {
    const input = "{ created: 2025-01-15T14:90+02:00 }";
    var result = parse(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}

test "syntax errors: string with unescaped quote" {
    const input = "{ text: \"Hello \"World\"\" }";
    var result = parse(std.testing.allocator, input);
    defer result.deinit();
    try std.testing.expect(!result.ok);
}
