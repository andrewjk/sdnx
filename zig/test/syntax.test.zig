const std = @import("std");
const sdn = @import("sdn");
const parse = sdn.parse;

test "syntax errors: no opening brace at top level" {
    const input = "age: 5";
    var data = parse(std.testing.allocator, input) catch |err| {
        try std.testing.expect(err == error.ExpectedBrace);
        return;
    };
    defer data.deinit(std.testing.allocator);
    try std.testing.expect(false);
}

test "syntax errors: no closing brace at top level" {
    const input = "{ age: 5";
    var data = parse(std.testing.allocator, input) catch |err| {
        try std.testing.expect(err == error.ObjectNotClosed);
        return;
    };
    defer data.deinit(std.testing.allocator);
    try std.testing.expect(false);
}

test "syntax errors: no closing array brace" {
    const input = "{ foods: [\"ice cream\", \"strudel\" }";
    var data = parse(std.testing.allocator, input) catch |err| {
        try std.testing.expect(err == error.ArrayNotClosed);
        return;
    };
    defer data.deinit(std.testing.allocator);
    try std.testing.expect(false);
}

test "syntax errors: no field value" {
    const input = "{ foods, things: true }";
    var data = parse(std.testing.allocator, input) catch |err| {
        try std.testing.expect(err == error.ExpectedChar);
        return;
    };
    defer data.deinit(std.testing.allocator);
    try std.testing.expect(false);
}

test "syntax errors: unsupported value type" {
    const input = "{ foods: things }";
    var data = parse(std.testing.allocator, input) catch |err| {
        try std.testing.expect(err == error.UnsupportedValueType);
        return;
    };
    defer data.deinit(std.testing.allocator);
    try std.testing.expect(false);
}

test "syntax errors: empty input" {
    const input = "";
    var data = parse(std.testing.allocator, input) catch |err| {
        try std.testing.expect(err == error.ExpectedBrace);
        return;
    };
    defer data.deinit(std.testing.allocator);
    try std.testing.expect(false);
}

test "syntax errors: just whitespace" {
    const input = "   \n\t  ";
    var data = parse(std.testing.allocator, input) catch |err| {
        try std.testing.expect(err == error.ExpectedBrace);
        return;
    };
    defer data.deinit(std.testing.allocator);
    try std.testing.expect(false);
}

test "syntax errors: field name starts with number" {
    const input = "{ 1field: \"value\" }";
    var data = parse(std.testing.allocator, input) catch |err| {
        try std.testing.expect(err == error.InvalidFieldName);
        return;
    };
    defer data.deinit(std.testing.allocator);
    try std.testing.expect(false);
}

test "syntax errors: field name with special chars" {
    const input = "{ field-name: \"value\" }";
    var data = parse(std.testing.allocator, input) catch |err| {
        try std.testing.expect(err == error.InvalidFieldName);
        return;
    };
    defer data.deinit(std.testing.allocator);
    try std.testing.expect(false);
}

test "syntax errors: unclosed string" {
    const input = "{ name: \"Alice }";
    var data = parse(std.testing.allocator, input) catch |err| {
        try std.testing.expect(err == error.UnterminatedString);
        return;
    };
    defer data.deinit(std.testing.allocator);
    try std.testing.expect(false);
}

test "syntax errors: invalid escape sequence" {
    const input = "{ quote: \"Hel\\lo\" }";
    var data = parse(std.testing.allocator, input) catch |err| {
        try std.testing.expect(err == error.InvalidEscapeSequence);
        return;
    };
    defer data.deinit(std.testing.allocator);
    try std.testing.expect(false);
}

test "syntax errors: number with decimal but no digits" {
    const input = "{ value: 123. }";
    var data = parse(std.testing.allocator, input) catch |err| {
        try std.testing.expect(err == error.UnsupportedValueType);
        return;
    };
    defer data.deinit(std.testing.allocator);
    try std.testing.expect(false);
}

test "syntax errors: hex number with invalid chars" {
    const input = "{ color: 0xGHIJKL }";
    var data = parse(std.testing.allocator, input) catch |err| {
        try std.testing.expect(err == error.UnsupportedValueType);
        return;
    };
    defer data.deinit(std.testing.allocator);
    try std.testing.expect(false);
}

test "syntax errors: invalid date format" {
    const input = "{ dob: 2025-13-01 }";
    var data = parse(std.testing.allocator, input) catch |err| {
        try std.testing.expect(err == error.UnsupportedValueType);
        return;
    };
    defer data.deinit(std.testing.allocator);
    try std.testing.expect(false);
}

test "syntax errors: boolean with wrong case" {
    const input = "{ active: True }";
    var data = parse(std.testing.allocator, input) catch |err| {
        try std.testing.expect(err == error.UnsupportedValueType);
        return;
    };
    defer data.deinit(std.testing.allocator);
    try std.testing.expect(false);
}

test " syntax errors: negative without digits" {
    const input = "{ value: - }";
    var data = parse(std.testing.allocator, input) catch |err| {
        try std.testing.expect(err == error.UnsupportedValueType);
        return;
    };
    defer data.deinit(std.testing.allocator);
    try std.testing.expect(false);
}

test "syntax errors: scientific notation missing exponent" {
    const input = "{ value: 1.5e }";
    var data = parse(std.testing.allocator, input) catch |err| {
        try std.testing.expect(err == error.UnsupportedValueType);
        return;
    };
    defer data.deinit(std.testing.allocator);
    try std.testing.expect(false);
}

test "syntax errors: multiple colons in field" {
    const input = "{ name:: \"Alice\" }";
    var data = parse(std.testing.allocator, input) catch |err| {
        try std.testing.expect(err == error.InvalidFieldName);
        return;
    };
    defer data.deinit(std.testing.allocator);
    try std.testing.expect(false);
}

test "syntax errors: array missing separator" {
    const input = "{ items: [\"a\" \"b\"] }";
    var data = parse(std.testing.allocator, input) catch |err| {
        try std.testing.expect(err == error.InvalidCharacter);
        return;
    };
    defer data.deinit(std.testing.allocator);
    try std.testing.expect(false);
}

test "syntax errors: array with trailing comma not followed by item" {
    const input = "{ items: [\"a\",] }";
    var data = parse(std.testing.allocator, input) catch |err| {
        try std.testing.expect(err == error.UnsupportedValueType);
        return;
    };
    defer data.deinit(std.testing.allocator);
    try std.testing.expect(false);
}

test "syntax errors: nested object not closed" {
    const input = "{ data: { nested: \"value\" }";
    var data = parse(std.testing.allocator, input) catch |err| {
        try std.testing.expect(err == error.ObjectNotClosed);
        return;
    };
    defer data.deinit(std.testing.allocator);
    try std.testing.expect(false);
}

test "syntax errors: nested array not closed" {
    const input = "{ matrix: [[1,2] }";
    var data = parse(std.testing.allocator, input) catch |err| {
        try std.testing.expect(err == error.ArrayNotClosed);
        return;
    };
    defer data.deinit(std.testing.allocator);
    try std.testing.expect(false);
}

test "syntax errors: object with missing colon after field name" {
    const input = "{ name \"Alice\" }";
    var data = parse(std.testing.allocator, input) catch |err| {
        try std.testing.expect(err == error.ExpectedChar);
        return;
    };
    defer data.deinit(std.testing.allocator);
    try std.testing.expect(false);
}

test "syntax errors: array with just opening brace" {
    const input = "{ items: [ }";
    var data = parse(std.testing.allocator, input) catch |err| {
        try std.testing.expect(err == error.ArrayNotClosed);
        return;
    };
    defer data.deinit(std.testing.allocator);
    try std.testing.expect(false);
}

test "syntax errors: array with missing opening brace" {
    const input = "{ items: 1,2,3] }";
    var data = parse(std.testing.allocator, input) catch |err| {
        try std.testing.expect(err == error.InvalidFieldName);
        return;
    };
    defer data.deinit(std.testing.allocator);
    try std.testing.expect(false);
}

test "syntax errors: field name with starting underscore" {
    const input = "{ _private: \"value\" }";
    var data = parse(std.testing.allocator, input) catch |err| {
        std.debug.print("Error parsing schema: {}\n", .{err});
        return error.ParseFailed;
    };
    defer data.deinit(std.testing.allocator);

    try std.testing.expect(data.object.get("_private") != null);
    try std.testing.expect(data.object.get("_private").?.string.len > 0);
}

test "syntax errors: field name in quotes" {
    const input = "{ \"private-field\": \"hidden\" }";
    var data = parse(std.testing.allocator, input) catch |err| {
        std.debug.print("Error parsing schema: {}\n", .{err});
        return error.ParseFailed;
    };
    defer data.deinit(std.testing.allocator);

    try std.testing.expect(data.object.get("\"private-field\"") != null);
    try std.testing.expect(data.object.get("\"private-field\"").?.string.len > 0);
}

test "syntax errors: multiple commas in object" {
    const input = "{ name: \"Alice\",, age: 30 }";
    var data = parse(std.testing.allocator, input) catch |err| {
        try std.testing.expect(err == error.InvalidFieldName);
        return;
    };
    defer data.deinit(std.testing.allocator);
    try std.testing.expect(false);
}

test "syntax errors: comma at start of object" {
    const input = "{ , name: \"Alice\" }";
    var data = parse(std.testing.allocator, input) catch |err| {
        try std.testing.expect(err == error.InvalidFieldName);
        return;
    };
    defer data.deinit(std.testing.allocator);
    try std.testing.expect(false);
}

test "syntax errors: invalid time format" {
    const input = "{ time: 25:00 }";
    var data = parse(std.testing.allocator, input) catch |err| {
        try std.testing.expect(err == error.UnsupportedValueType);
        return;
    };
    defer data.deinit(std.testing.allocator);
    try std.testing.expect(false);
}

test "syntax errors: invalid datetime format" {
    const input = "{ created: 2025-01-15T14:90+02:00 }";
    var data = parse(std.testing.allocator, input) catch |err| {
        try std.testing.expect(err == error.UnsupportedValueType);
        return;
    };
    defer data.deinit(std.testing.allocator);
    try std.testing.expect(false);
}

test "syntax errors: string with unescaped quote" {
    const input = "{ text: \"Hello \"World\"\" }";
    var data = parse(std.testing.allocator, input) catch |err| {
        try std.testing.expect(err == error.ExpectedChar);
        return;
    };
    defer data.deinit(std.testing.allocator);
    try std.testing.expect(false);
}
