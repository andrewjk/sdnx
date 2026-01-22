import convertValue from "./convertValue";
import { accept, expect, trim } from "./utils";

interface Status {
	input: string;
	i: number;
}

/**
 * Parses some structured data from a string into an object.
 *
 * @param input The input string.
 */
export default function parse(input: string): Record<PropertyKey, any> {
	let status = {
		input,
		i: 0,
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

	if (accept("{", status)) {
		return parseObject(status);
	} else {
		throw new Error(`Expected '{' but found '${status.input[status.i]}'`);
	}
}

function parseObject(status: Status) {
	let result: Record<PropertyKey, any> = {};
	const start = status.i;
	while (true) {
		trim(status);
		if (accept("}", status)) {
			break;
		} else if (status.i === status.input.length || accept("]", status)) {
			throw new Error(`Object not closed [${start}]`);
		}

		parseField(result, status);

		trim(status);
		accept(",", status);
	}
	return result;
}

function parseArray(status: Status) {
	let result: any[] = [];
	const start = status.i;
	while (true) {
		trim(status);
		if (accept("]", status)) {
			break;
		} else if (status.i === status.input.length || accept("}", status)) {
			throw new Error(`Array not closed [${start}]`);
		} else if (result.length > 0) {
			expect(",", status);
			trim(status);
		}

		const value = parseValue(status);
		result.push(value);
	}
	return result;
}

function parseField(result: Record<PropertyKey, any>, status: Status) {
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
		throw new Error(`Field must start with quote or alpha [${start}]`);
	}

	trim(status);
	expect(":", status);

	result[name] = parseValue(status);
}

function parseValue(status: Status) {
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
		return convertValue(value, start);
	}
}

function parseString(status: Status) {
	const start = status.i;
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
	let value = status.input.substring(start, status.i - 1);
	// Trim leading spaces from multiline strings
	if (value.startsWith("\n")) {
		const space = value.match(/^\s+/)![0];
		value = value.replaceAll(space, "\n").trimStart();
	}
	return value;
}

function parseComment(status: Status) {
	for (; status.i < status.input.length; status.i++) {
		if (status.input[status.i] === "\n") {
			break;
		}
	}
}

function parseMacro(status: Status) {
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
			throw new Error(`Unknown macro: '${macro}'`);
	}
}
