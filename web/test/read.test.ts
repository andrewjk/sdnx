import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { assert, expect, test } from "vitest";
import parseSchema from "../src/parseSchema";
import read from "../src/read";

const tmpDir = path.join(os.tmpdir(), "sdnx-read-test-" + Date.now());

function setupTestFiles(files: Record<string, string>): string[] {
	if (!fs.existsSync(tmpDir)) {
		fs.mkdirSync(tmpDir, { recursive: true });
	}
	const paths: string[] = [];
	for (const [name, content] of Object.entries(files)) {
		const filePath = path.join(tmpDir, name);
		const dir = path.dirname(filePath);
		if (!fs.existsSync(dir)) {
			fs.mkdirSync(dir, { recursive: true });
		}
		fs.writeFileSync(filePath, content, "utf-8");
		paths.push(filePath);
	}
	return paths;
}

function cleanupTestFiles(): void {
	if (fs.existsSync(tmpDir)) {
		fs.rmSync(tmpDir, { recursive: true, force: true });
	}
}

test.afterEach(() => {
	cleanupTestFiles();
});

test("read: successful with @schema directive", () => {
	const schema = `{ name: string, age: int }`;
	const data = `@schema("./schema.sdnx")
{ name: "Alice", age: 30 }`;

	const [_schemaPath, dataPath] = setupTestFiles({
		"schema.sdnx": schema,
		"data.sdn": data,
	});

	const result = read(dataPath);

	expect(result.ok).toBe(true);
	if (result.ok) {
		expect(result.data).toEqual({ name: "Alice", age: 30 });
	}
});

test("read: successful with explicit schema path", () => {
	const schema = `{ name: string, age: int }`;
	const data = `{ name: "Bob", age: 25 }`;

	const [schemaPath, dataPath] = setupTestFiles({
		"schema.sdnx": schema,
		"data.sdn": data,
	});

	const result = read(dataPath, schemaPath);

	expect(result.ok).toBe(true);
	if (result.ok) {
		expect(result.data).toEqual({ name: "Bob", age: 25 });
	}
});

test("read: successful with Schema object", () => {
	const schema = parseSchema(`{ name: string, age: int }`);
	assert(schema.ok);

	const data = `{ name: "Charlie", age: 35 }`;
	const [dataPath] = setupTestFiles({ "data.sdn": data });

	const result = read(dataPath, schema.data);

	expect(result.ok).toBe(true);
	if (result.ok) {
		expect(result.data).toEqual({ name: "Charlie", age: 35 });
	}
});

test("read: fails with data parse errors", () => {
	const schema = `{ name: string, age: int }`;
	const data = `@schema("./schema.sdnx")
{ name: "Alice", age: }`;

	const [_schemaPath, dataPath] = setupTestFiles({
		"schema.sdnx": schema,
		"data.sdn": data,
	});

	const result = read(dataPath);

	expect(result.ok).toBe(false);
	if (!result.ok) {
		expect(result.schemaErrors.length).toBeGreaterThan(0);
		expect(result.dataErrors).toHaveLength(0);
		expect(result.checkErrors).toHaveLength(0);
		expect(result.schemaErrors[0].message).toBeDefined();
	}
});

test("read: fails with schema parse errors", () => {
	const schema = `{ name: string, age: }`;
	const data = `@schema("./schema.sdnx")
{ name: "Alice", age: 30 }`;

	const [_schemaPath, dataPath] = setupTestFiles({
		"schema.sdnx": schema,
		"data.sdn": data,
	});

	const result = read(dataPath);

	expect(result.ok).toBe(false);
	if (!result.ok) {
		expect(result.schemaErrors.length).toBeGreaterThan(0);
		expect(result.dataErrors).toHaveLength(0);
		expect(result.checkErrors).toHaveLength(0);
	}
});

test("read: fails with validation errors", () => {
	const schema = `{ name: string, age: int min(18) }`;
	const data = `@schema("./schema.sdnx")
{ name: "Alice", age: 15 }`;

	const [_schemaPath, dataPath] = setupTestFiles({
		"schema.sdnx": schema,
		"data.sdn": data,
	});

	const result = read(dataPath);

	expect(result.ok).toBe(false);
	if (!result.ok) {
		expect(result.schemaErrors).toHaveLength(0);
		expect(result.dataErrors).toHaveLength(0);
		expect(result.checkErrors.length).toBeGreaterThan(0);
		expect(result.checkErrors[0].message).toContain("least");
	}
});

test("read: throws error when file not found", () => {
	expect(() => read("/nonexistent/path/to/file.sdn")).toThrow("File not found");
});

test("read: throws error when @schema directive missing and schema not provided", () => {
	const data = `{ name: "Alice", age: 30 }`;
	const [dataPath] = setupTestFiles({ "data.sdn": data });

	expect(() => read(dataPath)).toThrow("Schema required");
});

test("read: resolves relative schema path correctly", () => {
	const schema = `{ name: string }`;
	const data = `@schema("./schema.sdnx")
{ name: "Alice" }`;

	const [_schemaPath, dataPath] = setupTestFiles({
		"schema.sdnx": schema,
		"data.sdn": data,
	});

	const result = read(dataPath);

	expect(result.ok).toBe(true);
	if (result.ok) {
		expect(result.data).toEqual({ name: "Alice" });
	}
});

test("read: handles nested schema path", () => {
	const schema = `{ name: string }`;
	const data = `@schema("./schemas/schema.sdnx")
{ name: "Alice" }`;

	const paths = setupTestFiles({
		"schemas/schema.sdnx": schema,
		"data.sdn": data,
	});

	const result = read(paths[1]);

	expect(result.ok).toBe(true);
	if (result.ok) {
		expect(result.data).toEqual({ name: "Alice" });
	}
});

test("read: handles complex nested data", () => {
	const schema = `{
	name: string,
	age: int,
	address: { street: string, city: string },
	tags: [string]
}`;

	const data = `@schema("./schema.sdnx")
{
	name: "Alice",
	age: 30,
	address: { street: "123 Main St", city: "NYC" },
	tags: ["developer", "engineer"]
}`;

	const [_schemaPath, dataPath] = setupTestFiles({
		"schema.sdnx": schema,
		"data.sdn": data,
	});

	const result = read(dataPath);

	expect(result.ok).toBe(true);
	if (result.ok) {
		expect(result.data).toEqual({
			name: "Alice",
			age: 30,
			address: { street: "123 Main St", city: "NYC" },
			tags: ["developer", "engineer"],
		});
	}
});

test("read: includes line and char info in parse errors", () => {
	const schema = `{ name: string }`;
	const data = `@schema("./schema.sdnx")
{ name: "Alice",
age: invalid
}`;

	const [_schemaPath, dataPath] = setupTestFiles({
		"schema.sdnx": schema,
		"data.sdn": data,
	});

	const result = read(dataPath);

	expect(result.ok).toBe(false);
	if (!result.ok) {
		expect(result.schemaErrors.length).toBeGreaterThan(0);
		const error = result.schemaErrors[0];
		expect(error.line).toBeDefined();
		expect(error.char).toBeDefined();
		expect(error.index).toBeDefined();
		expect(error.length).toBeDefined();
		expect(error.message).toBeDefined();
	}
});

test("read: handles empty data file", () => {
	const schema = `{ name: string }`;
	const data = `@schema("./schema.sdnx")
{}`;

	const [_schemaPath, dataPath] = setupTestFiles({
		"schema.sdnx": schema,
		"data.sdn": data,
	});

	const result = read(dataPath);

	expect(result.ok).toBe(false);
	if (!result.ok) {
		expect(result.checkErrors.length).toBeGreaterThan(0);
	}
});

test("read: handles schema with union types", () => {
	const schema = `{ value: int | string }`;
	const data = `@schema("./schema.sdnx")
{ value: 42 }`;

	const [_schemaPath, dataPath] = setupTestFiles({
		"schema.sdnx": schema,
		"data.sdn": data,
	});

	const result = read(dataPath);

	expect(result.ok).toBe(true);
	if (result.ok) {
		expect(result.data).toEqual({ value: 42 });
	}
});

test("read: handles schema with array of objects", () => {
	const schema = `{ users: [{ name: string, age: int }] }`;
	const data = `@schema("./schema.sdnx")
{
	users: [
		{ name: "Alice", age: 30 },
		{ name: "Bob", age: 25 }
	]
}`;

	const [_schemaPath, dataPath] = setupTestFiles({
		"schema.sdnx": schema,
		"data.sdn": data,
	});

	const result = read(dataPath);

	expect(result.ok).toBe(true);
	if (result.ok) {
		expect(result.data).toEqual({
			users: [
				{ name: "Alice", age: 30 },
				{ name: "Bob", age: 25 },
			],
		});
	}
});

test("read: handles file path from cwd", () => {
	const schema = `{ name: string }`;
	const data = `@schema("./schema.sdnx")
{ name: "Alice" }`;

	const [_schemaPath, _dataPath] = setupTestFiles({
		"schema.sdnx": schema,
		"data.sdn": data,
	});

	const oldCwd = process.cwd();
	process.chdir(tmpDir);

	try {
		const result = read("data.sdn");

		expect(result.ok).toBe(true);
		if (result.ok) {
			expect(result.data).toEqual({ name: "Alice" });
		}
	} finally {
		process.chdir(oldCwd);
	}
});
