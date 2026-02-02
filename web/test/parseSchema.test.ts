import { assert, expect, test } from "vitest";
import parseSchema from "../src/parseSchema";
import space from "./space";
import unspace from "./unspace";

test("parse schema: basic test", () => {
	const input = `
{
	active: bool,
	# a comment
	name: string minlen(2),
	age: int min(16),
	rating: num max(5),	
	## a description of this field
	skills: string,
	started_at: date,
	meeting_at: null | date,
	children: [{
		age: int,
		name: string,
	}],
}`;
	const expected = {
		active: { type: "bool" },
		name: { type: "string", validators: { minlen: { raw: "2", required: 2 } } },
		age: { type: "int", validators: { min: { raw: "16", required: 16 } } },
		rating: { type: "num", validators: { max: { raw: "5", required: 5 } } },
		skills: { type: "string", description: "a description of this field" },
		started_at: { type: "date" },
		meeting_at: { type: "union", inner: [{ type: "null" }, { type: "date" }] },
		children: {
			type: "array",
			inner: {
				type: "object",
				inner: {
					age: { type: "int" },
					name: { type: "string" },
				},
			},
		},
	};

	const result = parseSchema(input);
	assert(result.ok);
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parseSchema(spacedInput);
	assert(spacedResult.ok);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input)
		.replaceAll("min(", " min(")
		.replaceAll("max(", " max(")
		.replaceAll("len(", " len(")
		.replaceAll("min len(", " minlen(");
	const unspacedResult = parseSchema(unspacedInput);
	assert(unspacedResult.ok);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse schema: simple type", () => {
	const input = `
{
	name: string,
}`;
	const expected = {
		name: { type: "string" },
	};

	const result = parseSchema(input);
	assert(result.ok);
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parseSchema(spacedInput);
	assert(spacedResult.ok);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input);
	const unspacedResult = parseSchema(unspacedInput);
	assert(unspacedResult.ok);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse schema: type with description", () => {
	const input = `
{
	## This is a name
	name: string,
}`;
	const expected = {
		name: { type: "string", description: "This is a name" },
	};

	const result = parseSchema(input);
	assert(result.ok);
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parseSchema(spacedInput);
	assert(spacedResult.ok);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input);
	const unspacedResult = parseSchema(unspacedInput);
	assert(unspacedResult.ok);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse schema: union type", () => {
	const input = `
{
	value: string | int,
}`;
	const expected = {
		value: {
			type: "union",
			inner: [{ type: "string" }, { type: "int" }],
		},
	};

	const result = parseSchema(input);
	assert(result.ok);
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parseSchema(spacedInput);
	assert(spacedResult.ok);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input);
	const unspacedResult = parseSchema(unspacedInput);
	assert(unspacedResult.ok);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse schema: type with parameter", () => {
	const input = `
{
	age: int min(0),
}`;
	const expected = {
		age: {
			type: "int",
			validators: { min: { raw: "0", required: 0 } },
		},
	};

	const result = parseSchema(input);
	assert(result.ok);
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parseSchema(spacedInput);
	assert(spacedResult.ok);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input).replaceAll("min(", " min(");
	const unspacedResult = parseSchema(unspacedInput);
	assert(unspacedResult.ok);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse schema: object type", () => {
	const input = `
{
	dob: { year: int, month: int, day: int }
}`;
	const expected = {
		dob: {
			type: "object",
			inner: {
				year: { type: "int" },
				month: { type: "int" },
				day: { type: "int" },
			},
		},
	};

	const result = parseSchema(input);
	assert(result.ok);
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parseSchema(spacedInput);
	assert(spacedResult.ok);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input);
	const unspacedResult = parseSchema(unspacedInput);
	assert(unspacedResult.ok);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse schema: array type", () => {
	const input = `
{
	children: [ string ]
}`;
	const expected = {
		children: {
			type: "array",
			inner: {
				type: "string",
			},
		},
	};

	const result = parseSchema(input);
	assert(result.ok);
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parseSchema(spacedInput);
	assert(spacedResult.ok);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input);
	const unspacedResult = parseSchema(unspacedInput);
	assert(unspacedResult.ok);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse schema: mix macro", () => {
	const input = `
{
	name: string minlen(2),
	@mix({
		age: int min(16),
		rating: num max(5),
	}),
	active: bool,
}`;
	const expected = {
		name: {
			type: "string",
			validators: { minlen: { raw: "2", required: 2 } },
		},
		mix$1: {
			type: "mix",
			inner: [
				{
					age: {
						type: "int",
						validators: { min: { raw: "16", required: 16 } },
					},
					rating: {
						type: "num",
						validators: { max: { raw: "5", required: 5 } },
					},
				},
			],
		},
		active: { type: "bool" },
	};

	const result = parseSchema(input);
	assert(result.ok);
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parseSchema(spacedInput);
	assert(spacedResult.ok);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input)
		.replaceAll("min(", " min(")
		.replaceAll("max(", " max(")
		.replaceAll("len(", " len(")
		.replaceAll("min len(", " minlen(");
	const unspacedResult = parseSchema(unspacedInput);
	assert(unspacedResult.ok);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse schema: any macro", () => {
	const input = `
{
	name: string minlen(2),
	@any(): int min(16),
	active: bool,
}`;
	const expected = {
		name: {
			type: "string",
			validators: { minlen: { raw: "2", required: 2 } },
		},
		any$1: {
			type: "",
			inner: {
				type: "int",
				validators: { min: { raw: "16", required: 16 } },
			},
		},
		active: { type: "bool" },
	};

	const result = parseSchema(input);
	assert(result.ok);
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parseSchema(spacedInput);
	assert(spacedResult.ok);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input)
		.replaceAll("min(", " min(")
		.replaceAll("max(", " max(")
		.replaceAll("len(", " len(")
		.replaceAll("min len(", " minlen(");
	const unspacedResult = parseSchema(unspacedInput);
	assert(unspacedResult.ok);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse schema: any macro with pattern", () => {
	const input = `
{
	@any(/v\\d/): string,
}`;
	const expected = {
		any$1: {
			type: "/v\\d/",
			inner: { type: "string" },
		},
	};

	const result = parseSchema(input);
	assert(result.ok);
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parseSchema(spacedInput);
	assert(spacedResult.ok);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input);
	const unspacedResult = parseSchema(unspacedInput);
	assert(unspacedResult.ok);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse schema: type with multiple parameters", () => {
	const input = `
{
	rating: num min(0) max(5),
}`;
	const expected = {
		rating: {
			type: "num",
			validators: {
				min: { raw: "0", required: 0 },
				max: { raw: "5", required: 5 },
			},
		},
	};

	const result = parseSchema(input);
	assert(result.ok);
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parseSchema(spacedInput);
	assert(spacedResult.ok);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input).replaceAll("min(", " min(").replaceAll("max(", " max(");
	const unspacedResult = parseSchema(unspacedInput);
	assert(unspacedResult.ok);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse schema: nested object", () => {
	const input = `
{
	address: {
		street: string,
		city: string,
		zip: string,
	},
}`;
	const expected = {
		address: {
			type: "object",
			inner: {
				street: { type: "string" },
				city: { type: "string" },
				zip: { type: "string" },
			},
		},
	};

	const result = parseSchema(input);
	assert(result.ok);
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parseSchema(spacedInput);
	assert(spacedResult.ok);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input);
	const unspacedResult = parseSchema(unspacedInput);
	assert(unspacedResult.ok);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse schema: array of objects", () => {
	const input = `
{
	items: [{ id: int, name: string }],
}`;
	const expected = {
		items: {
			type: "array",
			inner: {
				type: "object",
				inner: {
					id: { type: "int" },
					name: { type: "string" },
				},
			},
		},
	};

	const result = parseSchema(input);
	assert(result.ok);
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parseSchema(spacedInput);
	assert(spacedResult.ok);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input);
	const unspacedResult = parseSchema(unspacedInput);
	assert(unspacedResult.ok);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse schema: array of arrays", () => {
	const input = `
{
	matrix: [[ int ]],
}`;
	const expected = {
		matrix: {
			type: "array",
			inner: {
				type: "array",
				inner: {
					type: "int",
				},
			},
		},
	};

	const result = parseSchema(input);
	assert(result.ok);
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parseSchema(spacedInput);
	assert(spacedResult.ok);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input);
	const unspacedResult = parseSchema(unspacedInput);
	assert(unspacedResult.ok);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse schema: union of three types", () => {
	const input = `
{
	value: string | int | bool,
}`;
	const expected = {
		value: {
			type: "union",
			inner: [{ type: "string" }, { type: "int" }, { type: "bool" }],
		},
	};

	const result = parseSchema(input);
	assert(result.ok);
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parseSchema(spacedInput);
	assert(spacedResult.ok);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input);
	const unspacedResult = parseSchema(unspacedInput);
	assert(unspacedResult.ok);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse schema: multiple mix macros", () => {
	const input = `
{
	@mix({
		role: "admin",
		level: int min(1),
	}),
	@mix({
		role: "user",
		plan: string,
	}),
}`;
	const expected = {
		mix$1: {
			type: "mix",
			inner: [
				{
					role: { type: '"admin"' },
					level: {
						type: "int",
						validators: { min: { raw: "1", required: 1 } },
					},
				},
			],
		},
		mix$2: {
			type: "mix",
			inner: [
				{
					role: { type: '"user"' },
					plan: { type: "string" },
				},
			],
		},
	};

	const result = parseSchema(input);
	assert(result.ok);
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parseSchema(spacedInput);
	assert(spacedResult.ok);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input).replaceAll("min(", " min(");
	const unspacedResult = parseSchema(unspacedInput);
	assert(unspacedResult.ok);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse schema: mix with multiple alternatives", () => {
	const input = `
{
	@mix({
		minor: false
	} | {
		minor: true,
		guardian: string
	} | {
		minor: true,
		age: int min(18)
	}),
}`;
	const expected = {
		mix$1: {
			type: "mix",
			inner: [
				{
					minor: { type: "false" },
				},
				{
					minor: { type: "true" },
					guardian: { type: "string" },
				},
				{
					minor: { type: "true" },
					age: {
						type: "int",
						validators: { min: { raw: "18", required: 18 } },
					},
				},
			],
		},
	};

	const result = parseSchema(input);
	assert(result.ok);
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parseSchema(spacedInput);
	assert(spacedResult.ok);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input).replaceAll("min(", " min(");
	const unspacedResult = parseSchema(unspacedInput);
	assert(unspacedResult.ok);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse schema: empty object", () => {
	const input = `{}`;
	const expected = {};

	const result = parseSchema(input);
	assert(result.ok);
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parseSchema(spacedInput);
	assert(spacedResult.ok);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input);
	const unspacedResult = parseSchema(unspacedInput);
	assert(unspacedResult.ok);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse schema: array with union type", () => {
	const input = `
{
	values: [ string | int ],
}`;
	const expected = {
		values: {
			type: "array",
			inner: {
				type: "union",
				inner: [{ type: "string" }, { type: "int" }],
			},
		},
	};

	const result = parseSchema(input);
	assert(result.ok);
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parseSchema(spacedInput);
	assert(spacedResult.ok);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input);
	const unspacedResult = parseSchema(unspacedInput);
	assert(unspacedResult.ok);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse schema: union with array first", () => {
	const input = `
 {
	values: [ string ] | string,
 }`;
	const expected = {
		values: {
			type: "union",
			inner: [
				{
					type: "array",
					inner: { type: "string" },
				},
				{ type: "string" },
			],
		},
	};

	const result = parseSchema(input);
	assert(result.ok);
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parseSchema(spacedInput);
	assert(spacedResult.ok);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input);
	const unspacedResult = parseSchema(unspacedInput);
	assert(unspacedResult.ok);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse schema: union with array second", () => {
	const input = `
 {
	values: string | [ string ],
 }`;
	const expected = {
		values: {
			type: "union",
			inner: [
				{ type: "string" },
				{
					type: "array",
					inner: { type: "string" },
				},
			],
		},
	};

	const result = parseSchema(input);
	assert(result.ok);
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parseSchema(spacedInput);
	assert(spacedResult.ok);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input);
	const unspacedResult = parseSchema(unspacedInput);
	assert(unspacedResult.ok);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse schema: union with object first", () => {
	const input = `
 {
	values: { name: string } | string,
 }`;
	const expected = {
		values: {
			type: "union",
			inner: [
				{
					type: "object",
					inner: {
						name: { type: "string" },
					},
				},
				{ type: "string" },
			],
		},
	};

	const result = parseSchema(input);
	assert(result.ok);
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parseSchema(spacedInput);
	assert(spacedResult.ok);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input);
	const unspacedResult = parseSchema(unspacedInput);
	assert(unspacedResult.ok);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse schema: union with object second", () => {
	const input = `
 {
	values: string | { name: string },
 }`;
	const expected = {
		values: {
			type: "union",
			inner: [
				{ type: "string" },
				{
					type: "object",
					inner: {
						name: { type: "string" },
					},
				},
			],
		},
	};

	const result = parseSchema(input);
	assert(result.ok);
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parseSchema(spacedInput);
	assert(spacedResult.ok);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input);
	const unspacedResult = parseSchema(unspacedInput);
	assert(unspacedResult.ok);
	expect(unspacedResult.data).toEqual(expected);
});

test("parse schema: deeply nested structure", () => {
	const input = `
{
	data: {
		user: {
			profile: {
				name: string,
				contacts: [{ type: string, value: string }],
			},
		},
	},
}`;
	const expected = {
		data: {
			type: "object",
			inner: {
				user: {
					type: "object",
					inner: {
						profile: {
							type: "object",
							inner: {
								name: { type: "string" },
								contacts: {
									type: "array",
									inner: {
										type: "object",
										inner: {
											type: { type: "string" },
											value: { type: "string" },
										},
									},
								},
							},
						},
					},
				},
			},
		},
	};

	const result = parseSchema(input);
	assert(result.ok);
	expect(result.data).toEqual(expected);

	const spacedInput = space(input);
	const spacedResult = parseSchema(spacedInput);
	assert(spacedResult.ok);
	expect(spacedResult.data).toEqual(expected);

	const unspacedInput = unspace(input);
	const unspacedResult = parseSchema(unspacedInput);
	assert(unspacedResult.ok);
	expect(unspacedResult.data).toEqual(expected);
});
