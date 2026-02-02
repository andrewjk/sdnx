import convertValue from "./convertValue";
import ParseException from "./types/ParseException";
import ParseFailure from "./types/ParseFailure";
import ParseStatus from "./types/ParseStatus";
import ParseSuccess from "./types/ParseSuccess";
import { accept, expect, trim } from "./utils";

/**
 * Parses some structured data from a string into an object.
 *
 * @param input The input string.
 */
export default function parse(
	input: string,
): ParseSuccess<Record<PropertyKey, any>> | ParseFailure {
	let status: ParseStatus = {
		input,
		i: 0,
		errors: [],
	};

	trim(status);

	while (true) {
		if (accept("#", status)) {
			parseComment(status);
			trim(status);
		} else if (accept("@", status)) {
			parseMacro(status);
			trim(status);
		} else {
			break;
		}
	}

	try {
		if (accept("{", status)) {
			const data = parseObject(status);
			if (status.errors.length === 0) {
				return {
					ok: true,
					data,
				};
			} else {
				return { ok: false, errors: status.errors };
			}
		} else {
			status.errors.push({
				message: `Expected '{' but found '${status.input[status.i]}'`,
				index: 0,
				length: 1,
			});
			throw new ParseException();
		}
	} catch (ex) {
		// Handle our errors and throw others
		if (ex instanceof ParseException) {
			return {
				ok: false,
				errors: status.errors,
			};
		} else {
			throw ex;
		}
	}
}

function parseObject(status: ParseStatus) {
	let result: Record<PropertyKey, any> = {};
	const start = status.i;
	while (true) {
		trim(status);
		if (accept("}", status)) {
			break;
		} else if (status.i === status.input.length || accept("]", status)) {
			status.errors.push({
				message: "Object not closed",
				index: start,
				length: 1,
			});
			throw new ParseException();
		}

		parseField(result, status);

		trim(status);
		accept(",", status);
	}
	return result;
}

function parseArray(status: ParseStatus) {
	let result: any[] = [];
	const start = status.i;
	while (true) {
		trim(status);
		if (accept("]", status)) {
			break;
		} else if (status.i === status.input.length || accept("}", status)) {
			status.errors.push({
				message: "Array not closed",
				index: start,
				length: 1,
			});
			throw new ParseException();
		} else if (result.length > 0) {
			expect(",", status);
			trim(status);
		}

		const value = parseValue(status);
		result.push(value);
	}
	return result;
}

function parseField(result: Record<PropertyKey, any>, status: ParseStatus) {
	trim(status);

	if (accept("#", status)) {
		parseComment(status);
		return;
	}

	const start = status.i;
	let name = "";

	if (accept('"', status)) {
		while (/[^"]/.test(status.input[status.i])) {
			status.i++;
		}
		status.i++;
		name = status.input.substring(start, status.i);
	} else if (/[a-zA-Z_]/.test(status.input[status.i])) {
		status.i++;
		while (/[a-zA-Z0-9_]/.test(status.input[status.i])) {
			status.i++;
		}
		name = status.input.substring(start, status.i);
	} else {
		status.errors.push({
			message: "Field must start with quote or alpha",
			index: start,
			length: 1,
		});
		throw new ParseException();
	}

	trim(status);
	expect(":", status);

	result[name] = parseValue(status);
}

function parseValue(status: ParseStatus) {
	trim(status);
	if (accept("{", status)) {
		return parseObject(status);
	} else if (accept("[", status)) {
		return parseArray(status);
	} else if (accept('"', status)) {
		return parseString(status);
	} else {
		// Look for space, `,`, `}` or `]`
		const start = status.i;
		while (/[^\s,}\]]/.test(status.input[status.i])) {
			status.i++;
		}
		const value = status.input.substring(start, status.i).trim();
		return convertValue(value, start, status.errors);
	}
}

function parseString(status: ParseStatus) {
	const start = status.i;
	for (; status.i < status.input.length; status.i++) {
		if (status.input[status.i] === "\\") {
			if (status.input[++status.i] !== '"') {
				status.errors.push({
					message: `Invalid escape sequence '\\${status.input[status.i]}'`,
					index: status.i - 1,
					length: 2,
				});
			}
		} else if (status.input[status.i] === '"') {
			break;
		}
	}
	if (status.i === status.input.length) {
		status.errors.push({
			message: "String not closed",
			index: start,
			length: 1,
		});
		throw new ParseException();
	}
	status.i++;
	let value = status.input.substring(start, status.i - 1);
	// Trim leading spaces from multiline strings
	if (value.startsWith("\n")) {
		const space = value.match(/^\s+/)![0];
		value = value.replaceAll(space, "\n").trimStart();
	}
	return value;
}

function parseComment(status: ParseStatus) {
	for (; status.i < status.input.length; status.i++) {
		if (status.input[status.i] === "\n") {
			break;
		}
	}
}

function parseMacro(status: ParseStatus) {
	// Consume until space or `(`
	const start = status.i;
	while (/[^\s(]/.test(status.input[status.i])) {
		status.i++;
	}
	const macro = status.input.substring(start, status.i);
	trim(status);
	expect("(", status);
	switch (macro) {
		case "schema":
			trim(status);
			// Consume until space or `)`
			while (/[^\s)]/.test(status.input[status.i])) {
				status.i++;
			}
			trim(status);
			expect(")", status);
			break;
		default:
			// Consume until `)`
			const start = status.i - macro.length;
			let level = 1;
			for (; status.i < status.input.length; status.i++) {
				const char = status.input[status.i];
				if (char === "(" && status.input[status.i - 1] !== "\\") {
					level++;
				} else if (char === ")" && status.input[status.i - 1] !== "\\") {
					level--;
					if (level === 0) break;
				}
			}
			status.errors.push({
				message: `Unknown macro: '${macro}'`,
				index: start,
				length: macro.length,
			});
	}
}
