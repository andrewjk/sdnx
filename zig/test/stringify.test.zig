const std = @import("std");
const Allocator = std.mem.Allocator;
const sdn = @import("sdn");
const Value = sdn.Value;
const parse = sdn.parse;
const stringify = sdn.stringify;

test "stringify: basic object" {
    const allocator = std.testing.allocator;

    var object = std.StringArrayHashMap(Value).init(allocator);
    defer object.deinit();

    try object.put("name", Value{ .string = "Alice" });
    try object.put("age", Value{ .int = 25 });
    try object.put("active", Value{ .bool = true });
    try object.put("rating", Value{ .num = 4.5 });
    try object.put("balance", Value{ .int = -100 });

    var tags: std.ArrayList(Value) = .empty;
    defer tags.deinit(allocator);
    try tags.append(allocator, Value{ .string = "developer" });
    try tags.append(allocator, Value{ .string = "writer" });
    try object.put("tags", Value{ .array = tags });

    const input = Value{ .object = object };

    var opts = sdn.StringifyOptions{};
    const result = try stringify(allocator, input, &opts);
    defer allocator.free(result);

    const expected =
        "{\n" ++
        "\tname: \"Alice\",\n" ++
        "\tage: 25,\n" ++
        "\tactive: true,\n" ++
        "\trating: 4.5,\n" ++
        "\tbalance: -100,\n" ++
        "\ttags: [\n" ++
        "\t\t\"developer\",\n" ++
        "\t\t\"writer\"\n" ++
        "\t]\n" ++
        "}";

    try std.testing.expectEqualStrings(expected, result);

    var parsed = parse(allocator, result);
    defer parsed.deinit();
    try std.testing.expect(parsed.ok);
}

test "stringify: empty object" {
    const allocator = std.testing.allocator;

    var object = std.StringArrayHashMap(Value).init(allocator);
    defer object.deinit();

    const input = Value{ .object = object };

    var opts = sdn.StringifyOptions{};
    const result = try stringify(allocator, input, &opts);
    defer allocator.free(result);

    const expected = "{\n" ++
        "}";

    try std.testing.expectEqualStrings(expected, result);

    var parsed = parse(allocator, result);
    defer parsed.deinit();
    try std.testing.expect(parsed.ok);
}

test "stringify: empty array" {
    const allocator = std.testing.allocator;

    var object = std.StringArrayHashMap(Value).init(allocator);
    defer object.deinit();

    var items: std.ArrayList(Value) = .empty;
    defer items.deinit(allocator);
    try object.put("items", Value{ .array = items });

    const input = Value{ .object = object };

    var opts = sdn.StringifyOptions{};
    const result = try stringify(allocator, input, &opts);
    defer allocator.free(result);

    const expected =
        "{\n" ++
        "\titems: [\n" ++
        "\t]\n" ++
        "}";

    try std.testing.expectEqualStrings(expected, result);

    var parsed = parse(allocator, result);
    defer parsed.deinit();
    try std.testing.expect(parsed.ok);
}

test "stringify: nested objects" {
    const allocator = std.testing.allocator;

    var address = std.StringArrayHashMap(Value).init(allocator);
    defer address.deinit();
    try address.put("city", Value{ .string = "New York" });
    try address.put("country", Value{ .string = "USA" });

    var user = std.StringArrayHashMap(Value).init(allocator);
    defer user.deinit();
    try user.put("name", Value{ .string = "Bob" });
    try user.put("age", Value{ .int = 30 });
    try user.put("address", Value{ .object = address });

    var object = std.StringArrayHashMap(Value).init(allocator);
    defer object.deinit();
    try object.put("user", Value{ .object = user });

    const input = Value{ .object = object };

    var opts = sdn.StringifyOptions{};
    const result = try stringify(allocator, input, &opts);
    defer allocator.free(result);

    const expected =
        "{\n" ++
        "\tuser: {\n" ++
        "\t\tname: \"Bob\",\n" ++
        "\t\tage: 30,\n" ++
        "\t\taddress: {\n" ++
        "\t\t\tcity: \"New York\",\n" ++
        "\t\t\tcountry: \"USA\"\n" ++
        "\t\t}\n" ++
        "\t}\n" ++
        "}";

    try std.testing.expectEqualStrings(expected, result);

    var parsed = parse(allocator, result);
    defer parsed.deinit();
    try std.testing.expect(parsed.ok);
}

test "stringify: nested arrays" {
    const allocator = std.testing.allocator;

    var matrix: std.ArrayList(Value) = .empty;
    defer matrix.deinit(allocator);

    var row1: std.ArrayList(Value) = .empty;
    defer row1.deinit(allocator);
    try row1.append(allocator, Value{ .int = 1 });
    try row1.append(allocator, Value{ .int = 2 });
    try row1.append(allocator, Value{ .int = 3 });

    var row2: std.ArrayList(Value) = .empty;
    defer row2.deinit(allocator);
    try row2.append(allocator, Value{ .int = 4 });
    try row2.append(allocator, Value{ .int = 5 });
    try row2.append(allocator, Value{ .int = 6 });

    var row3: std.ArrayList(Value) = .empty;
    defer row3.deinit(allocator);
    try row3.append(allocator, Value{ .int = 7 });
    try row3.append(allocator, Value{ .int = 8 });
    try row3.append(allocator, Value{ .int = 9 });

    try matrix.append(allocator, Value{ .array = row1 });
    try matrix.append(allocator, Value{ .array = row2 });
    try matrix.append(allocator, Value{ .array = row3 });

    var object = std.StringArrayHashMap(Value).init(allocator);
    defer object.deinit();
    try object.put("matrix", Value{ .array = matrix });

    const input = Value{ .object = object };

    var opts = sdn.StringifyOptions{};
    const result = try stringify(allocator, input, &opts);
    defer allocator.free(result);

    const expected =
        "{\n" ++
        "\tmatrix: [\n" ++
        "\t\t[\n" ++
        "\t\t\t1,\n" ++
        "\t\t\t2,\n" ++
        "\t\t\t3\n" ++
        "\t\t],\n" ++
        "\t\t[\n" ++
        "\t\t\t4,\n" ++
        "\t\t\t5,\n" ++
        "\t\t\t6\n" ++
        "\t\t],\n" ++
        "\t\t[\n" ++
        "\t\t\t7,\n" ++
        "\t\t\t8,\n" ++
        "\t\t\t9\n" ++
        "\t\t]\n" ++
        "\t]\n" ++
        "}";

    try std.testing.expectEqualStrings(expected, result);

    var parsed = parse(allocator, result);
    defer parsed.deinit();
    try std.testing.expect(parsed.ok);
}

test "stringify: date without time" {
    const allocator = std.testing.allocator;

    var object = std.StringArrayHashMap(Value).init(allocator);
    defer object.deinit();
    try object.put("created_at", Value{ .date = "2025-01-15" });

    const input = Value{ .object = object };

    var opts = sdn.StringifyOptions{};
    const result = try stringify(allocator, input, &opts);
    defer allocator.free(result);

    var parsed = parse(allocator, result);
    defer parsed.deinit();
    try std.testing.expect(parsed.ok);
}

test "stringify: date with time" {
    const allocator = std.testing.allocator;

    var object = std.StringArrayHashMap(Value).init(allocator);
    defer object.deinit();
    try object.put("meeting_at", Value{ .date = "2025-01-15T10:30" });

    const input = Value{ .object = object };

    var opts = sdn.StringifyOptions{};
    const result = try stringify(allocator, input, &opts);
    defer allocator.free(result);

    const expected = "{\n" ++
        "\tmeeting_at: 2025-01-15T10:30\n" ++
        "}";

    try std.testing.expectEqualStrings(expected, result);

    var parsed = parse(allocator, result);
    defer parsed.deinit();
    try std.testing.expect(parsed.ok);
}

test "stringify: date with time including seconds" {
    const allocator = std.testing.allocator;

    var object = std.StringArrayHashMap(Value).init(allocator);
    defer object.deinit();
    try object.put("event_at", Value{ .date = "2025-01-15T10:30:45" });

    const input = Value{ .object = object };

    var opts = sdn.StringifyOptions{};
    const result = try stringify(allocator, input, &opts);
    defer allocator.free(result);

    const expected = "{\n" ++
        "\tevent_at: 2025-01-15T10:30:45\n" ++
        "}";

    try std.testing.expectEqualStrings(expected, result);

    var parsed = parse(allocator, result);
    defer parsed.deinit();
    try std.testing.expect(parsed.ok);
}

test "stringify: boolean values" {
    const allocator = std.testing.allocator;

    var object = std.StringArrayHashMap(Value).init(allocator);
    defer object.deinit();
    try object.put("is_active", Value{ .bool = true });
    try object.put("is_deleted", Value{ .bool = false });

    const input = Value{ .object = object };

    var opts = sdn.StringifyOptions{};
    const result = try stringify(allocator, input, &opts);
    defer allocator.free(result);

    const expected = "{\n" ++
        "\tis_active: true,\n" ++
        "\tis_deleted: false\n" ++
        "}";

    try std.testing.expectEqualStrings(expected, result);

    var parsed = parse(allocator, result);
    defer parsed.deinit();
    try std.testing.expect(parsed.ok);
}

test "stringify: null values" {
    const allocator = std.testing.allocator;

    var object = std.StringArrayHashMap(Value).init(allocator);
    defer object.deinit();
    try object.put("optional", Value{ .null = {} });
    try object.put("another", Value{ .null = {} });

    const input = Value{ .object = object };

    var opts = sdn.StringifyOptions{};
    const result = try stringify(allocator, input, &opts);
    defer allocator.free(result);

    const expected = "{\n" ++
        "\toptional: null,\n" ++
        "\tanother: null\n" ++
        "}";

    try std.testing.expectEqualStrings(expected, result);

    var parsed = parse(allocator, result);
    defer parsed.deinit();
    try std.testing.expect(parsed.ok);
}

test "stringify: numbers" {
    const allocator = std.testing.allocator;

    var object = std.StringArrayHashMap(Value).init(allocator);
    defer object.deinit();
    try object.put("integer", Value{ .int = 42 });
    try object.put("float", Value{ .num = 3.14 });
    try object.put("negative", Value{ .int = -10 });
    try object.put("zero", Value{ .int = 0 });
    try object.put("scientific", Value{ .num = 1.5e10 });
    try object.put("hex", Value{ .int = 0xff });

    const input = Value{ .object = object };

    var opts = sdn.StringifyOptions{};
    const result = try stringify(allocator, input, &opts);
    defer allocator.free(result);

    const expected = "{\n" ++
        "\tinteger: 42,\n" ++
        "\tfloat: 3.14,\n" ++
        "\tnegative: -10,\n" ++
        "\tzero: 0,\n" ++
        "\tscientific: 15000000000,\n" ++
        "\thex: 255\n" ++
        "}";

    try std.testing.expectEqualStrings(expected, result);

    var parsed = parse(allocator, result);
    defer parsed.deinit();
    try std.testing.expect(parsed.ok);
}

test "stringify: strings with special characters" {
    const allocator = std.testing.allocator;

    var object = std.StringArrayHashMap(Value).init(allocator);
    defer object.deinit();
    try object.put("quote", Value{ .string = "She said \"Hello\"" });
    try object.put("path", Value{ .string = "/usr/local/bin" });
    try object.put("regex", Value{ .string = "^test.*pattern$" });

    const input = Value{ .object = object };

    var opts = sdn.StringifyOptions{};
    const result = try stringify(allocator, input, &opts);
    defer allocator.free(result);

    const expected = "{\n" ++
        "\tquote: \"She said \"Hello\"\",\n" ++
        "\tpath: \"/usr/local/bin\",\n" ++
        "\tregex: \"^test.*pattern$\"\n" ++
        "}";

    try std.testing.expectEqualStrings(expected, result);

    var parsed = parse(allocator, result);
    defer parsed.deinit();
    try std.testing.expect(parsed.ok == false);
}

test "stringify: large dataset" {
    const allocator = std.testing.allocator;

    var users: std.ArrayList(Value) = .empty;
    defer users.deinit(allocator);

    var user1 = std.StringArrayHashMap(Value).init(allocator);
    defer user1.deinit();
    try user1.put("id", Value{ .int = 1 });
    try user1.put("name", Value{ .string = "Alice" });
    try user1.put("active", Value{ .bool = true });

    var user2 = std.StringArrayHashMap(Value).init(allocator);
    defer user2.deinit();
    try user2.put("id", Value{ .int = 2 });
    try user2.put("name", Value{ .string = "Bob" });
    try user2.put("active", Value{ .bool = false });

    var user3 = std.StringArrayHashMap(Value).init(allocator);
    defer user3.deinit();
    try user3.put("id", Value{ .int = 3 });
    try user3.put("name", Value{ .string = "Charlie" });
    try user3.put("active", Value{ .bool = true });

    try users.append(allocator, Value{ .object = user1 });
    try users.append(allocator, Value{ .object = user2 });
    try users.append(allocator, Value{ .object = user3 });

    var stats = std.StringArrayHashMap(Value).init(allocator);
    defer stats.deinit();
    try stats.put("total", Value{ .int = 3 });
    try stats.put("active", Value{ .int = 2 });
    try stats.put("inactive", Value{ .int = 1 });
    try stats.put("rating", Value{ .num = 4.5 });

    var object = std.StringArrayHashMap(Value).init(allocator);
    defer object.deinit();
    try object.put("users", Value{ .array = users });
    try object.put("stats", Value{ .object = stats });

    const input = Value{ .object = object };

    var opts = sdn.StringifyOptions{};
    const result = try stringify(allocator, input, &opts);
    defer allocator.free(result);

    const expected = "{\n" ++
        "\tusers: [\n" ++
        "\t\t{\n" ++
        "\t\t\tid: 1,\n" ++
        "\t\t\tname: \"Alice\",\n" ++
        "\t\t\tactive: true\n" ++
        "\t\t},\n" ++
        "\t\t{\n" ++
        "\t\t\tid: 2,\n" ++
        "\t\t\tname: \"Bob\",\n" ++
        "\t\t\tactive: false\n" ++
        "\t\t},\n" ++
        "\t\t{\n" ++
        "\t\t\tid: 3,\n" ++
        "\t\t\tname: \"Charlie\",\n" ++
        "\t\t\tactive: true\n" ++
        "\t\t}\n" ++
        "\t],\n" ++
        "\tstats: {\n" ++
        "\t\ttotal: 3,\n" ++
        "\t\tactive: 2,\n" ++
        "\t\tinactive: 1,\n" ++
        "\t\trating: 4.5\n" ++
        "\t}\n" ++
        "}";

    try std.testing.expectEqualStrings(expected, result);

    var parsed = parse(allocator, result);
    defer parsed.deinit();
    try std.testing.expect(parsed.ok);
}

test "stringify: ansi color mode enabled" {
    const allocator = std.testing.allocator;

    var object = std.StringArrayHashMap(Value).init(allocator);
    defer object.deinit();
    try object.put("name", Value{ .string = "Alice" });
    try object.put("age", Value{ .int = 25 });
    try object.put("active", Value{ .bool = true });

    const input = Value{ .object = object };

    var opts = sdn.StringifyOptions{ .ansi = true };
    const result = try stringify(allocator, input, &opts);
    defer allocator.free(result);

    try std.testing.expect(result.len > 0);
    try std.testing.expect(std.mem.indexOf(u8, result, "\x1b[32m") != null);
    try std.testing.expect(std.mem.indexOf(u8, result, "\x1b[33m") != null);
    try std.testing.expect(std.mem.indexOf(u8, result, "\x1b[34m") != null);
    try std.testing.expect(std.mem.indexOf(u8, result, "\x1b[0m") != null);
}

test "stringify: ansi color mode disabled" {
    const allocator = std.testing.allocator;

    var object = std.StringArrayHashMap(Value).init(allocator);
    defer object.deinit();
    try object.put("name", Value{ .string = "Alice" });
    try object.put("age", Value{ .int = 25 });
    try object.put("active", Value{ .bool = true });

    const input = Value{ .object = object };

    var opts = sdn.StringifyOptions{};
    const result = try stringify(allocator, input, &opts);
    defer allocator.free(result);

    const expected = "{\n" ++
        "\tname: \"Alice\",\n" ++
        "\tage: 25,\n" ++
        "\tactive: true\n" ++
        "}";

    try std.testing.expectEqualStrings(expected, result);
    try std.testing.expect(std.mem.indexOf(u8, result, "\x1b[") == null);
}

test "stringify: ansi colors for dates" {
    const allocator = std.testing.allocator;

    var object = std.StringArrayHashMap(Value).init(allocator);
    defer object.deinit();
    try object.put("date", Value{ .date = "2025-01-15" });

    const input = Value{ .object = object };

    var opts = sdn.StringifyOptions{ .ansi = true };
    const result = try stringify(allocator, input, &opts);
    defer allocator.free(result);

    try std.testing.expect(std.mem.indexOf(u8, result, "\x1b[35m") != null);
}

test "stringify: array of objects" {
    const allocator = std.testing.allocator;

    var items: std.ArrayList(Value) = .empty;
    defer items.deinit(allocator);

    var item1 = std.StringArrayHashMap(Value).init(allocator);
    defer item1.deinit();
    try item1.put("name", Value{ .string = "Item 1" });
    try item1.put("count", Value{ .int = 5 });

    var item2 = std.StringArrayHashMap(Value).init(allocator);
    defer item2.deinit();
    try item2.put("name", Value{ .string = "Item 2" });
    try item2.put("count", Value{ .int = 10 });

    var item3 = std.StringArrayHashMap(Value).init(allocator);
    defer item3.deinit();
    try item3.put("name", Value{ .string = "Item 3" });
    try item3.put("count", Value{ .int = 15 });

    try items.append(allocator, Value{ .object = item1 });
    try items.append(allocator, Value{ .object = item2 });
    try items.append(allocator, Value{ .object = item3 });

    var object = std.StringArrayHashMap(Value).init(allocator);
    defer object.deinit();
    try object.put("items", Value{ .array = items });

    const input = Value{ .object = object };

    var opts = sdn.StringifyOptions{};
    const result = try stringify(allocator, input, &opts);
    defer allocator.free(result);

    const expected = "{\n" ++
        "\titems: [\n" ++
        "\t\t{\n" ++
        "\t\t\tname: \"Item 1\",\n" ++
        "\t\t\tcount: 5\n" ++
        "\t\t},\n" ++
        "\t\t{\n" ++
        "\t\t\tname: \"Item 2\",\n" ++
        "\t\t\tcount: 10\n" ++
        "\t\t},\n" ++
        "\t\t{\n" ++
        "\t\t\tname: \"Item 3\",\n" ++
        "\t\t\tcount: 15\n" ++
        "\t\t}\n" ++
        "\t]\n" ++
        "}";

    try std.testing.expectEqualStrings(expected, result);

    var parsed = parse(allocator, result);
    defer parsed.deinit();
    try std.testing.expect(parsed.ok);
}

test "stringify: deeply nested structures" {
    const allocator = std.testing.allocator;

    var level3 = std.StringArrayHashMap(Value).init(allocator);
    defer level3.deinit();
    try level3.put("deep", Value{ .string = "value" });

    var level2 = std.StringArrayHashMap(Value).init(allocator);
    defer level2.deinit();
    try level2.put("level3", Value{ .object = level3 });

    var level1 = std.StringArrayHashMap(Value).init(allocator);
    defer level1.deinit();
    try level1.put("level2", Value{ .object = level2 });

    var nested_array: std.ArrayList(Value) = .empty;
    defer nested_array.deinit(allocator);

    var arr1: std.ArrayList(Value) = .empty;
    defer arr1.deinit(allocator);
    var arr1a: std.ArrayList(Value) = .empty;
    defer arr1a.deinit(allocator);
    try arr1a.append(allocator, Value{ .int = 1 });
    try arr1a.append(allocator, Value{ .int = 2 });
    var arr1b: std.ArrayList(Value) = .empty;
    defer arr1b.deinit(allocator);
    try arr1b.append(allocator, Value{ .int = 3 });
    try arr1b.append(allocator, Value{ .int = 4 });
    try arr1.append(allocator, Value{ .array = arr1a });
    try arr1.append(allocator, Value{ .array = arr1b });

    var arr2: std.ArrayList(Value) = .empty;
    defer arr2.deinit(allocator);
    var arr2a: std.ArrayList(Value) = .empty;
    defer arr2a.deinit(allocator);
    try arr2a.append(allocator, Value{ .int = 5 });
    try arr2a.append(allocator, Value{ .int = 6 });
    var arr2b: std.ArrayList(Value) = .empty;
    defer arr2b.deinit(allocator);
    try arr2b.append(allocator, Value{ .int = 7 });
    try arr2b.append(allocator, Value{ .int = 8 });
    try arr2.append(allocator, Value{ .array = arr2a });
    try arr2.append(allocator, Value{ .array = arr2b });

    try nested_array.append(allocator, Value{ .array = arr1 });
    try nested_array.append(allocator, Value{ .array = arr2 });

    var object = std.StringArrayHashMap(Value).init(allocator);
    defer object.deinit();
    try object.put("level1", Value{ .object = level1 });
    try object.put("nested_array", Value{ .array = nested_array });

    const input = Value{ .object = object };

    var opts = sdn.StringifyOptions{};
    const result = try stringify(allocator, input, &opts);
    defer allocator.free(result);

    const expected = "{\n" ++
        "\tlevel1: {\n" ++
        "\t\tlevel2: {\n" ++
        "\t\t\tlevel3: {\n" ++
        "\t\t\t\tdeep: \"value\"\n" ++
        "\t\t\t}\n" ++
        "\t\t}\n" ++
        "\t},\n" ++
        "\tnested_array: [\n" ++
        "\t\t[\n" ++
        "\t\t\t[\n" ++
        "\t\t\t\t1,\n" ++
        "\t\t\t\t2\n" ++
        "\t\t\t],\n" ++
        "\t\t\t[\n" ++
        "\t\t\t\t3,\n" ++
        "\t\t\t\t4\n" ++
        "\t\t\t]\n" ++
        "\t\t],\n" ++
        "\t\t[\n" ++
        "\t\t\t[\n" ++
        "\t\t\t\t5,\n" ++
        "\t\t\t\t6\n" ++
        "\t\t\t],\n" ++
        "\t\t\t[\n" ++
        "\t\t\t\t7,\n" ++
        "\t\t\t\t8\n" ++
        "\t\t\t]\n" ++
        "\t\t]\n" ++
        "\t]\n" ++
        "}";

    try std.testing.expectEqualStrings(expected, result);

    var parsed = parse(allocator, result);
    defer parsed.deinit();
    try std.testing.expect(parsed.ok);
}

test "stringify: custom indent with 2 spaces" {
    const allocator = std.testing.allocator;

    var object = std.StringArrayHashMap(Value).init(allocator);
    defer object.deinit();
    try object.put("name", Value{ .string = "Alice" });
    try object.put("age", Value{ .int = 25 });

    var tags: std.ArrayList(Value) = .empty;
    defer tags.deinit(allocator);
    try tags.append(allocator, Value{ .string = "developer" });

    try object.put("tags", Value{ .array = tags });

    const input = Value{ .object = object };

    var opts = sdn.StringifyOptions{ .indent = "  " };
    const result = try stringify(allocator, input, &opts);
    defer allocator.free(result);

    const expected =
        "{\n" ++
        "  name: \"Alice\",\n" ++
        "  age: 25,\n" ++
        "  tags: [\n" ++
        "    \"developer\"\n" ++
        "  ]\n" ++
        "}";

    try std.testing.expectEqualStrings(expected, result);

    var parsed = parse(allocator, result);
    defer parsed.deinit();
    try std.testing.expect(parsed.ok);
}

test "stringify: custom indent with 4 spaces" {
    const allocator = std.testing.allocator;

    var object = std.StringArrayHashMap(Value).init(allocator);
    defer object.deinit();
    try object.put("name", Value{ .string = "Alice" });
    try object.put("age", Value{ .int = 25 });

    const input = Value{ .object = object };

    var opts = sdn.StringifyOptions{ .indent = "    " };
    const result = try stringify(allocator, input, &opts);
    defer allocator.free(result);

    const expected =
        "{\n" ++
        "    name: \"Alice\",\n" ++
        "    age: 25\n" ++
        "}";

    try std.testing.expectEqualStrings(expected, result);

    var parsed = parse(allocator, result);
    defer parsed.deinit();
    try std.testing.expect(parsed.ok);
}
