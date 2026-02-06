import fs from "node:fs";
import path from "node:path";
import check from "./check";
import parse from "./parse";
import parseSchema from "./parseSchema";
import CheckError from "./types/CheckError";
import ParseError from "./types/ParseError";
import ReadError from "./types/ReadError";
import Schema from "./types/Schema";

interface ReadSuccess {
	ok: true;
	data: Record<string, any>;
}

interface ReadFailure {
	ok: false;
	schemaErrors: ReadError[];
	dataErrors: ReadError[];
	checkErrors: CheckError[];
}

export default function read(file: string, schema?: string | Schema): ReadSuccess | ReadFailure {
	file = locate(file);

	const contents = fs.readFileSync(file, "utf-8");
	const parsed = parse(contents);
	if (!parsed.ok) {
		return {
			ok: false,
			schemaErrors: [],
			dataErrors: parsed.errors.map((e) => buildReadError(e, contents)),
			checkErrors: [],
		};
	}

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
		const schemaParsed = parseSchema(schemaContents);
		if (schemaParsed.ok) {
			schema = schemaParsed.data;
		} else {
			return {
				ok: false,
				schemaErrors: schemaParsed.errors.map((e) => buildReadError(e, schemaContents)),
				dataErrors: [],
				checkErrors: [],
			};
		}
	}

	const checked = check(parsed.data, schema);
	if (checked.ok) {
		return {
			ok: true,
			data: parsed.data,
		};
	} else {
		return {
			ok: false,
			schemaErrors: [],
			dataErrors: [],
			checkErrors: checked.errors,
		};
	}
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

function buildReadError(e: ParseError, contents: string): ReadError {
	let lineIndex = e.index;
	while (lineIndex >= 0 && contents[lineIndex] !== "\n") {
		lineIndex--;
	}
	lineIndex++;
	let lineEndIndex = e.index;
	while (lineEndIndex < contents.length && contents[lineEndIndex] !== "\n") {
		lineEndIndex++;
	}
	return {
		message: e.message,
		index: e.index,
		length: e.length,
		line: contents.substring(lineIndex, lineEndIndex),
		char: e.index - lineIndex,
	};
}
