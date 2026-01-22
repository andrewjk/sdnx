import { expect, test } from "vitest";
import parse from "../src/parse";

test("syntax errors: no opening brace at top level", () => {
	const input = `age: 5`;
	expect(() => parse(input)).toThrowError("Expected '{' but found 'a'");
});

test("syntax errors: no closing brace at top level", () => {
	const input = `{ age: 5 `;
	expect(() => parse(input)).toThrowError("Object not closed");
});

test("syntax errors: no closing array brace", () => {
	const input = `{ foods: ["ice cream", "strudel" }`;
	expect(() => parse(input)).toThrowError("Array not closed");
});

test("syntax errors: no field value", () => {
	const input = `{ foods, things: true }`;
	expect(() => parse(input)).toThrowError("Expected ':' but found ','");
});

test("syntax errors: unsupported value type", () => {
	const input = `{ foods: things }`;
	expect(() => parse(input)).toThrowError("Unsupported value type 'things'");
});

test("syntax errors: empty input", () => {
	const input = ``;
	expect(() => parse(input)).toThrowError("Expected '{' but found 'undefined'");
});

test("syntax errors: just whitespace", () => {
	const input = `   \n\t  `;
	expect(() => parse(input)).toThrowError("Expected '{' but found 'undefined'");
});

test("syntax errors: field name starts with number", () => {
	const input = `{ 1field: "value" }`;
	expect(() => parse(input)).toThrowError("Field must start with quote or alpha");
});

test("syntax errors: field name with special chars", () => {
	const input = `{ field-name: "value" }`;
	expect(() => parse(input)).toThrowError("Expected ':' but found '-'");
});

test("syntax errors: unclosed string", () => {
	const input = `{ name: "Alice }`;
	expect(() => parse(input)).toThrowError("String not closed");
});

test("syntax errors: invalid escape sequence", () => {
	const input = `{ quote: "Hel\\lo" }`;
	expect(() => parse(input)).toThrowError("Invalid escape sequence '\\l'");
});

test("syntax errors: number with decimal but no digits", () => {
	const input = `{ value: 123. }`;
	expect(() => parse(input)).toThrowError("Unsupported value type '123.'");
});

test("syntax errors: hex number with invalid chars", () => {
	const input = `{ color: 0xGHIJKL }`;
	expect(() => parse(input)).toThrowError("Unsupported value type '0xGHIJKL'");
});

test("syntax errors: invalid date format", () => {
	const input = `{ dob: 2025-13-01 }`;
	expect(() => parse(input)).toThrowError("Invalid date '2025-13-01'");
});

test("syntax errors: boolean with wrong case", () => {
	const input = `{ active: True }`;
	expect(() => parse(input)).toThrowError("Unsupported value type 'True'");
});

test("syntax errors: negative without digits", () => {
	const input = `{ value: - }`;
	expect(() => parse(input)).toThrowError("Unsupported value type '-'");
});

test("syntax errors: scientific notation missing exponent", () => {
	const input = `{ value: 1.5e }`;
	expect(() => parse(input)).toThrowError("Unsupported value type '1.5e'");
});

test("syntax errors: multiple colons in field", () => {
	const input = `{ name:: "Alice" }`;
	expect(() => parse(input)).toThrowError("Unsupported value type ':'");
});

test("syntax errors: array missing separator", () => {
	const input = `{ items: ["a" "b"] }`;
	expect(() => parse(input)).toThrowError("Expected ',' but found '\"'");
});

test("syntax errors: array with trailing comma not followed by item", () => {
	const input = `{ items: ["a",] }`;
	expect(() => parse(input)).toThrowError("Unsupported value type ''");
});

test("syntax errors: nested object not closed", () => {
	const input = `{ data: { nested: "value" }`;
	expect(() => parse(input)).toThrowError("Object not closed");
});

test("syntax errors: nested array not closed", () => {
	const input = `{ matrix: [[1, 2] }`;
	expect(() => parse(input)).toThrowError("Array not closed");
});

test("syntax errors: object with missing colon after field name", () => {
	const input = `{ name "Alice" }`;
	expect(() => parse(input)).toThrowError("Expected ':' but found '\"'");
});

test("syntax errors: array with just opening brace", () => {
	const input = `{ items: [ }`;
	expect(() => parse(input)).toThrowError("Array not closed");
});

test("syntax errors: array with missing opening brace", () => {
	const input = `{ items: 1, 2, 3] }`;
	expect(() => parse(input)).toThrowError("Field must start with quote or alpha");
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
	expect(() => parse(input)).toThrowError("Field must start with quote or alpha");
});

test("syntax errors: comma at start of object", () => {
	const input = `{ , name: "Alice" }`;
	expect(() => parse(input)).toThrowError("Field must start with quote or alpha");
});

test("syntax errors: invalid time format", () => {
	const input = `{ time: 25:00 }`;
	expect(() => parse(input)).toThrowError("Invalid time '25:00'");
});

test("syntax errors: invalid datetime format", () => {
	const input = `{ created: 2025-01-15T14:90+02:00 }`;
	expect(() => parse(input)).toThrowError("Invalid date '2025-01-15T14:90+02:00'");
});

test("syntax errors: string with unescaped quote", () => {
	const input = `{ text: "Hello "World"" }`;
	expect(() => parse(input)).toThrowError("Expected ':' but found '\"'");
});
