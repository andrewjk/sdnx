const std = @import("std");
const sdn = @import("sdn");
const parseSchema = sdn.parseSchema_mod;
const spaceUnspace = @import("spaceUnspace.zig");

test "parse schema: basic test" {
    const allocator = std.testing.allocator;
    const input =
        \\{
        \\  active: bool,
        \\  # a comment
        \\  name: string minlen(2),
        \\  age: int min(16),
        \\  rating: num max(5),
        \\  ## a description of this field
        \\  skills: string,
        \\  started_at: date,
        \\  meeting_at: null | date,
        \\  children: [{
        \\    age: int,
        \\    name: string,
        \\  }],
        \\}
    ;

    {
        var result = parseSchema.parseSchema(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 8);
    }

    // Test spaced input
    const spaced_input = try spaceUnspace.space(allocator, input);
    defer allocator.free(spaced_input);
    {
        var result = parseSchema.parseSchema(allocator, spaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 8);
    }

    // Test unspaced input
    const unspaced_input = try spaceUnspace.unspace(allocator, input);
    defer allocator.free(unspaced_input);
    {
        const fixed_unspaced = try spaceUnspace.applyUnspaceReplacements(allocator, unspaced_input);
        defer allocator.free(fixed_unspaced);
        var result = parseSchema.parseSchema(allocator, fixed_unspaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 8);
    }
}

test "parse schema: simple type" {
    const allocator = std.testing.allocator;

    const input =
        \\{
        \\  name: string,
        \\}
    ;

    // Test original input
    {
        var result = parseSchema.parseSchema(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const name_entry = result.schema.?.get("name");
        try std.testing.expect(name_entry != null);
        try std.testing.expect(name_entry.? == .field);
        try std.testing.expect(std.mem.eql(u8, name_entry.?.field.type, "string"));
    }

    // Test spaced input
    const spaced_input = try spaceUnspace.space(allocator, input);
    defer allocator.free(spaced_input);
    {
        var result = parseSchema.parseSchema(allocator, spaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const name_entry = result.schema.?.get("name");
        try std.testing.expect(name_entry != null);
        try std.testing.expect(name_entry.? == .field);
        try std.testing.expect(std.mem.eql(u8, name_entry.?.field.type, "string"));
    }

    // Test unspaced input
    const unspaced_input = try spaceUnspace.unspace(allocator, input);
    defer allocator.free(unspaced_input);
    {
        var result = parseSchema.parseSchema(allocator, unspaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const name_entry = result.schema.?.get("name");
        try std.testing.expect(name_entry != null);
        try std.testing.expect(name_entry.? == .field);
        try std.testing.expect(std.mem.eql(u8, name_entry.?.field.type, "string"));
    }
}

test "parse schema: type with description" {
    const allocator = std.testing.allocator;

    const input =
        \\{
        \\  ## This is a name
        \\  name: string,
        \\}
    ;

    // Test original input
    {
        var result = parseSchema.parseSchema(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const name_entry = result.schema.?.get("name");
        try std.testing.expect(name_entry != null);
        try std.testing.expect(name_entry.? == .field);
        try std.testing.expect(std.mem.eql(u8, name_entry.?.field.type, "string"));
        try std.testing.expect(name_entry.?.field.description != null);
        try std.testing.expect(std.mem.eql(u8, name_entry.?.field.description.?, "This is a name"));
    }

    // Test spaced input
    const spaced_input = try spaceUnspace.space(allocator, input);
    defer allocator.free(spaced_input);
    {
        var result = parseSchema.parseSchema(allocator, spaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const name_entry = result.schema.?.get("name");
        try std.testing.expect(name_entry != null);
        try std.testing.expect(name_entry.? == .field);
        try std.testing.expect(std.mem.eql(u8, name_entry.?.field.type, "string"));
        try std.testing.expect(name_entry.?.field.description != null);
        try std.testing.expect(std.mem.eql(u8, name_entry.?.field.description.?, "This is a name"));
    }

    // Test unspaced input
    const unspaced_input = try spaceUnspace.unspace(allocator, input);
    defer allocator.free(unspaced_input);
    {
        var result = parseSchema.parseSchema(allocator, unspaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const name_entry = result.schema.?.get("name");
        try std.testing.expect(name_entry != null);
        try std.testing.expect(name_entry.? == .field);
        try std.testing.expect(std.mem.eql(u8, name_entry.?.field.type, "string"));
        try std.testing.expect(name_entry.?.field.description != null);
        try std.testing.expect(std.mem.eql(u8, name_entry.?.field.description.?, "This is a name"));
    }
}

test "parse schema: union type" {
    const allocator = std.testing.allocator;

    const input =
        \\{
        \\  value: string | int,
        \\}
    ;

    // Test original input
    {
        var result = parseSchema.parseSchema(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const value_entry = result.schema.?.get("value");
        try std.testing.expect(value_entry != null);
        try std.testing.expect(value_entry.? == .union_type);
        try std.testing.expect(value_entry.?.union_type.inner.items.len == 2);
    }

    // Test spaced input
    const spaced_input = try spaceUnspace.space(allocator, input);
    defer allocator.free(spaced_input);
    {
        var result = parseSchema.parseSchema(allocator, spaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const value_entry = result.schema.?.get("value");
        try std.testing.expect(value_entry != null);
        try std.testing.expect(value_entry.? == .union_type);
        try std.testing.expect(value_entry.?.union_type.inner.items.len == 2);
    }

    // Test unspaced input
    const unspaced_input = try spaceUnspace.unspace(allocator, input);
    defer allocator.free(unspaced_input);
    {
        var result = parseSchema.parseSchema(allocator, unspaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const value_entry = result.schema.?.get("value");
        try std.testing.expect(value_entry != null);
        try std.testing.expect(value_entry.? == .union_type);
        try std.testing.expect(value_entry.?.union_type.inner.items.len == 2);
    }
}

test "parse schema: type with parameter" {
    const allocator = std.testing.allocator;

    const input =
        \\{
        \\  age: int min(0),
        \\}
    ;

    // Test original input
    {
        var result = parseSchema.parseSchema(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const age_entry = result.schema.?.get("age");
        try std.testing.expect(age_entry != null);
        try std.testing.expect(age_entry.? == .field);
        try std.testing.expect(std.mem.eql(u8, age_entry.?.field.type, "int"));
        try std.testing.expect(age_entry.?.field.validators != null);
    }

    // Test spaced input
    const spaced_input = try spaceUnspace.space(allocator, input);
    defer allocator.free(spaced_input);
    {
        var result = parseSchema.parseSchema(allocator, spaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const age_entry = result.schema.?.get("age");
        try std.testing.expect(age_entry != null);
        try std.testing.expect(age_entry.? == .field);
        try std.testing.expect(std.mem.eql(u8, age_entry.?.field.type, "int"));
        try std.testing.expect(age_entry.?.field.validators != null);
    }

    // Test unspaced input with replacement
    const unspaced_input = try spaceUnspace.unspace(allocator, input);
    defer allocator.free(unspaced_input);
    const fixed_unspaced = try spaceUnspace.applyUnspaceReplacements(allocator, unspaced_input);
    defer allocator.free(fixed_unspaced);
    {
        var result = parseSchema.parseSchema(allocator, fixed_unspaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const age_entry = result.schema.?.get("age");
        try std.testing.expect(age_entry != null);
        try std.testing.expect(age_entry.? == .field);
        try std.testing.expect(std.mem.eql(u8, age_entry.?.field.type, "int"));
        try std.testing.expect(age_entry.?.field.validators != null);
    }
}

test "parse schema: object type" {
    const allocator = std.testing.allocator;

    const input =
        \\{
        \\  dob: { year: int, month: int, day: int }
        \\}
    ;

    // Test original input
    {
        var result = parseSchema.parseSchema(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const dob_entry = result.schema.?.get("dob");
        try std.testing.expect(dob_entry != null);
        try std.testing.expect(dob_entry.? == .object);
        try std.testing.expect(std.mem.eql(u8, dob_entry.?.object.type, "object"));
        try std.testing.expect(dob_entry.?.object.inner.count() == 3);
    }

    // Test spaced input
    const spaced_input = try spaceUnspace.space(allocator, input);
    defer allocator.free(spaced_input);
    {
        var result = parseSchema.parseSchema(allocator, spaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const dob_entry = result.schema.?.get("dob");
        try std.testing.expect(dob_entry != null);
        try std.testing.expect(dob_entry.? == .object);
        try std.testing.expect(std.mem.eql(u8, dob_entry.?.object.type, "object"));
        try std.testing.expect(dob_entry.?.object.inner.count() == 3);
    }

    // Test unspaced input
    const unspaced_input = try spaceUnspace.unspace(allocator, input);
    defer allocator.free(unspaced_input);
    {
        var result = parseSchema.parseSchema(allocator, unspaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const dob_entry = result.schema.?.get("dob");
        try std.testing.expect(dob_entry != null);
        try std.testing.expect(dob_entry.? == .object);
        try std.testing.expect(std.mem.eql(u8, dob_entry.?.object.type, "object"));
        try std.testing.expect(dob_entry.?.object.inner.count() == 3);
    }
}

test "parse schema: array type" {
    const allocator = std.testing.allocator;

    const input =
        \\{
        \\  children: [ string ]
        \\}
    ;

    // Test original input
    {
        var result = parseSchema.parseSchema(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const children_entry = result.schema.?.get("children");
        try std.testing.expect(children_entry != null);
        try std.testing.expect(children_entry.? == .array);
        try std.testing.expect(std.mem.eql(u8, children_entry.?.array.type, "array"));
    }

    // Test spaced input
    const spaced_input = try spaceUnspace.space(allocator, input);
    defer allocator.free(spaced_input);
    {
        var result = parseSchema.parseSchema(allocator, spaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const children_entry = result.schema.?.get("children");
        try std.testing.expect(children_entry != null);
        try std.testing.expect(children_entry.? == .array);
        try std.testing.expect(std.mem.eql(u8, children_entry.?.array.type, "array"));
    }

    // Test unspaced input
    const unspaced_input = try spaceUnspace.unspace(allocator, input);
    defer allocator.free(unspaced_input);
    {
        var result = parseSchema.parseSchema(allocator, unspaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const children_entry = result.schema.?.get("children");
        try std.testing.expect(children_entry != null);
        try std.testing.expect(children_entry.? == .array);
        try std.testing.expect(std.mem.eql(u8, children_entry.?.array.type, "array"));
    }
}

test "parse schema: mix macro" {
    const allocator = std.testing.allocator;

    const input =
        \\{
        \\  name: string minlen(2),
        \\  @mix({
        \\    age: int min(16),
        \\    rating: num max(5),
        \\  }),
        \\  active: bool,
        \\}
    ;

    // Test original input
    {
        var result = parseSchema.parseSchema(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 3);
        const name_entry = result.schema.?.get("name");
        try std.testing.expect(name_entry != null);
        try std.testing.expect(name_entry.? == .field);
        const active_entry = result.schema.?.get("active");
        try std.testing.expect(active_entry != null);
        try std.testing.expect(active_entry.? == .field);
        const mix_entry = result.schema.?.get("mix$1");
        try std.testing.expect(mix_entry != null);
        try std.testing.expect(mix_entry.? == .mix);
    }

    // Test spaced input
    const spaced_input = try spaceUnspace.space(allocator, input);
    defer allocator.free(spaced_input);
    {
        var result = parseSchema.parseSchema(allocator, spaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 3);
        const name_entry = result.schema.?.get("name");
        try std.testing.expect(name_entry != null);
        try std.testing.expect(name_entry.? == .field);
        const active_entry = result.schema.?.get("active");
        try std.testing.expect(active_entry != null);
        try std.testing.expect(active_entry.? == .field);
        const mix_entry = result.schema.?.get("mix$1");
        try std.testing.expect(mix_entry != null);
        try std.testing.expect(mix_entry.? == .mix);
    }

    // Test unspaced input
    const unspaced_input = try spaceUnspace.unspace(allocator, input);
    defer allocator.free(unspaced_input);
    {
        const fixed_input = try spaceUnspace.applyUnspaceReplacements(allocator, unspaced_input);
        defer allocator.free(fixed_input);
        var result = parseSchema.parseSchema(allocator, fixed_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 3);
        const name_entry = result.schema.?.get("name");
        try std.testing.expect(name_entry != null);
        try std.testing.expect(name_entry.? == .field);
        const active_entry = result.schema.?.get("active");
        try std.testing.expect(active_entry != null);
        try std.testing.expect(active_entry.? == .field);
        const mix_entry = result.schema.?.get("mix$1");
        try std.testing.expect(mix_entry != null);
        try std.testing.expect(mix_entry.? == .mix);
    }
}

test "parse schema: any macro" {
    const allocator = std.testing.allocator;

    const input =
        \\{
        \\  name: string minlen(2),
        \\  @any(): int min(16),
        \\  active: bool,
        \\}
    ;

    // Test original input
    {
        var result = parseSchema.parseSchema(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 3);
        const name_entry = result.schema.?.get("name");
        try std.testing.expect(name_entry != null);
        try std.testing.expect(name_entry.? == .field);
        const active_entry = result.schema.?.get("active");
        try std.testing.expect(active_entry != null);
        try std.testing.expect(active_entry.? == .field);
        const any_entry = result.schema.?.get("any$1");
        try std.testing.expect(any_entry != null);
        try std.testing.expect(any_entry.? == .any);
    }

    // Test spaced input
    const spaced_input = try spaceUnspace.space(allocator, input);
    defer allocator.free(spaced_input);
    {
        var result = parseSchema.parseSchema(allocator, spaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 3);
        const name_entry = result.schema.?.get("name");
        try std.testing.expect(name_entry != null);
        try std.testing.expect(name_entry.? == .field);
        const active_entry = result.schema.?.get("active");
        try std.testing.expect(active_entry != null);
        try std.testing.expect(active_entry.? == .field);
        const any_entry = result.schema.?.get("any$1");
        try std.testing.expect(any_entry != null);
        try std.testing.expect(any_entry.? == .any);
    }

    // Test unspaced input
    const unspaced_input = try spaceUnspace.unspace(allocator, input);
    defer allocator.free(unspaced_input);
    {
        const fixed_input = try spaceUnspace.applyUnspaceReplacements(allocator, unspaced_input);
        defer allocator.free(fixed_input);
        var result = parseSchema.parseSchema(allocator, fixed_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 3);
        const name_entry = result.schema.?.get("name");
        try std.testing.expect(name_entry != null);
        try std.testing.expect(name_entry.? == .field);
        const active_entry = result.schema.?.get("active");
        try std.testing.expect(active_entry != null);
        try std.testing.expect(active_entry.? == .field);
        const any_entry = result.schema.?.get("any$1");
        try std.testing.expect(any_entry != null);
        try std.testing.expect(any_entry.? == .any);
    }
}

test "parse schema: any macro with pattern" {
    const allocator = std.testing.allocator;

    const input =
        \\{
        \\  @any(/v\d/): string,
        \\}
    ;

    // Test original input
    {
        var result = parseSchema.parseSchema(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const any_entry = result.schema.?.get("any$1");
        try std.testing.expect(any_entry != null);
        try std.testing.expect(any_entry.? == .any);
        try std.testing.expect(std.mem.eql(u8, any_entry.?.any.type, "/v\\d/"));
    }

    // Test spaced input
    const spaced_input = try spaceUnspace.space(allocator, input);
    defer allocator.free(spaced_input);
    {
        var result = parseSchema.parseSchema(allocator, spaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const any_entry = result.schema.?.get("any$1");
        try std.testing.expect(any_entry != null);
        try std.testing.expect(any_entry.? == .any);
        try std.testing.expect(std.mem.eql(u8, any_entry.?.any.type, "/v\\d/"));
    }

    // Test unspaced input
    const unspaced_input = try spaceUnspace.unspace(allocator, input);
    defer allocator.free(unspaced_input);
    {
        var result = parseSchema.parseSchema(allocator, unspaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const any_entry = result.schema.?.get("any$1");
        try std.testing.expect(any_entry != null);
        try std.testing.expect(any_entry.? == .any);
        try std.testing.expect(std.mem.eql(u8, any_entry.?.any.type, "/v\\d/"));
    }
}

test "parse schema: type with multiple parameters" {
    const allocator = std.testing.allocator;

    const input =
        \\{
        \\  rating: num min(0) max(5),
        \\}
    ;

    // Test original input
    {
        var result = parseSchema.parseSchema(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const rating_entry = result.schema.?.get("rating");
        try std.testing.expect(rating_entry != null);
        try std.testing.expect(rating_entry.? == .field);
        try std.testing.expect(std.mem.eql(u8, rating_entry.?.field.type, "num"));
        try std.testing.expect(rating_entry.?.field.validators != null);
        try std.testing.expect(rating_entry.?.field.validators.?.count() == 2);
    }

    // Test spaced input
    const spaced_input = try spaceUnspace.space(allocator, input);
    defer allocator.free(spaced_input);
    {
        var result = parseSchema.parseSchema(allocator, spaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const rating_entry = result.schema.?.get("rating");
        try std.testing.expect(rating_entry != null);
        try std.testing.expect(rating_entry.? == .field);
        try std.testing.expect(std.mem.eql(u8, rating_entry.?.field.type, "num"));
        try std.testing.expect(rating_entry.?.field.validators != null);
        try std.testing.expect(rating_entry.?.field.validators.?.count() == 2);
    }

    // Test unspaced input with replacements
    const unspaced_input = try spaceUnspace.unspace(allocator, input);
    defer allocator.free(unspaced_input);
    const fixed_unspaced = try spaceUnspace.applyUnspaceReplacements(allocator, unspaced_input);
    defer allocator.free(fixed_unspaced);
    {
        var result = parseSchema.parseSchema(allocator, fixed_unspaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const rating_entry = result.schema.?.get("rating");
        try std.testing.expect(rating_entry != null);
        try std.testing.expect(rating_entry.? == .field);
        try std.testing.expect(std.mem.eql(u8, rating_entry.?.field.type, "num"));
        try std.testing.expect(rating_entry.?.field.validators != null);
        try std.testing.expect(rating_entry.?.field.validators.?.count() == 2);
    }
}

test "parse schema: nested object" {
    const allocator = std.testing.allocator;

    const input =
        \\{
        \\  address: {
        \\    street: string,
        \\    city: string,
        \\    zip: string,
        \\  },
        \\}
    ;

    // Test original input
    {
        var result = parseSchema.parseSchema(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const address_entry = result.schema.?.get("address");
        try std.testing.expect(address_entry != null);
        try std.testing.expect(address_entry.? == .object);
        try std.testing.expect(std.mem.eql(u8, address_entry.?.object.type, "object"));
        try std.testing.expect(address_entry.?.object.inner.count() == 3);
    }

    // Test spaced input
    const spaced_input = try spaceUnspace.space(allocator, input);
    defer allocator.free(spaced_input);
    {
        var result = parseSchema.parseSchema(allocator, spaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const address_entry = result.schema.?.get("address");
        try std.testing.expect(address_entry != null);
        try std.testing.expect(address_entry.? == .object);
        try std.testing.expect(std.mem.eql(u8, address_entry.?.object.type, "object"));
        try std.testing.expect(address_entry.?.object.inner.count() == 3);
    }

    // Test unspaced input
    const unspaced_input = try spaceUnspace.unspace(allocator, input);
    defer allocator.free(unspaced_input);
    {
        var result = parseSchema.parseSchema(allocator, unspaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const address_entry = result.schema.?.get("address");
        try std.testing.expect(address_entry != null);
        try std.testing.expect(address_entry.? == .object);
        try std.testing.expect(std.mem.eql(u8, address_entry.?.object.type, "object"));
        try std.testing.expect(address_entry.?.object.inner.count() == 3);
    }
}

test "parse schema: array of objects" {
    const allocator = std.testing.allocator;

    const input =
        \\{
        \\  items: [{ id: int, name: string }],
        \\}
    ;

    // Test original input
    {
        var result = parseSchema.parseSchema(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const items_entry = result.schema.?.get("items");
        try std.testing.expect(items_entry != null);
        try std.testing.expect(items_entry.? == .array);
        try std.testing.expect(items_entry.?.array.inner.* == .object);
    }

    // Test spaced input
    const spaced_input = try spaceUnspace.space(allocator, input);
    defer allocator.free(spaced_input);
    {
        var result = parseSchema.parseSchema(allocator, spaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const items_entry = result.schema.?.get("items");
        try std.testing.expect(items_entry != null);
        try std.testing.expect(items_entry.? == .array);
        try std.testing.expect(items_entry.?.array.inner.* == .object);
    }

    // Test unspaced input
    const unspaced_input = try spaceUnspace.unspace(allocator, input);
    defer allocator.free(unspaced_input);
    {
        var result = parseSchema.parseSchema(allocator, unspaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const items_entry = result.schema.?.get("items");
        try std.testing.expect(items_entry != null);
        try std.testing.expect(items_entry.? == .array);
        try std.testing.expect(items_entry.?.array.inner.* == .object);
    }
}

test "parse schema: array of arrays" {
    const allocator = std.testing.allocator;

    const input =
        \\{
        \\  matrix: [[ int ]],
        \\}
    ;

    // Test original input
    {
        var result = parseSchema.parseSchema(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const matrix_entry = result.schema.?.get("matrix");
        try std.testing.expect(matrix_entry != null);
        try std.testing.expect(matrix_entry.? == .array);
        try std.testing.expect(matrix_entry.?.array.inner.* == .array);
    }

    // Test spaced input
    const spaced_input = try spaceUnspace.space(allocator, input);
    defer allocator.free(spaced_input);
    {
        var result = parseSchema.parseSchema(allocator, spaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const matrix_entry = result.schema.?.get("matrix");
        try std.testing.expect(matrix_entry != null);
        try std.testing.expect(matrix_entry.? == .array);
        try std.testing.expect(matrix_entry.?.array.inner.* == .array);
    }

    // Test unspaced input
    const unspaced_input = try spaceUnspace.unspace(allocator, input);
    defer allocator.free(unspaced_input);
    {
        var result = parseSchema.parseSchema(allocator, unspaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const matrix_entry = result.schema.?.get("matrix");
        try std.testing.expect(matrix_entry != null);
        try std.testing.expect(matrix_entry.? == .array);
        try std.testing.expect(matrix_entry.?.array.inner.* == .array);
    }
}

test "parse schema: union of three types" {
    const allocator = std.testing.allocator;

    const input =
        \\{
        \\  value: string | int | bool,
        \\}
    ;

    // Test original input
    {
        var result = parseSchema.parseSchema(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const value_entry = result.schema.?.get("value");
        try std.testing.expect(value_entry != null);
        try std.testing.expect(value_entry.? == .union_type);
        try std.testing.expect(value_entry.?.union_type.inner.items.len == 3);
    }

    // Test spaced input
    const spaced_input = try spaceUnspace.space(allocator, input);
    defer allocator.free(spaced_input);
    {
        var result = parseSchema.parseSchema(allocator, spaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const value_entry = result.schema.?.get("value");
        try std.testing.expect(value_entry != null);
        try std.testing.expect(value_entry.? == .union_type);
        try std.testing.expect(value_entry.?.union_type.inner.items.len == 3);
    }

    // Test unspaced input
    const unspaced_input = try spaceUnspace.unspace(allocator, input);
    defer allocator.free(unspaced_input);
    {
        var result = parseSchema.parseSchema(allocator, unspaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const value_entry = result.schema.?.get("value");
        try std.testing.expect(value_entry != null);
        try std.testing.expect(value_entry.? == .union_type);
        try std.testing.expect(value_entry.?.union_type.inner.items.len == 3);
    }
}

test "parse schema: multiple mix macros" {
    const allocator = std.testing.allocator;

    const input =
        \\{
        \\  @mix({
        \\    role: "admin",
        \\    level: int min(1),
        \\  }),
        \\  @mix({
        \\    role: "user",
        \\    plan: string,
        \\  }),
        \\}
    ;

    // Test original input
    {
        var result = parseSchema.parseSchema(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 2);
        const mix1_entry = result.schema.?.get("mix$1");
        try std.testing.expect(mix1_entry != null);
        try std.testing.expect(mix1_entry.? == .mix);
        const mix2_entry = result.schema.?.get("mix$2");
        try std.testing.expect(mix2_entry != null);
        try std.testing.expect(mix2_entry.? == .mix);
    }

    // Test spaced input
    const spaced_input = try spaceUnspace.space(allocator, input);
    defer allocator.free(spaced_input);
    {
        var result = parseSchema.parseSchema(allocator, spaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 2);
        const mix1_entry = result.schema.?.get("mix$1");
        try std.testing.expect(mix1_entry != null);
        try std.testing.expect(mix1_entry.? == .mix);
        const mix2_entry = result.schema.?.get("mix$2");
        try std.testing.expect(mix2_entry != null);
        try std.testing.expect(mix2_entry.? == .mix);
    }

    // Test unspaced input with replacement
    const unspaced_input = try spaceUnspace.unspace(allocator, input);
    defer allocator.free(unspaced_input);
    const fixed_unspaced = try spaceUnspace.applyUnspaceReplacements(allocator, unspaced_input);
    defer allocator.free(fixed_unspaced);
    {
        var result = parseSchema.parseSchema(allocator, fixed_unspaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 2);
        const mix1_entry = result.schema.?.get("mix$1");
        try std.testing.expect(mix1_entry != null);
        try std.testing.expect(mix1_entry.? == .mix);
        const mix2_entry = result.schema.?.get("mix$2");
        try std.testing.expect(mix2_entry != null);
        try std.testing.expect(mix2_entry.? == .mix);
    }
}

test "parse schema: mix with multiple alternatives" {
    const allocator = std.testing.allocator;

    const input =
        \\{
        \\  @mix({
        \\    minor: false
        \\  } | {
        \\    minor: true,
        \\    guardian: string
        \\  } | {
        \\    minor: true,
        \\    age: int min(18)
        \\  }),
        \\}
    ;

    // Test original input
    {
        var result = parseSchema.parseSchema(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const mix_entry = result.schema.?.get("mix$1");
        try std.testing.expect(mix_entry != null);
        try std.testing.expect(mix_entry.? == .mix);
        try std.testing.expect(mix_entry.?.mix.inner.items.len == 3);
    }

    // Test spaced input with replacement
    const spaced_input = try spaceUnspace.space(allocator, input);
    defer allocator.free(spaced_input);
    {
        var result = parseSchema.parseSchema(allocator, spaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const mix_entry = result.schema.?.get("mix$1");
        try std.testing.expect(mix_entry != null);
        try std.testing.expect(mix_entry.? == .mix);
        try std.testing.expect(mix_entry.?.mix.inner.items.len == 3);
    }

    // Test unspaced input with replacement
    const unspaced_input = try spaceUnspace.unspace(allocator, input);
    defer allocator.free(unspaced_input);
    const fixed_unspaced = try spaceUnspace.applyUnspaceReplacements(allocator, unspaced_input);
    defer allocator.free(fixed_unspaced);
    {
        var result = parseSchema.parseSchema(allocator, fixed_unspaced);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const mix_entry = result.schema.?.get("mix$1");
        try std.testing.expect(mix_entry != null);
        try std.testing.expect(mix_entry.? == .mix);
        try std.testing.expect(mix_entry.?.mix.inner.items.len == 3);
    }
}

test "parse schema: empty object" {
    const allocator = std.testing.allocator;

    const input = "{}";

    // Test original input
    {
        var result = parseSchema.parseSchema(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 0);
    }

    // Test spaced input
    const spaced_input = try spaceUnspace.space(allocator, input);
    defer allocator.free(spaced_input);
    {
        var result = parseSchema.parseSchema(allocator, spaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 0);
    }

    // Test unspaced input
    const unspaced_input = try spaceUnspace.unspace(allocator, input);
    defer allocator.free(unspaced_input);
    {
        var result = parseSchema.parseSchema(allocator, unspaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 0);
    }
}

test "parse schema: array with union type" {
    const allocator = std.testing.allocator;

    const input =
        \\{
        \\  values: [ string | int ],
        \\}
    ;

    // Test original input
    {
        var result = parseSchema.parseSchema(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const values_entry = result.schema.?.get("values");
        try std.testing.expect(values_entry != null);
        try std.testing.expect(values_entry.? == .array);
        try std.testing.expect(values_entry.?.array.inner.* == .union_type);
    }

    // Test spaced input
    const spaced_input = try spaceUnspace.space(allocator, input);
    defer allocator.free(spaced_input);
    {
        var result = parseSchema.parseSchema(allocator, spaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const values_entry = result.schema.?.get("values");
        try std.testing.expect(values_entry != null);
        try std.testing.expect(values_entry.? == .array);
        try std.testing.expect(values_entry.?.array.inner.* == .union_type);
    }

    // Test unspaced input
    const unspaced_input = try spaceUnspace.unspace(allocator, input);
    defer allocator.free(unspaced_input);
    {
        var result = parseSchema.parseSchema(allocator, unspaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const values_entry = result.schema.?.get("values");
        try std.testing.expect(values_entry != null);
        try std.testing.expect(values_entry.? == .array);
        try std.testing.expect(values_entry.?.array.inner.* == .union_type);
    }
}

test "parse schema: union with array first" {
    const allocator = std.testing.allocator;

    const input =
        \\{
        \\  values: [ string ] | string,
        \\}
    ;

    // Test original input
    {
        var result = parseSchema.parseSchema(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const values_entry = result.schema.?.get("values");
        try std.testing.expect(values_entry != null);
        try std.testing.expect(values_entry.? == .union_type);
        try std.testing.expect(values_entry.?.union_type.inner.items.len == 2);
    }

    // Test spaced input
    const spaced_input = try spaceUnspace.space(allocator, input);
    defer allocator.free(spaced_input);
    {
        var result = parseSchema.parseSchema(allocator, spaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const values_entry = result.schema.?.get("values");
        try std.testing.expect(values_entry != null);
        try std.testing.expect(values_entry.? == .union_type);
        try std.testing.expect(values_entry.?.union_type.inner.items.len == 2);
    }

    // Test unspaced input
    const unspaced_input = try spaceUnspace.unspace(allocator, input);
    defer allocator.free(unspaced_input);
    {
        var result = parseSchema.parseSchema(allocator, unspaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const values_entry = result.schema.?.get("values");
        try std.testing.expect(values_entry != null);
        try std.testing.expect(values_entry.? == .union_type);
        try std.testing.expect(values_entry.?.union_type.inner.items.len == 2);
    }
}

test "parse schema: union with array second" {
    const allocator = std.testing.allocator;

    const input =
        \\{
        \\  values: string | [ string ],
        \\}
    ;

    // Test original input
    {
        var result = parseSchema.parseSchema(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const values_entry = result.schema.?.get("values");
        try std.testing.expect(values_entry != null);
        try std.testing.expect(values_entry.? == .union_type);
        try std.testing.expect(values_entry.?.union_type.inner.items.len == 2);
    }

    // Test spaced input
    const spaced_input = try spaceUnspace.space(allocator, input);
    defer allocator.free(spaced_input);
    {
        var result = parseSchema.parseSchema(allocator, spaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const values_entry = result.schema.?.get("values");
        try std.testing.expect(values_entry != null);
        try std.testing.expect(values_entry.? == .union_type);
        try std.testing.expect(values_entry.?.union_type.inner.items.len == 2);
    }

    // Test unspaced input
    const unspaced_input = try spaceUnspace.unspace(allocator, input);
    defer allocator.free(unspaced_input);
    {
        var result = parseSchema.parseSchema(allocator, unspaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const values_entry = result.schema.?.get("values");
        try std.testing.expect(values_entry != null);
        try std.testing.expect(values_entry.? == .union_type);
        try std.testing.expect(values_entry.?.union_type.inner.items.len == 2);
    }
}

test "parse schema: union with object first" {
    const allocator = std.testing.allocator;

    const input =
        \\{
        \\  values: { name: string } | string,
        \\}
    ;

    // Test original input
    {
        var result = parseSchema.parseSchema(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const values_entry = result.schema.?.get("values");
        try std.testing.expect(values_entry != null);
        try std.testing.expect(values_entry.? == .union_type);
        try std.testing.expect(values_entry.?.union_type.inner.items.len == 2);
    }

    // Test spaced input
    const spaced_input = try spaceUnspace.space(allocator, input);
    defer allocator.free(spaced_input);
    {
        var result = parseSchema.parseSchema(allocator, spaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const values_entry = result.schema.?.get("values");
        try std.testing.expect(values_entry != null);
        try std.testing.expect(values_entry.? == .union_type);
        try std.testing.expect(values_entry.?.union_type.inner.items.len == 2);
    }

    // Test unspaced input
    const unspaced_input = try spaceUnspace.unspace(allocator, input);
    defer allocator.free(unspaced_input);
    {
        var result = parseSchema.parseSchema(allocator, unspaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const values_entry = result.schema.?.get("values");
        try std.testing.expect(values_entry != null);
        try std.testing.expect(values_entry.? == .union_type);
        try std.testing.expect(values_entry.?.union_type.inner.items.len == 2);
    }
}

test "parse schema: union with object second" {
    const allocator = std.testing.allocator;

    const input =
        \\{
        \\  values: string | { name: string },
        \\}
    ;

    // Test original input
    {
        var result = parseSchema.parseSchema(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const values_entry = result.schema.?.get("values");
        try std.testing.expect(values_entry != null);
        try std.testing.expect(values_entry.? == .union_type);
        try std.testing.expect(values_entry.?.union_type.inner.items.len == 2);
    }

    // Test spaced input
    const spaced_input = try spaceUnspace.space(allocator, input);
    defer allocator.free(spaced_input);
    {
        var result = parseSchema.parseSchema(allocator, spaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const values_entry = result.schema.?.get("values");
        try std.testing.expect(values_entry != null);
        try std.testing.expect(values_entry.? == .union_type);
        try std.testing.expect(values_entry.?.union_type.inner.items.len == 2);
    }

    // Test unspaced input
    const unspaced_input = try spaceUnspace.unspace(allocator, input);
    defer allocator.free(unspaced_input);
    {
        var result = parseSchema.parseSchema(allocator, unspaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const values_entry = result.schema.?.get("values");
        try std.testing.expect(values_entry != null);
        try std.testing.expect(values_entry.? == .union_type);
        try std.testing.expect(values_entry.?.union_type.inner.items.len == 2);
    }
}

test "parse schema: deeply nested structure" {
    const allocator = std.testing.allocator;

    const input =
        \\{
        \\  data: {
        \\    user: {
        \\        profile: {
        \\            name: string,
        \\            contacts: [{ type: string, value: string }],
        \\        },
        \\    },
        \\  },
        \\}
    ;

    // Test original input
    {
        var result = parseSchema.parseSchema(allocator, input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const data_entry = result.schema.?.get("data");
        try std.testing.expect(data_entry != null);
        try std.testing.expect(data_entry.? == .object);
    }

    // Test spaced input
    const spaced_input = try spaceUnspace.space(allocator, input);
    defer allocator.free(spaced_input);
    {
        var result = parseSchema.parseSchema(allocator, spaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const data_entry = result.schema.?.get("data");
        try std.testing.expect(data_entry != null);
        try std.testing.expect(data_entry.? == .object);
    }

    // Test unspaced input
    const unspaced_input = try spaceUnspace.unspace(allocator, input);
    defer allocator.free(unspaced_input);
    {
        var result = parseSchema.parseSchema(allocator, unspaced_input);
        defer result.deinit();
        try std.testing.expect(result.ok);
        try std.testing.expect(result.schema.?.count() == 1);
        const data_entry = result.schema.?.get("data");
        try std.testing.expect(data_entry != null);
        try std.testing.expect(data_entry.? == .object);
    }
}
