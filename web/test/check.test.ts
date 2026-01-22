import { expect, test } from "vitest";
import check from "../src/check";
import parse from "../src/parse";
import parseSchema from "../src/parseSchema";

test("check: null type valid", () => {
	const schemaInput = `{ meeting_at: null | date }`;
	const input = `{ meeting_at: null }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: bool type valid", () => {
	const schemaInput = `{ is_active: bool }`;
	const input = `{ is_active: true }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: bool type invalid", () => {
	const schemaInput = `{ is_active: bool }`;
	const input = `{ is_active: 1 }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(false);
	if (result.ok === false) {
		expect(result.errors.length).toBe(1);
		expect(result.errors[0].message).toBe("'is_active' must be a boolean value");
	}
});

test("check: int type valid", () => {
	const schemaInput = `{ age: int }`;
	const input = `{ age: 25 }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: int type invalid", () => {
	const schemaInput = `{ age: int }`;
	const input = `{ age: 25.5 }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(false);
	if (result.ok === false) {
		expect(result.errors.length).toBe(1);
		expect(result.errors[0].message).toBe("'age' must be an integer value");
	}
});

test("check: num type valid", () => {
	const schemaInput = `{ rating: num }`;
	const input = `{ rating: 4.5 }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: num type invalid", () => {
	const schemaInput = `{ rating: num }`;
	const input = `{ rating: "excellent" }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(false);
	if (result.ok === false) {
		expect(result.errors.length).toBe(1);
		expect(result.errors[0].message).toBe("'rating' must be a number value");
	}
});

test("check: date type valid", () => {
	const schemaInput = `{ birthday: date }`;
	const input = `{ birthday: 2025-01-15 }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: date type invalid", () => {
	const schemaInput = `{ birthday: date }`;
	const input = `{ birthday: "2025-01-15" }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(false);
	if (result.ok === false) {
		expect(result.errors.length).toBe(1);
		expect(result.errors[0].message).toBe("'birthday' must be a date value");
	}
});

test("check: string type valid", () => {
	const schemaInput = `{ name: string }`;
	const input = `{ name: "Alice" }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: string type invalid", () => {
	const schemaInput = `{ name: string }`;
	const input = `{ name: 123 }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(false);
	if (result.ok === false) {
		expect(result.errors.length).toBe(1);
		expect(result.errors[0].message).toBe("'name' must be a string value");
	}
});

test("check: int union", () => {
	const schemaInput = `{ age: 15 | 16 | 17 }`;
	const input = `{ age: 22 }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(false);
	if (result.ok === false) {
		expect(result.errors.length).toBe(1);
		expect(result.errors[0].message).toBe(
			"'age' must be '15' | 'age' must be '16' | 'age' must be '17'",
		);
	}
});

test("check: int min validator valid", () => {
	const schemaInput = `{ age: int min(18) }`;
	const input = `{ age: 20 }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: int min validator invalid", () => {
	const schemaInput = `{ age: int min(18) }`;
	const input = `{ age: 15 }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(false);
	if (result.ok === false) {
		expect(result.errors.length).toBe(1);
		expect(result.errors[0].message).toBe("'age' must be at least 18");
	}
});

test("check: int max validator valid", () => {
	const schemaInput = `{ age: int max(100) }`;
	const input = `{ age: 50 }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: int max validator invalid", () => {
	const schemaInput = `{ age: int max(100) }`;
	const input = `{ age: 120 }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(false);
	if (result.ok === false) {
		expect(result.errors.length).toBe(1);
		expect(result.errors[0].message).toBe("'age' cannot be more than 100");
	}
});

test("check: num min validator valid", () => {
	const schemaInput = `{ rating: num min(0) }`;
	const input = `{ rating: 4.5 }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: num min validator invalid", () => {
	const schemaInput = `{ rating: num min(0) }`;
	const input = `{ rating: -0.5 }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(false);
	if (result.ok === false) {
		expect(result.errors.length).toBe(1);
		expect(result.errors[0].message).toBe("'rating' must be at least 0");
	}
});

test("check: num max validator valid", () => {
	const schemaInput = `{ rating: num max(5) }`;
	const input = `{ rating: 4.5 }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: num max validator invalid", () => {
	const schemaInput = `{ rating: num max(5) }`;
	const input = `{ rating: 5.5 }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(false);
	if (result.ok === false) {
		expect(result.errors.length).toBe(1);
		expect(result.errors[0].message).toBe("'rating' cannot be more than 5");
	}
});

test("check: field not found", () => {
	const schemaInput = `{ name: string, age: int }`;
	const input = `{ name: "Alice" }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(false);
	if (result.ok === false) {
		expect(result.errors.length).toBe(1);
		expect(result.errors[0].message).toBe("Field not found: age");
	}
});

test("check: multiple fields valid", () => {
	const schemaInput = `{ name: string, age: int, is_active: bool }`;
	const input = `{ name: "Alice", age: 25, is_active: true }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: multiple fields invalid", () => {
	const schemaInput = `{ name: string, age: int, is_active: bool }`;
	const input = `{ name: "Alice", age: 25.5, is_active: "yes" }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(false);
	if (result.ok === false) {
		expect(result.errors.length).toBe(2);
	}
});

test("check: array valid", () => {
	const schemaInput = `{ fruits: [string] }`;
	const input = `{ fruits: ["apple", "banana"] }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: array invalid", () => {
	const schemaInput = `{ fruits: [string] }`;
	const input = `{ fruits: ["apple", 5] }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(false);
	if (result.ok === false) {
		expect(result.errors.length).toBe(1);
		expect(result.errors[0].message).toBe("'1' must be a string value");
	}
});

test("check: nested object valid", () => {
	const schemaInput = `{ child: { is_active: bool } }`;
	const input = `{ child: { is_active: true } }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: nested object invalid", () => {
	const schemaInput = `{ child: { is_active: bool } }`;
	const input = `{ child: { is_active: 1 } }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(false);
	if (result.ok === false) {
		expect(result.errors.length).toBe(1);
		expect(result.errors[0].message).toBe("'is_active' must be a boolean value");
	}
});

test("check: nested array valid", () => {
	const schemaInput = `{ points: [[ int ]] }`;
	const input = `{ points: [[0, 1], [1, 2]] }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: nested array invalid", () => {
	const schemaInput = `{ points: [[ int ]] }`;
	const input = `{ points: [[0, 1], ["one", "two"]] }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(false);
	if (result.ok === false) {
		expect(result.errors.length).toBe(2);
		expect(result.errors[0].message).toBe("'0' must be an integer value");
		expect(result.errors[1].message).toBe("'1' must be an integer value");
	}
});

test("check: object in array valid", () => {
	const schemaInput = `{ children: [ { name: string, age: int }] }`;
	const input = `{ children: [ { name: "Child A", age: 12 }] }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: object in array invalid", () => {
	const schemaInput = `{ children: [ { name: string, age: int }] }`;
	const input = `{ children: [ { name: 12, age: 12 }] }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(false);
	if (result.ok === false) {
		expect(result.errors.length).toBe(1);
		expect(result.errors[0].message).toBe("'name' must be a string value");
	}
});

test("check: union type valid first", () => {
	const schemaInput = `{ value: string | int }`;
	const input = `{ value: "hello" }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: union type valid second", () => {
	const schemaInput = `{ value: string | int }`;
	const input = `{ value: 42 }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: union type invalid", () => {
	const schemaInput = `{ value: string | int }`;
	const input = `{ value: true }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(false);
	if (result.ok === false) {
		expect(result.errors.length).toBe(1);
		expect(result.errors[0].message).toBe(
			"'value' must be a string value | 'value' must be an integer value",
		);
	}
});

test("check: union of three types valid", () => {
	const schemaInput = `{ value: string | int | bool }`;
	const input = `{ value: false }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: union type in array valid", () => {
	const schemaInput = `{ values: [string | int] }`;
	const input = `{ values: ["hello", 45] }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: union type in array invalid", () => {
	const schemaInput = `{ values: [ string | int ] }`;
	const input = `{ values: [ true ] }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(false);
	if (result.ok === false) {
		expect(result.errors.length).toBe(1);
		expect(result.errors[0].message).toBe(
			"'0' must be a string value | '0' must be an integer value",
		);
	}
});

test("check: string min length valid", () => {
	const schemaInput = `{ name: string min(3) }`;
	const input = `{ name: "Alice" }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: string min length invalid", () => {
	const schemaInput = `{ name: string min(3) }`;
	const input = `{ name: "Al" }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(false);
	if (result.ok === false) {
		expect(result.errors.length).toBe(1);
		expect(result.errors[0].message).toBe("'name' must be at least 3 characters");
	}
});

test("check: string max length valid", () => {
	const schemaInput = `{ name: string max(10) }`;
	const input = `{ name: "Alice" }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: string max length invalid", () => {
	const schemaInput = `{ name: string max(5) }`;
	const input = `{ name: "Alexander" }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(false);
	if (result.ok === false) {
		expect(result.errors.length).toBe(1);
		expect(result.errors[0].message).toBe("'name' cannot be more than 5 characters");
	}
});

test("check: string regex valid", () => {
	const schemaInput = `{ email: string regex(/^[^@]+@[^@]+$/) }`;
	const input = `{ email: "user@example.com" }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: string regex invalid", () => {
	const schemaInput = `{ email: string regex(/^[^@]+@[^@]+$/) }`;
	const input = `{ email: "not-an-email" }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(false);
	if (result.ok === false) {
		expect(result.errors.length).toBe(1);
		expect(result.errors[0].message).toBe("'email' doesn't match pattern '/^[^@]+@[^@]+$/'");
	}
});

test("check: date min valid", () => {
	const schemaInput = `{ birthday: date min(2000-01-01) }`;
	const input = `{ birthday: 2005-06-15 }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: date min invalid", () => {
	const schemaInput = `{ birthday: date min(2000-01-01) }`;
	const input = `{ birthday: 1995-06-15 }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(false);
	if (result.ok === false) {
		expect(result.errors.length).toBe(1);
		expect(result.errors[0].message).toBe("'birthday' must be at least 2000-01-01");
	}
});

test("check: date max valid", () => {
	const schemaInput = `{ birthday: date max(2025-01-01) }`;
	const input = `{ birthday: 2020-06-15 }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: date max invalid", () => {
	const schemaInput = `{ birthday: date max(2020-01-01) }`;
	const input = `{ birthday: 2025-06-15 }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(false);
	if (result.ok === false) {
		expect(result.errors.length).toBe(1);
		expect(result.errors[0].message).toBe("'birthday' cannot be after 2020-01-01");
	}
});

test("check: @mix valid first alternative", () => {
	const schemaInput = `{ @mix({ role: "admin", level: int } | { role: "user", plan: string }) }`;
	const input = `{ role: "admin", level: 5 }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: @mix valid second alternative", () => {
	const schemaInput = `{ @mix({ role: "admin", level: int } | { role: "user", plan: string }) }`;
	const input = `{ role: "user", plan: "premium" }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: @mix invalid all alternatives", () => {
	const schemaInput = `{ @mix({ role: "admin", level: int } | { role: "user", plan: string }) }`;
	const input = `{ role: "guest", plan: "free" }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(false);
	if (result.ok === false) {
		expect(result.errors.length).toBe(1);
		expect(result.errors[0].message).toContain(
			"'role' must be 'admin' & Field not found: level | 'role' must be 'user'",
		);
	}
});

test("check: @any no pattern valid", () => {
	const schemaInput = `{ @any(): string }`;
	const input = `{ greeting: "hello", farewell: "goodbye" }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: @any no pattern invalid type", () => {
	const schemaInput = `{ @any(): string }`;
	const input = `{ greeting: "hello", count: 5 }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(false);
});

test("check: @any with pattern valid", () => {
	const schemaInput = `{ @any(/v\\d/): string }`;
	const input = `{ v1: "version 1", v2: "version 2" }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: @any with pattern invalid name", () => {
	const schemaInput = `{ @any(/v\\d/): string }`;
	const input = `{ version1: "version 1", v2: "version 2" }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(false);
	if (result.ok === false) {
		expect(result.errors.length).toBe(1);
		expect(result.errors[0].message).toBe("'version1' name doesn't match pattern '/v\\d/'");
	}
});

test("check: @any with pattern invalid type", () => {
	const schemaInput = `{ @any(/v\\d/): int }`;
	const input = `{ v1: "version 1", v2: "version 2" }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(false);
	if (result.ok === false) {
		expect(result.errors.length).toBe(2);
		expect(result.errors[0].message).toBe("'v1' must be an integer value");
		expect(result.errors[1].message).toBe("'v2' must be an integer value");
	}
});

test("check: multiple validators on int", () => {
	const schemaInput = `{ age: int min(18) max(100) }`;
	const input = `{ age: 25 }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: multiple validators on int invalid min", () => {
	const schemaInput = `{ age: int min(18) max(100) }`;
	const input = `{ age: 15 }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(false);
	if (result.ok === false) {
		expect(result.errors.length).toBe(1);
		expect(result.errors[0].message).toBe("'age' must be at least 18");
	}
});

test("check: multiple validators on int invalid max", () => {
	const schemaInput = `{ age: int min(18) max(100) }`;
	const input = `{ age: 120 }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(false);
	if (result.ok === false) {
		expect(result.errors.length).toBe(1);
		expect(result.errors[0].message).toBe("'age' cannot be more than 100");
	}
});

test("check: multiple validators on string", () => {
	const schemaInput = `{ username: string min(3) max(20) regex(/^[a-z]+$/) }`;
	const input = `{ username: "alice" }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: multiple validators on string invalid min", () => {
	const schemaInput = `{ username: string min(3) max(20) regex(/^[a-z]+$/) }`;
	const input = `{ username: "al" }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(false);
	if (result.ok === false) {
		expect(result.errors.length).toBe(1);
		expect(result.errors[0].message).toBe("'username' must be at least 3 characters");
	}
});

test("check: multiple validators on string invalid regex", () => {
	const schemaInput = `{ username: string min(3) max(20) regex(/^[a-z]+$/) }`;
	const input = `{ username: "Alice123" }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(false);
	if (result.ok === false) {
		expect(result.errors.length).toBe(1);
		expect(result.errors[0].message).toContain("doesn't match pattern");
	}
});

test("check: bool fixed value valid", () => {
	const schemaInput = `{ accepted: true }`;
	const input = `{ accepted: true }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: bool fixed value invalid", () => {
	const schemaInput = `{ accepted: true }`;
	const input = `{ accepted: false }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(false);
	if (result.ok === false) {
		expect(result.errors.length).toBe(1);
		expect(result.errors[0].message).toBe("'accepted' must be 'true'");
	}
});

test("check: empty array valid", () => {
	const schemaInput = `{ items: [string] }`;
	const input = `{ items: [] }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: empty object valid", () => {
	const schemaInput = `{ data: {} }`;
	const input = `{ data: {} }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: deeply nested valid", () => {
	const schemaInput = `{ data: { user: { profile: { name: string, age: int } } } }`;
	const input = `{ data: { user: { profile: { name: "Alice", age: 30 } } } }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: deeply nested invalid", () => {
	const schemaInput = `{ data: { user: { profile: { name: string, age: int } } } }`;
	const input = `{ data: { user: { profile: { name: 123, age: 30 } } } }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(false);
	if (result.ok === false) {
		expect(result.errors.length).toBe(1);
		expect(result.errors[0].message).toBe("'name' must be a string value");
	}
});

test("check: array with nested objects valid", () => {
	const schemaInput = `{ users: [ { name: string, age: int } ] }`;
	const input = `{ users: [ { name: "Alice", age: 30 }, { name: "Bob", age: 25 } ] }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: array with nested objects partial invalid", () => {
	const schemaInput = `{ users: [ { name: string, age: int } ] }`;
	const input = `{ users: [ { name: "Alice", age: 30 }, { name: 45, age: 25 } ] }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(false);
	if (result.ok === false) {
		expect(result.errors.length).toBe(1);
		expect(result.errors[0].message).toBe("'name' must be a string value");
	}
});

test("check: union with array valid", () => {
	const schemaInput = `{ items: string | [string] }`;
	const input = `{ items: ["a", "b"] }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: union with array invalid", () => {
	const schemaInput = `{ items: string | [string] }`;
	const input = `{ items: ["a", 5] }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(false);
	if (result.ok === false) {
		expect(result.errors.length).toBe(1);
		expect(result.errors[0].message).toBe(
			"'items' must be a string value | '1' must be a string value",
		);
	}
});

test("check: union with object valid", () => {
	const schemaInput = `{ item: { name: string } | string }`;
	const input = `{ item: { name: "a" } }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(true);
});

test("check: union with object invalid", () => {
	const schemaInput = `{ item: { name: string } | string }`;
	const input = `{ item: { name: 5 } }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	expect(result.ok).toBe(false);
	if (result.ok === false) {
		expect(result.errors.length).toBe(1);
		expect(result.errors[0].message).toBe(
			"'name' must be a string value | 'item' must be a string value",
		);
	}
});

test("check: undefined field", () => {
	const schemaInput = `{ name: string, age: undef | num }`;
	const input = `{ name: "Harold" } }`;

	const obj = parse(input);
	const schema = parseSchema(schemaInput);
	const result = check(obj, schema);

	if (result.ok === false) expect(result.errors.map((e) => e.message).join(", ")).toBe("");
	expect(result.ok).toBe(true);
});
