import { expect, test } from "vitest";
import parse from "../src/parse";

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

	expect(result).toEqual(expected);
});

test("parse: basic test spaced", () => {
	const input = `
{
	active : true ,
	name : "Darren" ,
	children : [ {
		name : "Rocket" ,
		age : 5 ,
	} ] ,
}`;

	const expected = {
		active: true,
		name: "Darren",
		children: [
			{
				name: "Rocket",
				age: 5,
			},
		],
	};

	const result = parse(input);

	expect(result).toEqual(expected);
});

test("parse: basic test unspaced", () => {
	const input = `{active:true,name:"Darren",children:[{name:"Rocket",age:5,}],}`;

	const expected = {
		active: true,
		name: "Darren",
		children: [
			{
				name: "Rocket",
				age: 5,
			},
		],
	};

	const result = parse(input);

	expect(result).toEqual(expected);
});

test("parse: empty object", () => {
	const input = `{}`;

	const result = parse(input);

	expect(result).toEqual({});
});

test("parse: negative numbers", () => {
	const input = `{temp: -10, balance: -3.14}`;

	const result = parse(input);

	expect(result).toEqual({ temp: -10, balance: -3.14 });
});

test("parse: positive numbers with plus prefix", () => {
	const input = `{count: +42, score: +4.5}`;

	const result = parse(input);

	expect(result).toEqual({ count: 42, score: 4.5 });
});

test("parse: hexadecimal integers", () => {
	const input = `{color: 0xFF00FF, alpha: 0xAB}`;

	const result = parse(input);

	expect(result).toEqual({ color: 0xff00ff, alpha: 0xab });
});

test("parse: scientific notation", () => {
	const input = `{distance: 1.5e10, tiny: 1.5e-5}`;

	const result = parse(input);

	expect(result).toEqual({ distance: 1.5e10, tiny: 1.5e-5 });
});

test("parse: numbers with underscore separators", () => {
	const input = `{population: 1_000_000, big_number: 1_000_000.123}`;

	const result = parse(input);

	expect(result).toEqual({ population: 1_000_000, big_number: 1_000_000.123 });
});

test("parse: string with escaped quotes", () => {
	const input = `{quote: "She said \\"Hello\\""}`;

	const result = parse(input);

	expect(result).toEqual({ quote: `She said \\"Hello\\"` });
});

test("parse: quoted field name", () => {
	const input = `{"field-with-dash": "value", "with spaces": "test"}`;

	const result = parse(input);

	expect(result).toEqual({
		'"field-with-dash"': "value",
		'"with spaces"': "test",
	});
});

test("parse: field names with numbers and underscores", () => {
	const input = `{field1: "a", field_2: "b", _private: "c", field_3_name: "d"}`;

	const result = parse(input);

	expect(result).toEqual({ field1: "a", field_2: "b", _private: "c", field_3_name: "d" });
});

test("parse: time only", () => {
	const input = `{meeting_time: 14:30, alarm_time: 07:15:30}`;

	const result = parse(input);

	expect(result).toEqual({
		meeting_time: new Date("1900-01-01T14:30:00"),
		alarm_time: new Date("1900-01-01T07:15:30"),
	});
});

test("parse: datetime with timezone offset", () => {
	const input = `{event_time: 2025-01-15T14:30+02:00}`;

	const result = parse(input);

	expect(result).toEqual({ event_time: new Date("2025-01-15T14:30+02:00") });
});

test("parse: multiple consecutive comments", () => {
	const input = `
# First comment
# Second comment
# Third comment
{
	name: "Alice"
}`;

	const result = parse(input);

	expect(result).toEqual({ name: "Alice" });
});

test("parse: inline comments", () => {
	const input = `{name: "Bob", # inline comment
age: 30}`;

	const result = parse(input);

	expect(result).toEqual({ name: "Bob", age: 30 });
});

test("parse: comments between fields", () => {
	const input = `{name: "Alice", # name field
# separator
age: 25 # age field
}`;

	const result = parse(input);

	expect(result).toEqual({ name: "Alice", age: 25 });
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

	const result = parse(input);

	expect(result).toEqual({
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
	});
});

test("parse: single field object", () => {
	const input = `{name: "Alice"}`;

	const result = parse(input);

	expect(result).toEqual({ name: "Alice" });
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

	const result = parse(input);

	expect(result).toEqual({
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
	});
});
