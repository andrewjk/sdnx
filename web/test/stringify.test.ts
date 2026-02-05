import { expect, test } from "vitest";
import parse from "../src/parse";
import stringify from "../src/stringify";

test("stringify: basic object", () => {
	const input = {
		name: "Alice",
		age: 25,
		active: true,
		rating: 4.5,
		balance: -100,
		tags: ["developer", "writer"],
	};

	const result = stringify(input);
	const expected = `{
	name: "Alice",
	age: 25,
	active: true,
	rating: 4.5,
	balance: -100,
	tags: [
		"developer",
		"writer"
	]
}`;

	expect(result).toEqual(expected);

	const parsed = parse(result);
	expect(parsed.ok).toBe(true);
});

test("stringify: empty object", () => {
	const input = {};
	const result = stringify(input);
	const expected = `{\n}`;
	expect(result).toEqual(expected);

	const parsed = parse(result);
	expect(parsed.ok).toBe(true);
});

test("stringify: empty array", () => {
	const input = { items: [] };
	const result = stringify(input);
	const expected = `{
	items: [
	]
}`;

	expect(result).toEqual(expected);

	const parsed = parse(result);
	expect(parsed.ok).toBe(true);
});

test("stringify: nested objects", () => {
	const input = {
		user: {
			name: "Bob",
			age: 30,
			address: {
				city: "New York",
				country: "USA",
			},
		},
	};

	const result = stringify(input);
	const expected = `{
	user: {
		name: "Bob",
		age: 30,
		address: {
			city: "New York",
			country: "USA"
		}
	}
}`;

	expect(result).toEqual(expected);

	const parsed = parse(result);
	expect(parsed.ok).toBe(true);
});

test("stringify: nested arrays", () => {
	const input = {
		matrix: [
			[1, 2, 3],
			[4, 5, 6],
			[7, 8, 9],
		],
	};

	const result = stringify(input);
	const expected = `{
	matrix: [
		[
			1,
			2,
			3
		],
		[
			4,
			5,
			6
		],
		[
			7,
			8,
			9
		]
	]
}`;

	expect(result).toEqual(expected);

	const parsed = parse(result);
	expect(parsed.ok).toBe(true);
});

test("stringify: date without time", () => {
	const input = {
		created_at: new Date("2025-01-15"),
	};

	const result = stringify(input);
	const parsed = parse(result);
	expect(parsed.ok).toBe(true);
});

test("stringify: date with time", () => {
	const input = {
		meeting_at: new Date("2025-01-15T10:30"),
	};

	const result = stringify(input);
	const expected = `{
	meeting_at: 2025-01-15T10:30
}`;

	expect(result).toEqual(expected);

	const parsed = parse(result);
	expect(parsed.ok).toBe(true);
});

test("stringify: date with time including seconds", () => {
	const input = {
		event_at: new Date("2025-01-15T10:30:45"),
	};

	const result = stringify(input);
	const expected = `{
	event_at: 2025-01-15T10:30
}`;

	expect(result).toEqual(expected);

	const parsed = parse(result);
	expect(parsed.ok).toBe(true);
});

test("stringify: boolean values", () => {
	const input = {
		is_active: true,
		is_deleted: false,
	};

	const result = stringify(input);
	const expected = `{
	is_active: true,
	is_deleted: false
}`;

	expect(result).toEqual(expected);

	const parsed = parse(result);
	expect(parsed.ok).toBe(true);
});

test("stringify: null values", () => {
	const input = {
		optional: null,
		another: null,
	};

	const result = stringify(input);
	const expected = `{
	optional: null,
	another: null
}`;

	expect(result).toEqual(expected);

	const parsed = parse(result);
	expect(parsed.ok).toBe(true);
});

test("stringify: numbers", () => {
	const input = {
		integer: 42,
		float: 3.14,
		negative: -10,
		zero: 0,
		scientific: 1.5e10,
		hex: 0xff,
	};

	const result = stringify(input);
	const expected = `{
	integer: 42,
	float: 3.14,
	negative: -10,
	zero: 0,
	scientific: 15000000000,
	hex: 255
}`;

	expect(result).toEqual(expected);

	const parsed = parse(result);
	expect(parsed.ok).toBe(true);
});

test("stringify: strings with special characters", () => {
	const input = {
		quote: 'She said "Hello"',
		path: "/usr/local/bin",
		regex: "^test.*pattern$",
	};

	const result = stringify(input);
	const expected = `{
	quote: "She said "Hello"",
	path: "/usr/local/bin",
	regex: "^test.*pattern$"
}`;

	expect(result).toEqual(expected);

	const parsed = parse(result);
	expect(parsed.ok).toBe(false); // Can't parse because quotes aren't escaped
});

test("stringify: large dataset", () => {
	const input = {
		users: [
			{ id: 1, name: "Alice", active: true },
			{ id: 2, name: "Bob", active: false },
			{ id: 3, name: "Charlie", active: true },
		],
		stats: {
			total: 3,
			active: 2,
			inactive: 1,
			rating: 4.5,
		},
	};

	const result = stringify(input);
	const expected = `{
	users: [
		{
			id: 1,
			name: "Alice",
			active: true
		},
		{
			id: 2,
			name: "Bob",
			active: false
		},
		{
			id: 3,
			name: "Charlie",
			active: true
		}
	],
	stats: {
		total: 3,
		active: 2,
		inactive: 1,
		rating: 4.5
	}
}`;

	expect(result).toEqual(expected);

	const parsed = parse(result);
	expect(parsed.ok).toBe(true);
});

test("stringify: ansi color mode enabled", () => {
	const input = {
		name: "Alice",
		age: 25,
		active: true,
	};

	const result = stringify(input, { ansi: true });
	const stripped = result.replace(/\x1b\[[0-9]+m/g, "");

	const expected = `{
	name: "Alice",
	age: 25,
	active: true
}`;

	expect(stripped).toEqual(expected);

	expect(result).toContain("\x1b[32m"); // Green for strings
	expect(result).toContain("\x1b[33m"); // Yellow for numbers
	expect(result).toContain("\x1b[34m"); // Blue for booleans
	expect(result).toContain("\x1b[0m"); // Reset
});

test("stringify: ansi color mode disabled", () => {
	const input = {
		name: "Alice",
		age: 25,
		active: true,
	};

	const result = stringify(input, { ansi: false });
	const expected = `{
	name: "Alice",
	age: 25,
	active: true
}`;

	expect(result).toEqual(expected);
	expect(result).not.toContain("\x1b[");
});

test("stringify: ansi colors for dates", () => {
	const input = {
		date: new Date("2025-01-15"),
	};

	const result = stringify(input, { ansi: true });
	const stripped = result.replace(/\x1b\[[0-9]+m/g, "");

	const parsed = parse(stripped);
	expect(parsed.ok).toBe(true);
	expect(result).toContain("\x1b[35m"); // Magenta for dates
});

test("stringify: array of objects", () => {
	const input = {
		items: [
			{ name: "Item 1", count: 5 },
			{ name: "Item 2", count: 10 },
			{ name: "Item 3", count: 15 },
		],
	};

	const result = stringify(input);
	const expected = `{
	items: [
		{
			name: "Item 1",
			count: 5
		},
		{
			name: "Item 2",
			count: 10
		},
		{
			name: "Item 3",
			count: 15
		}
	]
}`;

	expect(result).toEqual(expected);

	const parsed = parse(result);
	expect(parsed.ok).toBe(true);
});

test("stringify: custom indent text", () => {
	const input = {
		name: "Alice",
		children: ["Jez", "Bez"],
		active: true,
	};

	const result = stringify(input, { indent: "  " });
	const expected = `{
  name: "Alice",
  children: [
    "Jez",
    "Bez"
  ],
  active: true
}`;

	expect(result).toEqual(expected);
});

test("stringify: deeply nested structures", () => {
	const input = {
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

	const result = stringify(input);
	const expected = `{
	level1: {
		level2: {
			level3: {
				deep: "value"
			}
		}
	},
	nested_array: [
		[
			[
				1,
				2
			],
			[
				3,
				4
			]
		],
		[
			[
				5,
				6
			],
			[
				7,
				8
			]
		]
	]
}`;

	expect(result).toEqual(expected);

	const parsed = parse(result);
	expect(parsed.ok).toBe(true);
});
