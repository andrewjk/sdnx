import ArraySchema from "./types/ArraySchema";
import CheckError from "./types/CheckError";
import CheckStatus from "./types/CheckStatus";
import DefSchema from "./types/DefSchema";
import FieldSchema from "./types/FieldSchema";
import MixSchema from "./types/MixSchema";
import ObjectSchema from "./types/ObjectSchema";
import PropsSchema from "./types/PropsSchema";
import RefSchema from "./types/RefSchema";
import Schema from "./types/Schema";
import SchemaValue from "./types/SchemaValue";
import UnionSchema from "./types/UnionSchema";
import { createRegex } from "./utils";
import validators from "./validators";

interface CheckSuccess {
	ok: true;
}

interface CheckFailure {
	ok: false;
	errors: CheckError[];
}

export default function check(
	input: Record<PropertyKey, unknown>,
	schema: Schema,
): CheckSuccess | CheckFailure {
	let status: CheckStatus = {
		path: [],
		errors: [],
		defs: {},
	};

	checkObjectSchemaInner(input, schema, status);

	if (status.errors.length === 0) {
		return { ok: true };
	} else {
		return { ok: false, errors: status.errors };
	}
}

function checkObjectSchema(
	input: Record<PropertyKey, unknown>,
	schema: ObjectSchema,
	status: CheckStatus,
): boolean {
	return checkObjectSchemaInner(input, schema.inner, status);
}

function checkObjectSchemaInner(
	input: Record<PropertyKey, unknown>,
	schema: Schema,
	status: CheckStatus,
): boolean {
	let result = true;
	for (let [field, fieldSchema] of Object.entries(schema)) {
		status.path.push(field);
		if (field.startsWith("def$")) {
			// Add it to the status for use when it's referenced
			status.defs[(fieldSchema as DefSchema).name] = (fieldSchema as DefSchema).inner;
		} else if (field.startsWith("ref$")) {
			if (!checkRefSchema(input, fieldSchema as RefSchema, status)) {
				result = false;
			}
		} else if (field.startsWith("mix$")) {
			if (!checkMixSchema(input, fieldSchema as MixSchema, status)) {
				result = false;
			}
		} else if (field.startsWith("props$")) {
			if (!checkPropsSchema(input, fieldSchema as PropsSchema, field, status)) {
				result = false;
			}
		} else {
			const value = input[field];
			if (!checkFieldSchema(value, fieldSchema, field, status)) {
				result = false;
			}
		}
		status.path.pop();
	}
	return result;
}

function checkArraySchema(
	input: Record<PropertyKey, unknown>[],
	schema: ArraySchema,
	status: CheckStatus,
): boolean {
	let result = true;
	for (let [i, value] of input.entries()) {
		status.path.push(String(i));
		if (!checkFieldSchema(value, schema.inner, i.toString(), status)) {
			result = false;
		}
		status.path.pop();
	}
	return result;
}

function checkUnionSchema(value: unknown, schema: UnionSchema, field: string, status: CheckStatus) {
	let fieldStatus: CheckStatus = {
		path: [...status.path],
		errors: [],
		defs: status.defs,
	};
	let ok = false;
	for (let fs of schema.inner) {
		if (checkFieldSchema(value, fs, field, fieldStatus)) {
			ok = true;
			break;
		}
	}
	if (!ok) {
		status.errors.push({
			path: [...status.path],
			message: fieldStatus.errors.map((e) => e.message).join(" | "),
		});
	}
	return ok;
}

function checkRefSchema(input: Record<PropertyKey, unknown>, ref: RefSchema, status: CheckStatus) {
	let def = status.defs[ref.inner];
	if (def === undefined) {
		// This should never happen...
		status.errors.push({
			path: [...status.path],
			message: `Undefined def: ${ref}`,
		});
		return false;
	}

	return checkObjectSchemaInner(input, def, status);
}

function checkMixSchema(
	input: Record<PropertyKey, unknown>,
	schema: MixSchema,
	status: CheckStatus,
) {
	/*
	let fieldErrors: CheckError[] = [];
	let ok = false;
	for (let fs of schema.inner) {
		const mixResult = check(input, fs);
		if (mixResult.ok) {
			ok = true;
			break;
		} else {
			fieldErrors.push({
				path: [...status.path],
				message: mixResult.errors.map((e) => e.message).join(" & "),
			});
		}
	}
	if (!ok) {
		status.errors.push({
			path: [...status.path],
			message: fieldErrors.map((e) => e.message).join(" | "),
		});
	}
	return ok;
	*/
	let fieldErrors: CheckError[] = [];
	let ok = false;
	for (let fs of schema.inner) {
		let fieldStatus: CheckStatus = {
			path: [...status.path],
			errors: [],
			defs: status.defs,
		};
		if (checkObjectSchemaInner(input, fs, fieldStatus)) {
			ok = true;
			break;
		} else {
			fieldErrors.push({
				path: [...status.path],
				message: fieldStatus.errors.map((e) => e.message).join(" & "),
			});
		}
	}
	if (!ok) {
		status.errors.push({
			path: [...status.path],
			message: fieldErrors.map((e) => e.message).join(" | "),
		});
	}
	return ok;
}

function checkPropsSchema(
	input: Record<PropertyKey, unknown>,
	schema: PropsSchema,
	field: string,
	status: CheckStatus,
) {
	let result = true;
	for (let [anyField, value] of Object.entries(input)) {
		if (schema.type) {
			// PERF: could cache this
			const regexp = createRegex(schema.type);
			if (regexp === undefined) {
				// This should never happen...
				status.errors.push({
					path: [...status.path],
					message: `Unsupported pattern for '${field}': ${schema.type}`,
				});
				return false;
			}
			if (!regexp.test(anyField)) {
				status.errors.push({
					path: [...status.path],
					message: `'${anyField}' name doesn't match pattern '${schema.type}'`,
				});
				return false;
			}
		}

		// Run the field's validators
		if (!checkFieldSchema(value, schema.inner, anyField, status)) {
			result = false;
		}
	}
	return result;
}

function checkFieldSchema(
	value: unknown,
	schema: SchemaValue,
	field: string,
	status: CheckStatus,
): boolean {
	if (schema.type === "object") {
		if (value === null || typeof value !== "object") {
			status.errors.push({
				path: [...status.path],
				message: `'${field}' must be an object`,
			});
			return false;
		}
		return checkObjectSchema(value as Record<PropertyKey, unknown>, schema as ObjectSchema, status);
	} else if (schema.type === "array") {
		if (!Array.isArray(value)) {
			status.errors.push({
				path: [...status.path],
				message: `'${field}' must be an array`,
			});
			return false;
		}
		return checkArraySchema(value, schema as ArraySchema, status);
	} else if (schema.type === "union") {
		return checkUnionSchema(value, schema as UnionSchema, field, status);
	} else {
		return checkFieldSchemaValue(value, schema, field, status);
	}
}

function checkFieldSchemaValue(
	value: unknown,
	schema: FieldSchema,
	field: string,
	status: CheckStatus,
): boolean {
	if (value === undefined && schema.type !== "undef") {
		status.errors.push({
			path: [...status.path],
			message: `Field not found: ${field}`,
		});
		return false;
	}

	// Check the value's type
	switch (schema.type) {
		case "undef":
			if (value !== undefined) {
				status.errors.push({
					path: [...status.path],
					message: `'${field}' must be undefined`,
				});
				return false;
			}
			break;
		case "bool":
			if (typeof value !== "boolean") {
				status.errors.push({
					path: [...status.path],
					message: `'${field}' must be a boolean value`,
				});
				return false;
			}
			break;
		case "int":
			if (typeof value !== "number" || !Number.isInteger(value)) {
				status.errors.push({
					path: [...status.path],
					message: `'${field}' must be an integer value`,
				});
				return false;
			}
			break;
		case "num":
			if (typeof value !== "number") {
				status.errors.push({
					path: [...status.path],
					message: `'${field}' must be a number value`,
				});
				return false;
			}
			break;
		case "date":
			if (value instanceof Date === false) {
				status.errors.push({
					path: [...status.path],
					message: `'${field}' must be a date value`,
				});
				return false;
			}
			break;
		case "string":
			if (typeof value !== "string") {
				status.errors.push({
					path: [...status.path],
					message: `'${field}' must be a string value`,
				});
				return false;
			}
			break;
		default:
			// It may be a fixed value e.g. `true`
			let expectedType = schema.type;
			if (expectedType.startsWith('"') && expectedType.endsWith('"')) {
				expectedType = expectedType.substring(1, expectedType.length - 1);
			}
			if (String(expectedType) !== String(value)) {
				status.errors.push({
					path: [...status.path],
					message: `'${field}' must be '${expectedType}'`,
				});
				return false;
			}

			// There can't be any more validators after a fixed value
			return true;
	}

	// Run the validators
	if (schema.validators !== undefined) {
		for (let [method, { raw, required }] of Object.entries(schema.validators)) {
			if (method === "type" || method === "description") {
				continue;
			}

			const validate = validators[schema.type][method];
			if (validate !== undefined) {
				if (!validate(field, value, raw, required, status)) {
					return false;
				}
			} else {
				// This should never happen...
				status.errors.push({
					path: [...status.path],
					message: `Unsupported validation method for '${field}': ${method}`,
				});
				return false;
			}
		}
	}

	return true;
}
