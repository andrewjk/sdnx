const std = @import("std");
const sdn = @import("sdn");
const parse = sdn.parse;
const spaceUnspace = @import("spaceUnspace.zig");

fn expectBasicTest(result: anytype) !void {
    try std.testing.expect(result == .object);

    const active = result.object.get("active");
    try std.testing.expect(active != null);
    try std.testing.expect(active.?.bool == true);

    const name = result.object.get("name");
    try std.testing.expect(name != null);
    try std.testing.expect(std.mem.eql(u8, name.?.string, "Darren"));

    const age = result.object.get("age");
    try std.testing.expect(age != null);
    try std.testing.expect(age.?.int == 25);

    const rating = result.object.get("rating");
    try std.testing.expect(rating != null);
    try std.testing.expect(rating.?.num == 4.2);

    const skills = result.object.get("skills");
    try std.testing.expect(skills != null);
    try std.testing.expect(skills.? == .string);

    const started_at = result.object.get("started_at");
    try std.testing.expect(started_at != null);
    try std.testing.expect(started_at.? == .date);

    const meeting_at = result.object.get("meeting_at");
    try std.testing.expect(meeting_at != null);
    try std.testing.expect(meeting_at.? == .date);

    const children = result.object.get("children");
    try std.testing.expect(children != null);
    try std.testing.expect(children.? == .array);
    try std.testing.expect(children.?.array.items.len == 1);

    const has_license = result.object.get("has_license");
    try std.testing.expect(has_license != null);
    try std.testing.expect(has_license.?.bool == true);

    const license_num = result.object.get("license_num");
    try std.testing.expect(license_num != null);
    try std.testing.expect(std.mem.eql(u8, license_num.?.string, "112"));
}

test "parse: basic test" {
    const allocator = std.testing.allocator;
    const input =
        \\{
        \\  active: true,
        \\  name: "Darren",
        \\  age: 25,
        \\  rating: 4.2,
        \\  # strings can be multiline
        \\  skills: "very good at",
        \\  started_at: 2025-01-01,
        \\  meeting_at: 2026-01-01T10:00,
        \\  children: [{
        \\    name: "Rocket",
        \\    age: 5,
        \\  }],
        \\  has_license: true,
        \\  license_num: "112",
        \\}
    ;

    // Test original input
    {
        var result = parse(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try expectBasicTest(result.data.?);
    }

    // Test spaced input (with time fix)
    {
        const spaced = try spaceUnspace.space(allocator, input);
        defer allocator.free(spaced);
        const fixed = try spaceUnspace.replaceAll(allocator, spaced, "10 : 00", "10:00");
        defer allocator.free(fixed);
        var result = parse(allocator, fixed);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try expectBasicTest(result.data.?);
    }

    // Test unspaced input
    {
        const unspaced = try spaceUnspace.unspace(allocator, input);
        defer allocator.free(unspaced);
        var result = parse(allocator, unspaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try expectBasicTest(result.data.?);
    }
}

test "parse: empty object" {
    const allocator = std.testing.allocator;

    // Test original input
    {
        var result = parse(allocator, "{}");
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        try std.testing.expect(result.data.?.object.count() == 0);
    }

    // Test spaced input
    {
        const spaced = try spaceUnspace.space(allocator, "{}");
        defer allocator.free(spaced);
        var result = parse(allocator, spaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        try std.testing.expect(result.data.?.object.count() == 0);
    }

    // Test unspaced input
    {
        const unspaced = try spaceUnspace.unspace(allocator, "{}");
        defer allocator.free(unspaced);
        var result = parse(allocator, unspaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        try std.testing.expect(result.data.?.object.count() == 0);
    }
}

test "parse: negative numbers" {
    const allocator = std.testing.allocator;
    const input = "{temp: -10, balance: -3.14}";

    // Test original input
    {
        var result = parse(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const temp = result.data.?.object.get("temp");
        try std.testing.expect(temp != null);
        try std.testing.expect(temp.?.int == -10);
        const balance = result.data.?.object.get("balance");
        try std.testing.expect(balance != null);
        try std.testing.expect(balance.?.num == -3.14);
    }

    // Test spaced input
    {
        const spaced = try spaceUnspace.space(allocator, input);
        defer allocator.free(spaced);
        var result = parse(allocator, spaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const temp = result.data.?.object.get("temp");
        try std.testing.expect(temp != null);
        try std.testing.expect(temp.?.int == -10);
        const balance = result.data.?.object.get("balance");
        try std.testing.expect(balance != null);
        try std.testing.expect(balance.?.num == -3.14);
    }

    // Test unspaced input
    {
        const unspaced = try spaceUnspace.unspace(allocator, input);
        defer allocator.free(unspaced);
        var result = parse(allocator, unspaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const temp = result.data.?.object.get("temp");
        try std.testing.expect(temp != null);
        try std.testing.expect(temp.?.int == -10);
        const balance = result.data.?.object.get("balance");
        try std.testing.expect(balance != null);
        try std.testing.expect(balance.?.num == -3.14);
    }
}

test "parse: positive numbers with plus prefix" {
    const allocator = std.testing.allocator;
    const input = "{count: +42, score: +4.5}";

    // Test original input
    {
        var result = parse(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const count = result.data.?.object.get("count");
        try std.testing.expect(count != null);
        try std.testing.expect(count.?.int == 42);
        const score = result.data.?.object.get("score");
        try std.testing.expect(score != null);
        try std.testing.expect(score.?.num == 4.5);
    }

    // Test spaced input
    {
        const spaced = try spaceUnspace.space(allocator, input);
        defer allocator.free(spaced);
        var result = parse(allocator, spaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const count = result.data.?.object.get("count");
        try std.testing.expect(count != null);
        try std.testing.expect(count.?.int == 42);
        const score = result.data.?.object.get("score");
        try std.testing.expect(score != null);
        try std.testing.expect(score.?.num == 4.5);
    }

    // Test unspaced input
    {
        const unspaced = try spaceUnspace.unspace(allocator, input);
        defer allocator.free(unspaced);
        var result = parse(allocator, unspaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const count = result.data.?.object.get("count");
        try std.testing.expect(count != null);
        try std.testing.expect(count.?.int == 42);
        const score = result.data.?.object.get("score");
        try std.testing.expect(score != null);
        try std.testing.expect(score.?.num == 4.5);
    }
}

test "parse: hexadecimal integers" {
    const allocator = std.testing.allocator;
    const input = "{color: 0xFF00FF, alpha: 0xAB}";

    // Test original input
    {
        var result = parse(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const color = result.data.?.object.get("color");
        try std.testing.expect(color != null);
        try std.testing.expect(color.?.int == 0xFF00FF);
        const alpha = result.data.?.object.get("alpha");
        try std.testing.expect(alpha != null);
        try std.testing.expect(alpha.?.int == 0xAB);
    }

    // Test spaced input
    {
        const spaced = try spaceUnspace.space(allocator, input);
        defer allocator.free(spaced);
        var result = parse(allocator, spaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const color = result.data.?.object.get("color");
        try std.testing.expect(color != null);
        try std.testing.expect(color.?.int == 0xFF00FF);
        const alpha = result.data.?.object.get("alpha");
        try std.testing.expect(alpha != null);
        try std.testing.expect(alpha.?.int == 0xAB);
    }

    // Test unspaced input
    {
        const unspaced = try spaceUnspace.unspace(allocator, input);
        defer allocator.free(unspaced);
        var result = parse(allocator, unspaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const color = result.data.?.object.get("color");
        try std.testing.expect(color != null);
        try std.testing.expect(color.?.int == 0xFF00FF);
        const alpha = result.data.?.object.get("alpha");
        try std.testing.expect(alpha != null);
        try std.testing.expect(alpha.?.int == 0xAB);
    }
}

test "parse: scientific notation" {
    const allocator = std.testing.allocator;
    const input = "{distance: 1.5e10, tiny: 1.5e-5}";

    // Test original input
    {
        var result = parse(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const distance = result.data.?.object.get("distance");
        try std.testing.expect(distance != null);
        try std.testing.expect(distance.?.num == 1.5e10);
        const tiny = result.data.?.object.get("tiny");
        try std.testing.expect(tiny != null);
        try std.testing.expect(tiny.?.num == 1.5e-5);
    }

    // Test spaced input
    {
        const spaced = try spaceUnspace.space(allocator, input);
        defer allocator.free(spaced);
        var result = parse(allocator, spaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const distance = result.data.?.object.get("distance");
        try std.testing.expect(distance != null);
        try std.testing.expect(distance.?.num == 1.5e10);
        const tiny = result.data.?.object.get("tiny");
        try std.testing.expect(tiny != null);
        try std.testing.expect(tiny.?.num == 1.5e-5);
    }

    // Test unspaced input
    {
        const unspaced = try spaceUnspace.unspace(allocator, input);
        defer allocator.free(unspaced);
        var result = parse(allocator, unspaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const distance = result.data.?.object.get("distance");
        try std.testing.expect(distance != null);
        try std.testing.expect(distance.?.num == 1.5e10);
        const tiny = result.data.?.object.get("tiny");
        try std.testing.expect(tiny != null);
        try std.testing.expect(tiny.?.num == 1.5e-5);
    }
}

test "parse: numbers with underscore separators" {
    const allocator = std.testing.allocator;
    const input = "{population: 1_000_000, big_number: 1_000_000.123}";

    // Test original input
    {
        var result = parse(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const population = result.data.?.object.get("population");
        try std.testing.expect(population != null);
        try std.testing.expect(population.?.int == 1_000_000);
        const big_number = result.data.?.object.get("big_number");
        try std.testing.expect(big_number != null);
        try std.testing.expect(big_number.?.num == 1_000_000.123);
    }

    // Test spaced input
    {
        const spaced = try spaceUnspace.space(allocator, input);
        defer allocator.free(spaced);
        var result = parse(allocator, spaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const population = result.data.?.object.get("population");
        try std.testing.expect(population != null);
        try std.testing.expect(population.?.int == 1_000_000);
        const big_number = result.data.?.object.get("big_number");
        try std.testing.expect(big_number != null);
        try std.testing.expect(big_number.?.num == 1_000_000.123);
    }

    // Test unspaced input
    {
        const unspaced = try spaceUnspace.unspace(allocator, input);
        defer allocator.free(unspaced);
        var result = parse(allocator, unspaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const population = result.data.?.object.get("population");
        try std.testing.expect(population != null);
        try std.testing.expect(population.?.int == 1_000_000);
        const big_number = result.data.?.object.get("big_number");
        try std.testing.expect(big_number != null);
        try std.testing.expect(big_number.?.num == 1_000_000.123);
    }
}

test "parse: string with escaped quotes" {
    const allocator = std.testing.allocator;
    const input = "{quote: \"She said \\\"Hello\\\"\"}";

    // Test original input
    {
        var result = parse(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const quote = result.data.?.object.get("quote");
        try std.testing.expect(quote != null);
        try std.testing.expect(quote.? == .string);
        try std.testing.expect(quote.?.string.len > 0);
    }

    // Test spaced input
    {
        const spaced = try spaceUnspace.space(allocator, input);
        defer allocator.free(spaced);
        var result = parse(allocator, spaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const quote = result.data.?.object.get("quote");
        try std.testing.expect(quote != null);
        try std.testing.expect(quote.? == .string);
    }

    // Test unspaced input
    {
        const unspaced = try spaceUnspace.unspace(allocator, input);
        defer allocator.free(unspaced);
        var result = parse(allocator, unspaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const quote = result.data.?.object.get("quote");
        try std.testing.expect(quote != null);
        try std.testing.expect(quote.? == .string);
    }
}

test "parse: multiline string" {
    const allocator = std.testing.allocator;
    const input =
        \\{
        \\  # strings can be multiline
        \\  skills: "
        \\    very good at
        \\      - reading
        \\      - writing
        \\      - selling",
        \\}
    ;

    // Test original input
    {
        var result = parse(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const skills = result.data.?.object.get("skills");
        try std.testing.expect(skills != null);
        try std.testing.expect(skills.? == .string);
        try std.testing.expect(std.mem.eql(u8, skills.?.string, "very good at\n  - reading\n  - writing\n  - selling"));
    }

    // Test spaced input
    {
        const spaced = try spaceUnspace.space(allocator, input);
        defer allocator.free(spaced);
        var result = parse(allocator, spaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const skills = result.data.?.object.get("skills");
        try std.testing.expect(skills != null);
        try std.testing.expect(std.mem.eql(u8, skills.?.string, "very good at\n  - reading\n  - writing\n  - selling"));
    }

    // Test unspaced input
    {
        const unspaced = try spaceUnspace.unspace(allocator, input);
        defer allocator.free(unspaced);
        var result = parse(allocator, unspaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const skills = result.data.?.object.get("skills");
        try std.testing.expect(skills != null);
        try std.testing.expect(std.mem.eql(u8, skills.?.string, "very good at\n  - reading\n  - writing\n  - selling"));
    }
}

test "parse: quoted field name" {
    const allocator = std.testing.allocator;
    const input = "{\"field-with-dash\": \"value\", \"with spaces\": \"test\"}";

    // Test original input
    {
        var result = parse(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        try std.testing.expect(result.data.?.object.count() == 2);
    }

    // Test spaced input
    {
        const spaced = try spaceUnspace.space(allocator, input);
        defer allocator.free(spaced);
        var result = parse(allocator, spaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        try std.testing.expect(result.data.?.object.count() == 2);
    }

    // Test unspaced input
    {
        const unspaced = try spaceUnspace.unspace(allocator, input);
        defer allocator.free(unspaced);
        var result = parse(allocator, unspaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        try std.testing.expect(result.data.?.object.count() == 2);
    }
}

test "parse: field names with numbers and underscores" {
    const allocator = std.testing.allocator;
    const input = "{field1: \"a\", field_2: \"b\", _private: \"c\", field_3_name: \"d\"}";

    // Test original input
    {
        var result = parse(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        try std.testing.expect(result.data.?.object.count() == 4);
        try std.testing.expect(std.mem.eql(u8, result.data.?.object.get("field1").?.string, "a"));
        try std.testing.expect(std.mem.eql(u8, result.data.?.object.get("field_2").?.string, "b"));
        try std.testing.expect(std.mem.eql(u8, result.data.?.object.get("_private").?.string, "c"));
        try std.testing.expect(std.mem.eql(u8, result.data.?.object.get("field_3_name").?.string, "d"));
    }

    // Test spaced input
    {
        const spaced = try spaceUnspace.space(allocator, input);
        defer allocator.free(spaced);
        var result = parse(allocator, spaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        try std.testing.expect(result.data.?.object.count() == 4);
    }

    // Test unspaced input
    {
        const unspaced = try spaceUnspace.unspace(allocator, input);
        defer allocator.free(unspaced);
        var result = parse(allocator, unspaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        try std.testing.expect(result.data.?.object.count() == 4);
    }
}

test "parse: time only" {
    const allocator = std.testing.allocator;
    const input = "{meeting_time: 14:30, alarm_time: 07:15:30}";

    // Test original input
    {
        var result = parse(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const meeting_time = result.data.?.object.get("meeting_time");
        try std.testing.expect(meeting_time != null);
        try std.testing.expect(meeting_time.? == .date);
        const alarm_time = result.data.?.object.get("alarm_time");
        try std.testing.expect(alarm_time != null);
        try std.testing.expect(alarm_time.? == .date);
    }

    // Test spaced input (with time fixes)
    {
        const spaced = try spaceUnspace.space(allocator, input);
        defer allocator.free(spaced);
        const fixed = try spaceUnspace.replaceAll(allocator, spaced, "14 : 30", "14:30");
        defer allocator.free(fixed);
        const fixed2 = try spaceUnspace.replaceAll(allocator, fixed, "07 : 15 : 30", "07:15:30");
        defer allocator.free(fixed2);
        var result = parse(allocator, fixed2);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const meeting_time = result.data.?.object.get("meeting_time");
        try std.testing.expect(meeting_time != null);
        try std.testing.expect(meeting_time.? == .date);
        const alarm_time = result.data.?.object.get("alarm_time");
        try std.testing.expect(alarm_time != null);
        try std.testing.expect(alarm_time.? == .date);
    }

    // Test unspaced input
    {
        const unspaced = try spaceUnspace.unspace(allocator, input);
        defer allocator.free(unspaced);
        var result = parse(allocator, unspaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const meeting_time = result.data.?.object.get("meeting_time");
        try std.testing.expect(meeting_time != null);
        try std.testing.expect(meeting_time.? == .date);
        const alarm_time = result.data.?.object.get("alarm_time");
        try std.testing.expect(alarm_time != null);
        try std.testing.expect(alarm_time.? == .date);
    }
}

test "parse: datetime with timezone offset" {
    const allocator = std.testing.allocator;
    const input = "{event_time: 2025-01-15T14:30+02:00}";

    // Test original input
    {
        var result = parse(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const event_time = result.data.?.object.get("event_time");
        try std.testing.expect(event_time != null);
        try std.testing.expect(event_time.? == .date);
    }

    // Test spaced input (with time fix)
    {
        const spaced = try spaceUnspace.space(allocator, input);
        defer allocator.free(spaced);
        const fixed = try spaceUnspace.replaceAll(allocator, spaced, "14 : 30+02 : 00", "14:30+02:00");
        defer allocator.free(fixed);
        var result = parse(allocator, fixed);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const event_time = result.data.?.object.get("event_time");
        try std.testing.expect(event_time != null);
        try std.testing.expect(event_time.? == .date);
    }

    // Test unspaced input
    {
        const unspaced = try spaceUnspace.unspace(allocator, input);
        defer allocator.free(unspaced);
        var result = parse(allocator, unspaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const event_time = result.data.?.object.get("event_time");
        try std.testing.expect(event_time != null);
        try std.testing.expect(event_time.? == .date);
    }
}

test "parse: multiple consecutive comments" {
    const allocator = std.testing.allocator;
    const input =
        \\# First comment
        \\# Second comment
        \\# Third comment
        \\{
        \\  name: "Alice"
        \\}
    ;

    // Test original input
    {
        var result = parse(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const name = result.data.?.object.get("name");
        try std.testing.expect(name != null);
        try std.testing.expect(std.mem.eql(u8, name.?.string, "Alice"));
    }

    // Test spaced input
    {
        const spaced = try spaceUnspace.space(allocator, input);
        defer allocator.free(spaced);
        var result = parse(allocator, spaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const name = result.data.?.object.get("name");
        try std.testing.expect(name != null);
        try std.testing.expect(std.mem.eql(u8, name.?.string, "Alice"));
    }

    // Test unspaced input
    {
        const unspaced = try spaceUnspace.unspace(allocator, input);
        defer allocator.free(unspaced);
        var result = parse(allocator, unspaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const name = result.data.?.object.get("name");
        try std.testing.expect(name != null);
        try std.testing.expect(std.mem.eql(u8, name.?.string, "Alice"));
    }
}

test "parse: inline comments" {
    const allocator = std.testing.allocator;
    const input = "{name: \"Bob\", # inline comment\nage: 30}";

    // Test original input
    {
        var result = parse(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const name = result.data.?.object.get("name");
        try std.testing.expect(name != null);
        try std.testing.expect(std.mem.eql(u8, name.?.string, "Bob"));
        const age = result.data.?.object.get("age");
        try std.testing.expect(age != null);
        try std.testing.expect(age.?.int == 30);
    }

    // Test spaced input
    {
        const spaced = try spaceUnspace.space(allocator, input);
        defer allocator.free(spaced);
        var result = parse(allocator, spaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const name = result.data.?.object.get("name");
        try std.testing.expect(name != null);
        try std.testing.expect(std.mem.eql(u8, name.?.string, "Bob"));
        const age = result.data.?.object.get("age");
        try std.testing.expect(age != null);
        try std.testing.expect(age.?.int == 30);
    }

    // Test unspaced input
    {
        const unspaced = try spaceUnspace.unspace(allocator, input);
        defer allocator.free(unspaced);
        var result = parse(allocator, unspaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const name = result.data.?.object.get("name");
        try std.testing.expect(name != null);
        try std.testing.expect(std.mem.eql(u8, name.?.string, "Bob"));
        const age = result.data.?.object.get("age");
        try std.testing.expect(age != null);
        try std.testing.expect(age.?.int == 30);
    }
}

test "parse: comments between fields" {
    const allocator = std.testing.allocator;
    const input = "{name: \"Alice\", # name field\n# separator\nage: 25 # age field\n}";

    // Test original input
    {
        var result = parse(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const name = result.data.?.object.get("name");
        try std.testing.expect(name != null);
        try std.testing.expect(std.mem.eql(u8, name.?.string, "Alice"));
        const age = result.data.?.object.get("age");
        try std.testing.expect(age != null);
        try std.testing.expect(age.?.int == 25);
    }

    // Test spaced input
    {
        const spaced = try spaceUnspace.space(allocator, input);
        defer allocator.free(spaced);
        var result = parse(allocator, spaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const name = result.data.?.object.get("name");
        try std.testing.expect(name != null);
        try std.testing.expect(std.mem.eql(u8, name.?.string, "Alice"));
        const age = result.data.?.object.get("age");
        try std.testing.expect(age != null);
        try std.testing.expect(age.?.int == 25);
    }

    // Test unspaced input
    {
        const unspaced = try spaceUnspace.unspace(allocator, input);
        defer allocator.free(unspaced);
        var result = parse(allocator, unspaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const name = result.data.?.object.get("name");
        try std.testing.expect(name != null);
        try std.testing.expect(std.mem.eql(u8, name.?.string, "Alice"));
        const age = result.data.?.object.get("age");
        try std.testing.expect(age != null);
        try std.testing.expect(age.?.int == 25);
    }
}

test "parse: deeply nested structures" {
    const allocator = std.testing.allocator;
    const input =
        \\{
        \\  level1: {
        \\    level2: {
        \\      level3: {
        \\        deep: "value"
        \\      }
        \\    }
        \\  },
        \\  nested_array: [[[1, 2], [3, 4]], [[5, 6], [7, 8]]]
        \\}
    ;

    // Test original input
    {
        var result = parse(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const level1 = result.data.?.object.get("level1");
        try std.testing.expect(level1 != null);
        try std.testing.expect(level1.? == .object);
        const nested_array = result.data.?.object.get("nested_array");
        try std.testing.expect(nested_array != null);
        try std.testing.expect(nested_array.? == .array);
        try std.testing.expect(nested_array.?.array.items.len == 2);
    }

    // Test spaced input
    {
        const spaced = try spaceUnspace.space(allocator, input);
        defer allocator.free(spaced);
        var result = parse(allocator, spaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const level1 = result.data.?.object.get("level1");
        try std.testing.expect(level1 != null);
        try std.testing.expect(level1.? == .object);
        const nested_array = result.data.?.object.get("nested_array");
        try std.testing.expect(nested_array != null);
        try std.testing.expect(nested_array.? == .array);
        try std.testing.expect(nested_array.?.array.items.len == 2);
    }

    // Test unspaced input
    {
        const unspaced = try spaceUnspace.unspace(allocator, input);
        defer allocator.free(unspaced);
        var result = parse(allocator, unspaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const level1 = result.data.?.object.get("level1");
        try std.testing.expect(level1 != null);
        try std.testing.expect(level1.? == .object);
        const nested_array = result.data.?.object.get("nested_array");
        try std.testing.expect(nested_array != null);
        try std.testing.expect(nested_array.? == .array);
        try std.testing.expect(nested_array.?.array.items.len == 2);
    }
}

test "parse: single field object" {
    const allocator = std.testing.allocator;
    const input = "{name: \"Alice\"}";

    // Test original input
    {
        var result = parse(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const name = result.data.?.object.get("name");
        try std.testing.expect(name != null);
        try std.testing.expect(std.mem.eql(u8, name.?.string, "Alice"));
    }

    // Test spaced input
    {
        const spaced = try spaceUnspace.space(allocator, input);
        defer allocator.free(spaced);
        var result = parse(allocator, spaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const name = result.data.?.object.get("name");
        try std.testing.expect(name != null);
        try std.testing.expect(std.mem.eql(u8, name.?.string, "Alice"));
    }

    // Test unspaced input
    {
        const unspaced = try spaceUnspace.unspace(allocator, input);
        defer allocator.free(unspaced);
        var result = parse(allocator, unspaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.data.? == .object);
        const name = result.data.?.object.get("name");
        try std.testing.expect(name != null);
        try std.testing.expect(std.mem.eql(u8, name.?.string, "Alice"));
    }
}

fn expectLargeDataset(result: anytype) !void {
    try std.testing.expect(result == .object);
    try std.testing.expect(result.object.count() == 3);

    const users = result.object.get("users");
    try std.testing.expect(users != null);
    try std.testing.expect(users.? == .array);
    try std.testing.expect(users.?.array.items.len == 5);

    const stats = result.object.get("stats");
    try std.testing.expect(stats != null);
    try std.testing.expect(stats.? == .object);

    const metadata = result.object.get("metadata");
    try std.testing.expect(metadata != null);
    try std.testing.expect(metadata.? == .object);
}

test "parse: large dataset" {
    const allocator = std.testing.allocator;
    const input =
        \\{
        \\  users: [
        \\    { id: 1, name: "Alice", active: true },
        \\    { id: 2, name: "Bob", active: false },
        \\    { id: 3, name: "Charlie", active: true },
        \\    { id: 4, name: "Diana", active: true },
        \\    { id: 5, name: "Eve", active: false }
        \\  ],
        \\  stats: {
        \\    total: 5,
        \\    active: 3,
        \\    inactive: 2,
        \\    rating: 4.5
        \\  },
        \\  metadata: {
        \\    created_at: 2025-01-01,
        \\    updated_at: 2025-01-15T10:30:00,
        \\    tags: ["production", "api", "v1"]
        \\  }
        \\}
    ;

    // Test original input
    {
        var result = parse(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try expectLargeDataset(result.data.?);
    }

    // Test spaced input (with time fix)
    {
        const spaced = try spaceUnspace.space(allocator, input);
        defer allocator.free(spaced);
        const fixed = try spaceUnspace.replaceAll(allocator, spaced, "10 : 30 : 00", "10:30:00");
        defer allocator.free(fixed);
        var result = parse(allocator, fixed);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try expectLargeDataset(result.data.?);
    }

    // Test unspaced input
    {
        const unspaced = try spaceUnspace.unspace(allocator, input);
        defer allocator.free(unspaced);
        var result = parse(allocator, unspaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try expectLargeDataset(result.data.?);
    }
}
