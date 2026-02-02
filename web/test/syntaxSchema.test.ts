import { assert, expect, test } from "vitest";
import parseSchema from "../src/parseSchema";

test("schema syntax errors: no opening brace at top level", () => {
	const input = `age: int`;
	const result = parseSchema(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Expected '{' but found 'a'")).toBeTruthy();
});

test("schema syntax errors: no closing brace at top level", () => {
	const input = `{ age: int `;
	const result = parseSchema(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Schema object not closed")).toBeTruthy();
});

test("schema syntax errors: no closing array brace", () => {
	const input = `{ foods: [string }`;
	const result = parseSchema(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Schema array not closed")).toBeTruthy();
});

test("schema syntax errors: no field value", () => {
	const input = `{ foods, things: boolean }`;
	const result = parseSchema(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Expected ':' but found ','")).toBeTruthy();
});

test("schema syntax errors: unsupported value type", () => {
	const input = `{ foods: things }`;
	const result = parseSchema(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Unsupported value type 'things'")).toBeTruthy();
});

test("schema syntax errors: empty input", () => {
	const input = ``;
	const result = parseSchema(input);
	assert(result.ok === false);
	expect(
		result.errors.find((e) => e.message === "Expected '{' but found 'undefined'"),
	).toBeTruthy();
});

test("schema syntax errors: just whitespace", () => {
	const input = `   \n\t  `;
	const result = parseSchema(input);
	assert(result.ok === false);
	expect(
		result.errors.find((e) => e.message === "Expected '{' but found 'undefined'"),
	).toBeTruthy();
});

test("schema syntax errors: field name starts with number", () => {
	const input = `{ 1field: string }`;
	const result = parseSchema(input);
	assert(result.ok === false);
	expect(
		result.errors.find((e) => e.message === "Field must start with quote or alpha"),
	).toBeTruthy();
});

test("schema syntax errors: field name with special chars", () => {
	const input = `{ field-name: string }`;
	const result = parseSchema(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Expected ':' but found '-'")).toBeTruthy();
});

test("schema syntax errors: unclosed string", () => {
	const input = `{ name: "Alice }`;
	const result = parseSchema(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "String not closed")).toBeTruthy();
});

test("schema syntax errors: invalid escape sequence", () => {
	const input = `{ quote: "Hel\\lo" }`;
	const result = parseSchema(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Invalid escape sequence '\\l'")).toBeTruthy();
});

test("schema syntax errors: number with decimal but no digits", () => {
	const input = `{ value: 123. }`;
	const result = parseSchema(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Unsupported value type '123.'")).toBeTruthy();
});

test("schema syntax errors: hex number with invalid chars", () => {
	const input = `{ color: 0xGHIJKL }`;
	const result = parseSchema(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Unsupported value type '0xGHIJKL'")).toBeTruthy();
});

test("schema syntax errors: invalid date format", () => {
	const input = `{ dob: 2025-13-01 }`;
	const result = parseSchema(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Invalid date '2025-13-01'")).toBeTruthy();
});

test("schema syntax errors: boolean with wrong case", () => {
	const input = `{ active: True }`;
	const result = parseSchema(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Unsupported value type 'True'")).toBeTruthy();
});

test("schema syntax errors: negative without digits", () => {
	const input = `{ value: - }`;
	const result = parseSchema(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Unsupported value type '-'")).toBeTruthy();
});

test("schema syntax errors: scientific notation missing exponent", () => {
	const input = `{ value: 1.5e }`;
	const result = parseSchema(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Unsupported value type '1.5e'")).toBeTruthy();
});

test("schema syntax errors: multiple colons in field", () => {
	const input = `{ name:: string }`;
	const result = parseSchema(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Unsupported value type ':'")).toBeTruthy();
});

test("schema syntax errors: array with trailing comma not followed by item", () => {
	const input = `{ items: ["a",] }`;
	const result = parseSchema(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Schema array not closed")).toBeTruthy();
});

test("schema syntax errors: nested object not closed", () => {
	const input = `{ data: { nested: string }`;
	const result = parseSchema(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Schema object not closed")).toBeTruthy();
});

test("schema syntax errors: nested array not closed", () => {
	const input = `{ matrix: [[int] }`;
	const result = parseSchema(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Schema array not closed")).toBeTruthy();
});

test("schema syntax errors: object with missing colon after field name", () => {
	const input = `{ name string }`;
	const result = parseSchema(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Expected ':' but found 's'")).toBeTruthy();
});

test("schema syntax errors: array with just opening brace", () => {
	const input = `{ items: [ }`;
	const result = parseSchema(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Schema array not closed")).toBeTruthy();
});

test("schema syntax errors: array with missing opening brace", () => {
	const input = `{ items: int] }`;
	const result = parseSchema(input);
	assert(result.ok === false);
	// TODO: a better error
	//expect(result.errors.find((e) => e.message === "Schema object not opened")).toBeTruthy();
	expect(result.errors.find((e) => e.message === "Schema object not closed")).toBeTruthy();
});

test("schema syntax errors: field name with starting underscore", () => {
	const input = `{ _private: string }`;
	expect(() => parseSchema(input)).not.toThrow();
});

test("schema syntax errors: field name in quotes", () => {
	const input = `{ "private-field": string }`;
	expect(() => parseSchema(input)).not.toThrow();
});

test("schema syntax errors: multiple commas in object", () => {
	const input = `{ name: string,, age: int }`;
	const result = parseSchema(input);
	assert(result.ok === false);
	expect(
		result.errors.find((e) => e.message === "Field must start with quote or alpha"),
	).toBeTruthy();
});

test("schema syntax errors: comma at start of object", () => {
	const input = `{ , name: string }`;
	const result = parseSchema(input);
	assert(result.ok === false);
	expect(
		result.errors.find((e) => e.message === "Field must start with quote or alpha"),
	).toBeTruthy();
});

test("schema syntax errors: invalid time format", () => {
	const input = `{ time: 25:00 }`;
	const result = parseSchema(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Invalid time '25:00'")).toBeTruthy();
});

test("schema syntax errors: invalid datetime format", () => {
	const input = `{ created: 2025-01-15T14:90+02:00 }`;
	const result = parseSchema(input);
	assert(result.ok === false);
	expect(
		result.errors.find((e) => e.message === "Invalid date '2025-01-15T14:90+02:00'"),
	).toBeTruthy();
});

test("schema syntax errors: string with unescaped quote", () => {
	const input = `{ text: "Hello "World"" }`;
	const result = parseSchema(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Expected ':' but found '\"'")).toBeTruthy();
});

test("schema syntax errors: unknown validator", () => {
	const input = `{ text: string required }`;
	const result = parseSchema(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Unsupported validator 'required'")).toBeTruthy();
});
