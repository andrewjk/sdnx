import { assert, expect, test } from "vitest";
import parse from "../src/parse";
import space from "./space";
import unspace from "./unspace";

test("parse: basic test", () => {
	const input = `
{
	active: true,
	name: "Darren",
	age: 25,
	rating: 4.2,
	# strings can be multiline
	skills: "
		very good at
		  - reading
		  - writing
		  - selling",
	started_at: 2025-01-01,
	meeting_at: 2026-01-01T10:00,
	children: [{
		name: "Rocket",
		age: 5,
	}],
	has_license: true,
	license_num: "112",
}`;

	const expected = {
		active: true,
		name: "Darren",
		age: 25,
		rating: 4.2,
		skills: `very good at
  - reading
  - writing
  - selling`,
		started_at: new Date("2025-01-01"),
		meeting_at: new Date("2026-01-01T10:00"),
		children: [
			{
				name: "Rocket",
				age: 5,
			},
		],
		has_license: true,
		license_num: "112",
	};

	const result = parse(input);
	assert(result.ok, result.ok ? "" : result.errors.map((e) => e.message).join("\n"));
	expect(result.data).toEqual(expected);

	const spacedInput = space(input).replace("10 : 00", "10:00");
	const spacedResult = parse(spacedInput);
	assert(
		spacedResult.ok,
		spacedResult.ok ? "" : spacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input);
	const unspacedResult = parse(unspacedInput);
	assert(
		unspacedResult.ok,
		unspacedResult.ok ? "" : unspacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse: empty object", () => {
	const input = `{}`;
	const expected = {};

	const result = parse(input);
	assert(result.ok, result.ok ? "" : result.errors.map((e) => e.message).join("\n"));
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parse(spacedInput);
	assert(
		spacedResult.ok,
		spacedResult.ok ? "" : spacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input);
	const unspacedResult = parse(unspacedInput);
	assert(
		unspacedResult.ok,
		unspacedResult.ok ? "" : unspacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse: negative numbers", () => {
	const input = `{temp: -10, balance: -3.14}`;
	const expected = { temp: -10, balance: -3.14 };

	const result = parse(input);
	assert(result.ok, result.ok ? "" : result.errors.map((e) => e.message).join("\n"));
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parse(spacedInput);
	assert(
		spacedResult.ok,
		spacedResult.ok ? "" : spacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input);
	const unspacedResult = parse(unspacedInput);
	assert(
		unspacedResult.ok,
		unspacedResult.ok ? "" : unspacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse: positive numbers with plus prefix", () => {
	const input = `{count: +42, score: +4.5}`;
	const expected = { count: 42, score: 4.5 };

	const result = parse(input);
	assert(result.ok, result.ok ? "" : result.errors.map((e) => e.message).join("\n"));
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parse(spacedInput);
	assert(
		spacedResult.ok,
		spacedResult.ok ? "" : spacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input);
	const unspacedResult = parse(unspacedInput);
	assert(
		unspacedResult.ok,
		unspacedResult.ok ? "" : unspacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse: hexadecimal integers", () => {
	const input = `{color: 0xFF00FF, alpha: 0xAB}`;
	const expected = { color: 0xff00ff, alpha: 0xab };

	const result = parse(input);
	assert(result.ok, result.ok ? "" : result.errors.map((e) => e.message).join("\n"));
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parse(spacedInput);
	assert(
		spacedResult.ok,
		spacedResult.ok ? "" : spacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input);
	const unspacedResult = parse(unspacedInput);
	assert(
		unspacedResult.ok,
		unspacedResult.ok ? "" : unspacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse: scientific notation", () => {
	const input = `{distance: 1.5e10, tiny: 1.5e-5}`;
	const expected = { distance: 1.5e10, tiny: 1.5e-5 };

	const result = parse(input);
	assert(result.ok, result.ok ? "" : result.errors.map((e) => e.message).join("\n"));
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parse(spacedInput);
	assert(
		spacedResult.ok,
		spacedResult.ok ? "" : spacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input);
	const unspacedResult = parse(unspacedInput);
	assert(
		unspacedResult.ok,
		unspacedResult.ok ? "" : unspacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse: numbers with underscore separators", () => {
	const input = `{population: 1_000_000, big_number: 1_000_000.123}`;
	const expected = { population: 1_000_000, big_number: 1_000_000.123 };

	const result = parse(input);
	assert(result.ok, result.ok ? "" : result.errors.map((e) => e.message).join("\n"));
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parse(spacedInput);
	assert(
		spacedResult.ok,
		spacedResult.ok ? "" : spacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input);
	const unspacedResult = parse(unspacedInput);
	assert(
		unspacedResult.ok,
		unspacedResult.ok ? "" : unspacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse: string with escaped quotes", () => {
	const input = `{quote: "She said \\"Hello\\""}`;
	const expected = { quote: `She said \\"Hello\\"` };

	const result = parse(input);
	assert(result.ok, result.ok ? "" : result.errors.map((e) => e.message).join("\n"));
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parse(spacedInput);
	assert(
		spacedResult.ok,
		spacedResult.ok ? "" : spacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input);
	const unspacedResult = parse(unspacedInput);
	assert(
		unspacedResult.ok,
		unspacedResult.ok ? "" : unspacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse: multiline string", () => {
	const input = `
{
	# strings can be multiline
	skills: "
		very good at
		  - reading
		  - writing
		  - selling",
}`;

	const expected = {
		skills: `very good at
  - reading
  - writing
  - selling`,
	};

	const result = parse(input);
	assert(result.ok, result.ok ? "" : result.errors.map((e) => e.message).join("\n"));
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parse(spacedInput);
	assert(
		spacedResult.ok,
		spacedResult.ok ? "" : spacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input);
	const unspacedResult = parse(unspacedInput);
	assert(
		unspacedResult.ok,
		unspacedResult.ok ? "" : unspacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse: quoted field name", () => {
	const input = `{"field-with-dash": "value", "with spaces": "test"}`;
	const expected = {
		'"field-with-dash"': "value",
		'"with spaces"': "test",
	};

	const result = parse(input);
	assert(result.ok, result.ok ? "" : result.errors.map((e) => e.message).join("\n"));
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parse(spacedInput);
	assert(
		spacedResult.ok,
		spacedResult.ok ? "" : spacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input);
	const unspacedResult = parse(unspacedInput);
	assert(
		unspacedResult.ok,
		unspacedResult.ok ? "" : unspacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse: field names with numbers and underscores", () => {
	const input = `{field1: "a", field_2: "b", _private: "c", field_3_name: "d"}`;
	const expected = { field1: "a", field_2: "b", _private: "c", field_3_name: "d" };

	const result = parse(input);
	assert(result.ok, result.ok ? "" : result.errors.map((e) => e.message).join("\n"));
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parse(spacedInput);
	assert(
		spacedResult.ok,
		spacedResult.ok ? "" : spacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input);
	const unspacedResult = parse(unspacedInput);
	assert(
		unspacedResult.ok,
		unspacedResult.ok ? "" : unspacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse: time only", () => {
	const input = `{meeting_time: 14:30, alarm_time: 07:15:30}`;
	const expected = {
		meeting_time: new Date("1900-01-01T14:30:00"),
		alarm_time: new Date("1900-01-01T07:15:30"),
	};

	const result = parse(input);
	assert(result.ok, result.ok ? "" : result.errors.map((e) => e.message).join("\n"));
	expect(result.data).toEqual(expected);

	const spacedInput = space(input).replace("14 : 30", "14:30").replace("07 : 15 : 30", "07:15:30");
	const spacedResult = parse(spacedInput);
	assert(
		spacedResult.ok,
		spacedResult.ok ? "" : spacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input);
	const unspacedResult = parse(unspacedInput);
	assert(
		unspacedResult.ok,
		unspacedResult.ok ? "" : unspacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse: datetime with timezone offset", () => {
	const input = `{event_time: 2025-01-15T14:30+02:00}`;
	const expected = { event_time: new Date("2025-01-15T14:30+02:00") };

	const result = parse(input);
	assert(result.ok, result.ok ? "" : result.errors.map((e) => e.message).join("\n"));
	expect(result.data).toEqual(expected);

	const spacedInput = space(input).replace("14 : 30+02 : 00", "14:30+02:00");
	const spacedResult = parse(spacedInput);
	assert(
		spacedResult.ok,
		spacedResult.ok ? "" : spacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input);
	const unspacedResult = parse(unspacedInput);
	assert(
		unspacedResult.ok,
		unspacedResult.ok ? "" : unspacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse: multiple consecutive comments", () => {
	const input = `
# First comment
# Second comment
# Third comment
{
	name: "Alice"
}`;
	const expected = { name: "Alice" };

	const result = parse(input);
	assert(result.ok, result.ok ? "" : result.errors.map((e) => e.message).join("\n"));
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parse(spacedInput);
	assert(
		spacedResult.ok,
		spacedResult.ok ? "" : spacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input);
	const unspacedResult = parse(unspacedInput);
	assert(
		unspacedResult.ok,
		unspacedResult.ok ? "" : unspacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse: inline comments", () => {
	const input = `{name: "Bob", # inline comment
age: 30}`;
	const expected = { name: "Bob", age: 30 };

	const result = parse(input);
	assert(result.ok, result.ok ? "" : result.errors.map((e) => e.message).join("\n"));
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parse(spacedInput);
	assert(
		spacedResult.ok,
		spacedResult.ok ? "" : spacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input);
	const unspacedResult = parse(unspacedInput);
	assert(
		unspacedResult.ok,
		unspacedResult.ok ? "" : unspacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse: comments between fields", () => {
	const input = `{name: "Alice", # name field
# separator
age: 25 # age field
}`;
	const expected = { name: "Alice", age: 25 };

	const result = parse(input);
	assert(result.ok, result.ok ? "" : result.errors.map((e) => e.message).join("\n"));
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parse(spacedInput);
	assert(
		spacedResult.ok,
		spacedResult.ok ? "" : spacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input);
	const unspacedResult = parse(unspacedInput);
	assert(
		unspacedResult.ok,
		unspacedResult.ok ? "" : unspacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse: deeply nested structures", () => {
	const input = `{
	level1: {
		level2: {
			level3: {
				deep: "value"
			}
		}
	},
	nested_array: [[[1, 2], [3, 4]], [[5, 6], [7, 8]]]
}`;
	const expected = {
		level1: {
			level2: {
				level3: {
					deep: "value",
				},
			},
		},
		nested_array: [
			[
				[1, 2],
				[3, 4],
			],
			[
				[5, 6],
				[7, 8],
			],
		],
	};

	const result = parse(input);
	assert(result.ok, result.ok ? "" : result.errors.map((e) => e.message).join("\n"));
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parse(spacedInput);
	assert(
		spacedResult.ok,
		spacedResult.ok ? "" : spacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input);
	const unspacedResult = parse(unspacedInput);
	assert(
		unspacedResult.ok,
		unspacedResult.ok ? "" : unspacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse: single field object", () => {
	const input = `{name: "Alice"}`;
	const expected = { name: "Alice" };

	const result = parse(input);
	assert(result.ok, result.ok ? "" : result.errors.map((e) => e.message).join("\n"));
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parse(spacedInput);
	assert(
		spacedResult.ok,
		spacedResult.ok ? "" : spacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input);
	const unspacedResult = parse(unspacedInput);
	assert(
		unspacedResult.ok,
		unspacedResult.ok ? "" : unspacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse: large dataset", () => {
	const input = `{
	users: [
		{ id: 1, name: "Alice", active: true },
		{ id: 2, name: "Bob", active: false },
		{ id: 3, name: "Charlie", active: true },
		{ id: 4, name: "Diana", active: true },
		{ id: 5, name: "Eve", active: false }
	],
	stats: {
		total: 5,
		active: 3,
		inactive: 2,
		rating: 4.5
	},
	metadata: {
		created_at: 2025-01-01,
		updated_at: 2025-01-15T10:30:00,
		tags: ["production", "api", "v1"]
	}
}`;
	const expected = {
		users: [
			{ id: 1, name: "Alice", active: true },
			{ id: 2, name: "Bob", active: false },
			{ id: 3, name: "Charlie", active: true },
			{ id: 4, name: "Diana", active: true },
			{ id: 5, name: "Eve", active: false },
		],
		stats: {
			total: 5,
			active: 3,
			inactive: 2,
			rating: 4.5,
		},
		metadata: {
			created_at: new Date("2025-01-01"),
			updated_at: new Date("2025-01-15T10:30:00"),
			tags: ["production", "api", "v1"],
		},
	};

	const result = parse(input);
	assert(result.ok, result.ok ? "" : result.errors.map((e) => e.message).join("\n"));
	expect(result.data).toEqual(expected);

	const spacedInput = space(input).replace("10 : 30 : 00", "10:30:00");
	const spacedResult = parse(spacedInput);
	assert(
		spacedResult.ok,
		spacedResult.ok ? "" : spacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input);
	const unspacedResult = parse(unspacedInput);
	assert(
		unspacedResult.ok,
		unspacedResult.ok ? "" : unspacedResult.errors.map((e) => e.message).join("\n"),
	);
	expect(unspacedResult.data).toEqual(expected);
});
