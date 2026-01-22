import convertValue from "./convertValue";
import { AnySchema } from "./types/AnySchema";
import { ArraySchema } from "./types/ArraySchema";
import { FieldSchema } from "./types/FieldSchema";
import { MixSchema } from "./types/MixSchema";
import { ObjectSchema } from "./types/ObjectSchema";
import { Schema, SchemaValue } from "./types/Schema";
import { UnionSchema } from "./types/UnionSchema";
import { accept, expect, trim } from "./utils";
import validators from "./validators";

interface Status {
	input: string;
	i: number;
	description: string;
	mix: number;
	any: number;
}

/**
 * Parses some structured data from a string into an object.
 *
 * @param input The input string.
 */
export default function parseSchema(input: string): Schema {
	let status = {
		input,
		i: 0,
		description: "",
		mix: 1,
		any: 1,
	};

	trim(status);

	if (accept("{", status)) {
		return parseObject(status);
	} else {
		throw new Error(`Expected '{' but found '${status.input[status.i]}'`);
	}
}

function parseObject(status: Status): Schema {
	let result: Schema = {};
	const start = status.i;
	while (true) {
		trim(status);
		if (accept("}", status)) {
			break;
		} else if (status.i === status.input.length || accept("]", status)) {
			throw new Error(`Schema object not closed [${start}]`);
		}

		parseField(result, status);

		trim(status);
		accept(",", status);
	}
	return result;
}

function parseArray(status: Status): SchemaValue {
	trim(status);
	const start = status.i;

	if (accept("]", status)) {
		throw new Error(`Schema array empty [${start}]`);
	} else if (accept("}", status)) {
		throw new Error(`Schema array not closed [${start}]`);
	}

	let value = parseValue(status);

	trim(status);
	if (status.i === status.input.length || !accept("]", status)) {
		throw new Error(`Schema array not closed [${start}]`);
	}

	return value;
}

function parseField(result: Record<string, SchemaValue>, status: Status): void {
	trim(status);

	const start = status.i;

	// Check for comments
	if (accept("#", status)) {
		const addDescription = accept("#", status);
		for (; status.i < status.input.length; status.i++) {
			if (status.input[status.i] === "\n") {
				break;
			}
		}
		if (addDescription) {
			status.description += status.input.substring(start + 2, status.i);
		}
		return;
	}

	// Check for macros
	if (accept("@", status)) {
		// Consume until space or `(`
		const start = status.i;
		while (/[^\s(]/.test(status.input[status.i])) {
			status.i++;
		}
		const macro = status.input.substring(start, status.i);
		trim(status);
		expect("(", status);
		switch (macro) {
			case "mix":
				expect("{", status);
				const mixResult: MixSchema = {
					type: "mix",
					inner: [parseObject(status)],
				};
				result[`mix$${status.mix++}`] = mixResult;
				trim(status);
				while (accept("|", status)) {
					trim(status);
					expect("{", status);
					mixResult.inner.push(parseObject(status));
					trim(status);
				}
				expect(")", status);
				break;
			case "any":
				trim(status);
				// Consume until space or `)`
				const start = status.i;
				let level = 1;
				for (; status.i < status.input.length; status.i++) {
					const char = status.input[status.i];
					if (char === "(" && status.input[status.i - 1] !== "\\") {
						level++;
					} else if (char === ")" && status.input[status.i - 1] !== "\\") {
						level--;
						if (level === 0) break;
					} else if (/\s/.test(char)) {
						break;
					}
				}
				const pattern = status.input.substring(start, status.i);
				trim(status);
				expect(")", status);
				expect(":", status);
				const anyResult: AnySchema = {
					type: pattern,
					inner: parseValue(status),
				};
				result[`any$${status.mix++}`] = anyResult;
				break;
			default:
				throw new Error(`Unknown macro: '${macro}'`);
		}
		return;
	}

	let name = "";
	if (accept('"', status)) {
		name = parseString(status);
	} else {
		if (/[^a-zA-Z_]/.test(status.input[status.i])) {
			throw new Error(`Field must start with quote or alpha [${start}]`);
		}
		status.i++;
		while (/[a-zA-Z0-9_]/.test(status.input[status.i])) {
			status.i++;
		}
		name = status.input.substring(start, status.i);
	}

	trim(status);
	expect(":", status);

	result[name] = parseValue(status);
}

function parseValue(status: Status): SchemaValue {
	let value = parseSingleValue(status);

	trim(status);
	if (accept("|", status)) {
		let unionValue: UnionSchema = {
			type: "union",
			inner: [value],
		};
		while (true) {
			trim(status);
			unionValue.inner.push(parseSingleValue(status));
			trim(status);

			if (!accept("|", status)) {
				break;
			}
		}
		value = unionValue;
	}

	return value;
}

function parseSingleValue(status: Status): SchemaValue {
	trim(status);
	if (accept("{", status)) {
		const result: ObjectSchema = {
			type: "object",
			inner: parseObject(status),
		};
		return result;
	} else if (accept("[", status)) {
		const result: ArraySchema = {
			type: "array",
			inner: parseArray(status),
		};
		return result;
	} else if (accept('"', status)) {
		return { type: parseString(status, true) };
	} else {
		return parseType(status);
	}
}
function parseType(status: Status) {
	// Parse and check the type
	const start = status.i;
	while (status.i < status.input.length && /[^\s|,}\]]/.test(status.input[status.i])) {
		status.i++;
	}
	const type = status.input.substring(start, status.i).trim();
	if (!["undef", "null", "bool", "int", "num", "string", "date"].includes(type)) {
		convertValue(type, -1);
	}

	// Create the field schema
	let result: FieldSchema = { type };
	if (status.description !== "") {
		result.description = status.description.trim();
		status.description = "";
	}

	// Add validators
	trim(status);
	while (status.i < status.input.length && /[^|,}\]]/.test(status.input[status.i])) {
		// Parse and check the validator
		const start = status.i;
		while (status.i < status.input.length && /[^\s|,}\](]/.test(status.input[status.i])) {
			status.i++;
		}
		const validator = status.input.substring(start, status.i);
		if (validators[type] && !validators[type][validator]) {
			throw new Error(`Unsupported validator '${validator}'`);
		}

		let raw = "true";
		let required = true;

		trim(status);
		if (accept("(", status)) {
			trim(status);
			if (accept('"', status)) {
				raw = parseString(status, true);
				required = convertValue(raw, -1);
			} else if (accept("/", status)) {
				raw = parseRegex(status);
				required = convertValue(raw, -1);
			} else {
				// Consume until a space or closing bracket
				const start = status.i;
				while (status.i < status.input.length && /[^\s)]/.test(status.input[status.i])) {
					status.i++;
				}
				raw = status.input.substring(start, status.i);
				required = convertValue(raw, -1);
			}
			trim(status);
			expect(")", status);
			trim(status);
		}
		(result.validators ??= {})[validator] = { raw, required };
	}
	return result;
}

function parseString(status: Status, withQuotes = false) {
	const start = withQuotes ? status.i - 1 : status.i;
	for (; status.i < status.input.length; status.i++) {
		if (status.input[status.i] === "\\") {
			if (status.input[++status.i] !== '"') {
				throw new Error(`Invalid escape sequence '\\${status.input[status.i]}'`);
			}
		} else if (status.input[status.i] === '"') {
			break;
		}
	}
	if (status.i === status.input.length) {
		throw new Error(`String not closed [${start}]`);
	}
	status.i++;
	const end = withQuotes ? status.i : status.i - 1;
	return status.input.substring(start, end);
}

function parseRegex(status: Status) {
	const start = status.i - 1;
	while (
		status.i < status.input.length &&
		!(status.input[status.i] === "/" && status.input[status.i - 1] !== "\\")
	) {
		status.i++;
	}
	if (status.i === status.input.length) {
		throw new Error(`Regex not closed [${start}]`);
	}
	while (status.i < status.input.length && /[^\s)]/.test(status.input[status.i])) {
		status.i++;
	}
	return status.input.substring(start, status.i);
}
