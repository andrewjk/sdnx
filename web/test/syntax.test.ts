import { assert, expect, test } from "vitest";
import parse from "../src/parse";

test("syntax errors: no opening brace at top level", () => {
	const input = `age: 5`;
	const result = parse(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Expected '{' but found 'a'")).toBeTruthy();
});

test("syntax errors: no closing brace at top level", () => {
	const input = `{ age: 5 `;
	const result = parse(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Object not closed")).toBeTruthy();
});

test("syntax errors: no closing array brace", () => {
	const input = `{ foods: ["ice cream", "strudel" }`;
	const result = parse(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Array not closed")).toBeTruthy();
});

test("syntax errors: no field value", () => {
	const input = `{ foods, things: true }`;
	const result = parse(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Expected ':' but found ','")).toBeTruthy();
});

test("syntax errors: unsupported value type", () => {
	const input = `{ foods: things }`;
	const result = parse(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Unsupported value type 'things'")).toBeTruthy();
});

test("syntax errors: empty input", () => {
	const input = ``;
	const result = parse(input);
	assert(result.ok === false);
	expect(
		result.errors.find((e) => e.message === "Expected '{' but found 'undefined'"),
	).toBeTruthy();
});

test("syntax errors: just whitespace", () => {
	const input = `   \n\t  `;
	const result = parse(input);
	assert(result.ok === false);
	expect(
		result.errors.find((e) => e.message === "Expected '{' but found 'undefined'"),
	).toBeTruthy();
});

test("syntax errors: field name starts with number", () => {
	const input = `{ 1field: "value" }`;
	const result = parse(input);
	assert(result.ok === false);
	expect(
		result.errors.find((e) => e.message === "Field must start with quote or alpha"),
	).toBeTruthy();
});

test("syntax errors: field name with special chars", () => {
	const input = `{ field-name: "value" }`;
	const result = parse(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Expected ':' but found '-'")).toBeTruthy();
});

test("syntax errors: unclosed string", () => {
	const input = `{ name: "Alice }`;
	const result = parse(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "String not closed")).toBeTruthy();
});

test("syntax errors: invalid escape sequence", () => {
	const input = `{ quote: "Hel\\lo" }`;
	const result = parse(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Invalid escape sequence '\\l'")).toBeTruthy();
});

test("syntax errors: number with decimal but no digits", () => {
	const input = `{ value: 123. }`;
	const result = parse(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Unsupported value type '123.'")).toBeTruthy();
});

test("syntax errors: hex number with invalid chars", () => {
	const input = `{ color: 0xGHIJKL }`;
	const result = parse(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Unsupported value type '0xGHIJKL'")).toBeTruthy();
});

test("syntax errors: invalid date format", () => {
	const input = `{ dob: 2025-13-01 }`;
	const result = parse(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Invalid date '2025-13-01'")).toBeTruthy();
});

test("syntax errors: boolean with wrong case", () => {
	const input = `{ active: True }`;
	const result = parse(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Unsupported value type 'True'")).toBeTruthy();
});

test("syntax errors: negative without digits", () => {
	const input = `{ value: - }`;
	const result = parse(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Unsupported value type '-'")).toBeTruthy();
});

test("syntax errors: scientific notation missing exponent", () => {
	const input = `{ value: 1.5e }`;
	const result = parse(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Unsupported value type '1.5e'")).toBeTruthy();
});

test("syntax errors: multiple colons in field", () => {
	const input = `{ name:: "Alice" }`;
	const result = parse(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Unsupported value type ':'")).toBeTruthy();
});

test("syntax errors: array missing separator", () => {
	const input = `{ items: ["a" "b"] }`;
	const result = parse(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Expected ',' but found '\"'")).toBeTruthy();
});

test("syntax errors: array with trailing comma not followed by item", () => {
	const input = `{ items: ["a",] }`;
	const result = parse(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Unsupported value type ''")).toBeTruthy();
});

test("syntax errors: nested object not closed", () => {
	const input = `{ data: { nested: "value" }`;
	const result = parse(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Object not closed")).toBeTruthy();
});

test("syntax errors: nested array not closed", () => {
	const input = `{ matrix: [[1, 2] }`;
	const result = parse(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Array not closed")).toBeTruthy();
});

test("syntax errors: object with missing colon after field name", () => {
	const input = `{ name "Alice" }`;
	const result = parse(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Expected ':' but found '\"'")).toBeTruthy();
});

test("syntax errors: array with just opening brace", () => {
	const input = `{ items: [ }`;
	const result = parse(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Array not closed")).toBeTruthy();
});

test("syntax errors: array with missing opening brace", () => {
	const input = `{ items: 1, 2, 3] }`;
	const result = parse(input);
	assert(result.ok === false);
	expect(
		result.errors.find((e) => e.message === "Field must start with quote or alpha"),
	).toBeTruthy();
});

test("syntax errors: field name with starting underscore", () => {
	const input = `{ _private: "value" }`;
	expect(() => parse(input)).not.toThrow();
});

test("syntax errors: field name in quotes", () => {
	const input = `{ "private-field": "hidden" }`;
	expect(() => parse(input)).not.toThrow();
});

test("syntax errors: multiple commas in object", () => {
	const input = `{ name: "Alice",, age: 30 }`;
	const result = parse(input);
	assert(result.ok === false);
	expect(
		result.errors.find((e) => e.message === "Field must start with quote or alpha"),
	).toBeTruthy();
});

test("syntax errors: comma at start of object", () => {
	const input = `{ , name: "Alice" }`;
	const result = parse(input);
	assert(result.ok === false);
	expect(
		result.errors.find((e) => e.message === "Field must start with quote or alpha"),
	).toBeTruthy();
});

test("syntax errors: invalid time format", () => {
	const input = `{ time: 25:00 }`;
	const result = parse(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Invalid time '25:00'")).toBeTruthy();
});

test("syntax errors: invalid datetime format", () => {
	const input = `{ created: 2025-01-15T14:90+02:00 }`;
	const result = parse(input);
	assert(result.ok === false);
	expect(
		result.errors.find((e) => e.message === "Invalid date '2025-01-15T14:90+02:00'"),
	).toBeTruthy();
});

test("syntax errors: string with unescaped quote", () => {
	const input = `{ text: "Hello "World"" }`;
	const result = parse(input);
	assert(result.ok === false);
	expect(result.errors.find((e) => e.message === "Expected ':' but found '\"'")).toBeTruthy();
});
