import convertValue from "./convertValue";
import ArraySchema from "./types/ArraySchema";
import DefSchema from "./types/DefSchema";
import FieldSchema from "./types/FieldSchema";
import MixSchema from "./types/MixSchema";
import ObjectSchema from "./types/ObjectSchema";
import ParseException from "./types/ParseException";
import ParseFailure from "./types/ParseFailure";
import ParseStatus from "./types/ParseStatus";
import ParseSuccess from "./types/ParseSuccess";
import PropsSchema from "./types/PropsSchema";
import RefSchema from "./types/RefSchema";
import Schema from "./types/Schema";
import SchemaValue from "./types/SchemaValue";
import UnionSchema from "./types/UnionSchema";
import { accept, expect, trim } from "./utils";
import validators from "./validators";

interface ParseSchemaStatus extends ParseStatus {
	description: string;
	def: number;
	mix: number;
	any: number;
	refs: Set<string>;
}

/**
 * Parses some structured data from a string into an object.
 *
 * @param input The input string.
 */
export default function parseSchema(input: string): ParseSuccess<Schema> | ParseFailure {
	let status: ParseSchemaStatus = {
		input,
		i: 0,
		errors: [],
		description: "",
		def: 1,
		mix: 1,
		any: 1,
		refs: new Set(),
	};

	trim(status);

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

function parseObject(status: ParseSchemaStatus): Schema {
	let result: Schema = {};
	const start = status.i;
	while (true) {
		trim(status);
		if (accept("}", status)) {
			break;
		} else if (status.i === status.input.length || accept("]", status)) {
			status.errors.push({
				message: "Schema object not closed",
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

function parseArray(status: ParseSchemaStatus): SchemaValue {
	trim(status);
	const start = status.i;

	if (accept("]", status)) {
		status.errors.push({
			message: "Schema array empty",
			index: start,
			length: status.i - start,
		});
	} else if (accept("}", status)) {
		status.errors.push({
			message: "Schema array not closed",
			index: start,
			length: 1,
		});
		throw new ParseException();
	}

	let value = parseValue(status);

	trim(status);
	if (status.i === status.input.length || !accept("]", status)) {
		status.errors.push({
			message: "Schema array not closed",
			index: start,
			length: 1,
		});
		throw new ParseException();
	}

	return value;
}

function parseField(result: Record<string, SchemaValue>, status: ParseSchemaStatus): void {
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
			case "def": {
				trim(status);
				const start = status.i;
				while (status.i < status.input.length && /[^)]/.test(status.input[status.i])) {
					status.i++;
				}
				const ref = status.input.substring(start, status.i).trim();
				// TODO: Should allow any valid prop name, including surrounded by quotes
				if (/[:\s]/.test(ref)) {
					status.errors.push({
						message: `Invalid reference name '${ref}'`,
						index: start,
						length: ref.length,
					});
				}
				status.i++;
				trim(status);
				expect(":", status);
				trim(status);
				expect("{", status);
				status.refs.add(ref);
				const defSchema: DefSchema = {
					type: "def",
					name: ref,
					inner: parseObject(status),
				};
				result[`def$${status.def++}`] = defSchema;
				break;
			}
			case "mix": {
				trim(status);
				const mixSchema: MixSchema = {
					type: "mix",
					inner: [],
				};
				while (true) {
					trim(status);
					if (accept("{", status)) {
						mixSchema.inner.push(parseObject(status));
					} else {
						const start = status.i;
						while (status.i < status.input.length && !/[|)]/.test(status.input[status.i])) {
							status.i++;
						}
						const ref = status.input.substring(start, status.i).trim();
						if (status.refs.has(ref)) {
							const refSchema: RefSchema = {
								type: "ref",
								inner: ref,
							};
							const refResult: Record<string, RefSchema> = {};
							refResult["ref$1"] = refSchema;
							mixSchema.inner.push(refResult);
						} else {
							status.errors.push({
								message: `Unknown reference: '${ref}'`,
								index: start,
								length: ref.length,
							});
						}
					}
					trim(status);
					if (!accept("|", status)) {
						break;
					}
				}
				expect(")", status);
				result[`mix$${status.mix++}`] = mixSchema;
				break;
			}
			case "props": {
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
				trim(status);
				expect(":", status);
				const anyResult: PropsSchema = {
					type: pattern,
					inner: parseValue(status),
				};
				result[`props$${status.mix++}`] = anyResult;
				break;
			}
			default: {
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
		return;
	}

	let name = "";
	if (accept('"', status)) {
		name = parseString(status);
	} else {
		if (/[^a-zA-Z_]/.test(status.input[status.i])) {
			status.errors.push({
				message: "Field must start with quote or alpha",
				index: start,
				length: 1,
			});
			throw new ParseException();
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

function parseValue(status: ParseSchemaStatus): SchemaValue {
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

function parseSingleValue(status: ParseSchemaStatus): SchemaValue {
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
		parseValidators(result, status);
		return result;
	} else if (accept('"', status)) {
		return { type: parseString(status, true) };
	} else {
		return parseType(status);
	}
}

function parseType(status: ParseSchemaStatus) {
	// Parse and check the type
	const start = status.i;
	while (status.i < status.input.length && /[^\s|,}\]]/.test(status.input[status.i])) {
		status.i++;
	}
	const type = status.input.substring(start, status.i).trim();
	if (
		!["undef", "null", "bool", "int", "num", "string", "date"].includes(type) &&
		!status.refs.has(type)
	) {
		convertValue(type, start, status.errors);
	}

	// Create the field schema
	let result: FieldSchema = { type };
	if (status.description !== "") {
		result.description = status.description.trim();
		status.description = "";
	}

	parseValidators(result, status);

	return result;
}

function parseValidators(field: FieldSchema, status: ParseSchemaStatus) {
	// Add validators
	trim(status);
	while (status.i < status.input.length && /[^|,}\]]/.test(status.input[status.i])) {
		// Parse and check the validator
		const start = status.i;
		while (status.i < status.input.length && /[^\s|,}\](]/.test(status.input[status.i])) {
			status.i++;
		}
		const validator = status.input.substring(start, status.i);
		if (validators[field.type] && !validators[field.type][validator]) {
			status.errors.push({
				message: `Unsupported validator '${validator}'`,
				index: start,
				length: status.i - start,
			});
		}

		let raw = "true";
		let required = true;

		trim(status);
		if (accept("(", status)) {
			trim(status);
			const start = status.i;
			if (accept('"', status)) {
				raw = parseString(status, true);
				required = convertValue(raw, start, status.errors);
			} else if (accept("/", status)) {
				raw = parseRegex(status);
				required = convertValue(raw, start, status.errors);
			} else {
				// Consume until a space or closing bracket
				const start = status.i;
				while (status.i < status.input.length && /[^\s)]/.test(status.input[status.i])) {
					status.i++;
				}
				raw = status.input.substring(start, status.i);
				required = convertValue(raw, start, status.errors);
			}
			trim(status);
			expect(")", status);
			trim(status);
		}
		(field.validators ??= {})[validator] = { raw, required };
	}
}

function parseString(status: ParseSchemaStatus, withQuotes = false) {
	const start = withQuotes ? status.i - 1 : status.i;
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
	const end = withQuotes ? status.i : status.i - 1;
	return status.input.substring(start, end);
}

function parseRegex(status: ParseSchemaStatus) {
	const start = status.i - 1;
	while (
		status.i < status.input.length &&
		!(status.input[status.i] === "/" && status.input[status.i - 1] !== "\\")
	) {
		status.i++;
	}
	if (status.i === status.input.length) {
		status.errors.push({
			message: "Pattern not closed",
			index: start,
			length: 1,
		});
		throw new ParseException();
	}
	while (status.i < status.input.length && /[^\s)]/.test(status.input[status.i])) {
		status.i++;
	}
	return status.input.substring(start, status.i);
}
