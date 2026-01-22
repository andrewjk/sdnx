import { expect, test } from "vitest";
import parseSchema from "../src/parseSchema";

test("schema syntax errors: no opening brace at top level", () => {
	const input = `age: int`;
	expect(() => parseSchema(input)).toThrowError("Expected '{' but found 'a'");
});

test("schema syntax errors: no closing brace at top level", () => {
	const input = `{ age: int `;
	expect(() => parseSchema(input)).toThrowError("Schema object not closed");
});

test("schema syntax errors: no closing array brace", () => {
	const input = `{ foods: [string }`;
	expect(() => parseSchema(input)).toThrowError("Schema array not closed");
});

test("schema syntax errors: no field value", () => {
	const input = `{ foods, things: boolean }`;
	expect(() => parseSchema(input)).toThrowError("Expected ':' but found ','");
});

test("schema syntax errors: unsupported value type", () => {
	const input = `{ foods: things }`;
	expect(() => parseSchema(input)).toThrowError("Unsupported value type 'things'");
});

test("schema syntax errors: empty input", () => {
	const input = ``;
	expect(() => parseSchema(input)).toThrowError("Expected '{' but found 'undefined'");
});

test("schema syntax errors: just whitespace", () => {
	const input = `   \n\t  `;
	expect(() => parseSchema(input)).toThrowError("Expected '{' but found 'undefined'");
});

test("schema syntax errors: field name starts with number", () => {
	const input = `{ 1field: string }`;
	expect(() => parseSchema(input)).toThrowError("Field must start with quote or alpha");
});

test("schema syntax errors: field name with special chars", () => {
	const input = `{ field-name: string }`;
	expect(() => parseSchema(input)).toThrowError("Expected ':' but found '-'");
});

test("schema syntax errors: unclosed string", () => {
	const input = `{ name: "Alice }`;
	expect(() => parseSchema(input)).toThrowError("String not closed");
});

test("schema syntax errors: invalid escape sequence", () => {
	const input = `{ quote: "Hel\\lo" }`;
	expect(() => parseSchema(input)).toThrowError("Invalid escape sequence '\\l'");
});

test("schema syntax errors: number with decimal but no digits", () => {
	const input = `{ value: 123. }`;
	expect(() => parseSchema(input)).toThrowError("Unsupported value type '123.'");
});

test("schema syntax errors: hex number with invalid chars", () => {
	const input = `{ color: 0xGHIJKL }`;
	expect(() => parseSchema(input)).toThrowError("Unsupported value type '0xGHIJKL'");
});

test("schema syntax errors: invalid date format", () => {
	const input = `{ dob: 2025-13-01 }`;
	expect(() => parseSchema(input)).toThrowError("Invalid date '2025-13-01'");
});

test("schema syntax errors: boolean with wrong case", () => {
	const input = `{ active: True }`;
	expect(() => parseSchema(input)).toThrowError("Unsupported value type 'True'");
});

test("schema syntax errors: negative without digits", () => {
	const input = `{ value: - }`;
	expect(() => parseSchema(input)).toThrowError("Unsupported value type '-'");
});

test("schema syntax errors: scientific notation missing exponent", () => {
	const input = `{ value: 1.5e }`;
	expect(() => parseSchema(input)).toThrowError("Unsupported value type '1.5e'");
});

test("schema syntax errors: multiple colons in field", () => {
	const input = `{ name:: string }`;
	expect(() => parseSchema(input)).toThrowError("Unsupported value type ':'");
});

test("schema syntax errors: array with trailing comma not followed by item", () => {
	const input = `{ items: ["a",] }`;
	expect(() => parseSchema(input)).toThrowError("Schema array not closed");
});

test("schema syntax errors: nested object not closed", () => {
	const input = `{ data: { nested: string }`;
	expect(() => parseSchema(input)).toThrowError("Schema object not closed");
});

test("schema syntax errors: nested array not closed", () => {
	const input = `{ matrix: [[int] }`;
	expect(() => parseSchema(input)).toThrowError("Schema array not closed");
});

test("schema syntax errors: object with missing colon after field name", () => {
	const input = `{ name string }`;
	expect(() => parseSchema(input)).toThrowError("Expected ':' but found 's'");
});

test("schema syntax errors: array with just opening brace", () => {
	const input = `{ items: [ }`;
	expect(() => parseSchema(input)).toThrowError("Schema array not closed");
});

test("schema syntax errors: array with missing opening brace", () => {
	const input = `{ items: int] }`;
	// TODO: a better error
	//expect(() => parseSchema(input)).toThrowError("Schema array not opened");
	expect(() => parseSchema(input)).toThrowError("Schema object not closed");
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
	expect(() => parseSchema(input)).toThrowError("Field must start with quote or alpha");
});

test("schema syntax errors: comma at start of object", () => {
	const input = `{ , name: string }`;
	expect(() => parseSchema(input)).toThrowError("Field must start with quote or alpha");
});

test("schema syntax errors: invalid time format", () => {
	const input = `{ time: 25:00 }`;
	expect(() => parseSchema(input)).toThrowError("Invalid time '25:00'");
});

test("schema syntax errors: invalid datetime format", () => {
	const input = `{ created: 2025-01-15T14:90+02:00 }`;
	expect(() => parseSchema(input)).toThrowError("Invalid date '2025-01-15T14:90+02:00'");
});

test("schema syntax errors: string with unescaped quote", () => {
	const input = `{ text: "Hello "World"" }`;
	expect(() => parseSchema(input)).toThrowError("Expected ':' but found '\"'");
});

test("schema syntax errors: unknown validator", () => {
	const input = `{ text: string required }`;
	expect(() => parseSchema(input)).toThrowError("Unsupported validator 'required'");
});
