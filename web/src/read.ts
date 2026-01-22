import fs from "node:fs";
import path from "node:path";
import check from "./check";
import parse from "./parse";
import parseSchema from "./parseSchema";
import { CheckError } from "./types/CheckError";
import { Schema } from "./types/Schema";

interface ReadSuccess {
	ok: true;
	data: Record<string, any>;
}

interface ReadFailure {
	ok: false;
	data: Record<string, any>;
	errors: CheckError[];
}

export default function read(file: string, schema?: string | Schema): ReadSuccess | ReadFailure {
	file = locate(file);

	const contents = fs.readFileSync(file, "utf-8");
	const data = parse(contents);

	// If there's a @schema directive, try to load the schema from there
	if (schema === undefined) {
		const match = contents.match(/^\s*@schema\("(.+?)"\)/);
		if (match === null) {
			throw new Error("Schema required");
		}
		schema = path.resolve(path.dirname(file), match[1]);
	}

	// TODO: Handle fetching from a URL
	if (typeof schema === "string") {
		schema = locate(schema);
		const schemaContents = fs.readFileSync(schema, "utf-8");
		schema = parseSchema(schemaContents);
	}

	const checked = check(data, schema);

	return Object.assign(checked, { data });
}

function locate(file: string) {
	if (!fs.existsSync(file)) {
		const cwd = process.cwd();
		file = path.join(cwd, file);
		if (!fs.existsSync(file)) {
			throw new Error(`File not found: ${file}`);
		}
	}
	return file;
}
