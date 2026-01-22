import { AnySchema } from "./types/AnySchema";
import { ArraySchema } from "./types/ArraySchema";
import { FieldSchema } from "./types/FieldSchema";
import { MixSchema } from "./types/MixSchema";
import { ObjectSchema } from "./types/ObjectSchema";
import { Schema, SchemaValue } from "./types/Schema";
import { UnionSchema } from "./types/UnionSchema";
import { createRegex } from "./utils";
import validators from "./validators";

interface CheckSuccess {
	ok: true;
}

interface CheckFailure {
	ok: false;
	errors: Error[];
}

export interface Error {
	path: string[];
	message: string;
}

// TODO:
//interface Status {
//	path: string[];
//	errors: Error[];
//}

export default function check(
	input: Record<PropertyKey, unknown>,
	schema: Schema,
): CheckSuccess | CheckFailure {
	let errors: Error[] = [];

	checkObjectSchemaInner(input, schema, errors);

	if (errors.length === 0) {
		return { ok: true };
	} else {
		return { ok: false, errors };
	}
}

function checkObjectSchema(
	input: Record<PropertyKey, unknown>,
	schema: ObjectSchema,
	errors: Error[],
): boolean {
	return checkObjectSchemaInner(input, schema.inner, errors);
}

function checkObjectSchemaInner(
	input: Record<PropertyKey, unknown>,
	schema: Schema,
	errors: Error[],
): boolean {
	let result = true;
	for (let [field, fieldSchema] of Object.entries(schema)) {
		if (field.startsWith("mix$")) {
			if (!checkMixSchema(input, fieldSchema as MixSchema, errors)) {
				result = false;
			}
		} else if (field.startsWith("any$")) {
			if (!checkAnySchema(input, fieldSchema as AnySchema, field, errors)) {
				result = false;
			}
		} else {
			const value = input[field];
			if (!checkFieldSchema(value, fieldSchema, field, errors)) {
				result = false;
			}
		}
	}
	return result;
}

function checkArraySchema(
	input: Record<PropertyKey, unknown>[],
	schema: ArraySchema,
	errors: Error[],
): boolean {
	let result = true;
	for (let [i, value] of input.entries()) {
		if (!checkFieldSchema(value, schema.inner, i.toString(), errors)) {
			result = false;
		}
	}
	return result;
}

function checkUnionSchema(value: unknown, schema: UnionSchema, field: string, errors: Error[]) {
	let fieldErrors: Error[] = [];
	let ok = false;
	for (let fs of schema.inner) {
		if (checkFieldSchema(value, fs, field, fieldErrors)) {
			ok = true;
			break;
		}
	}
	if (!ok) {
		errors.push({
			path: [],
			message: fieldErrors.map((e) => e.message).join(" | "),
		});
	}
	return ok;
}

function checkMixSchema(input: Record<PropertyKey, unknown>, schema: MixSchema, errors: Error[]) {
	let fieldErrors: Error[] = [];
	let ok = false;
	for (let fs of schema.inner) {
		const mixResult = check(input, fs);
		if (mixResult.ok) {
			ok = true;
			break;
		} else {
			fieldErrors.push({
				path: [],
				message: mixResult.errors.map((e) => e.message).join(" & "),
			});
		}
	}
	if (!ok) {
		errors.push({
			path: [],
			message: fieldErrors.map((e) => e.message).join(" | "),
		});
	}
	return ok;
}

function checkAnySchema(
	input: Record<PropertyKey, unknown>,
	schema: AnySchema,
	field: string,
	errors: Error[],
) {
	let result = true;
	for (let [anyField, value] of Object.entries(input)) {
		if (schema.type) {
			// PERF: could cache this
			const regexp = createRegex(schema.type);
			if (regexp === undefined) {
				// This should never happen...
				errors.push({
					path: [],
					message: `Unsupported pattern for '${field}': ${schema.type}`,
				});
				return false;
			}
			if (!regexp.test(anyField)) {
				errors.push({
					path: [],
					message: `'${anyField}' name doesn't match pattern '${schema.type}'`,
				});
				return false;
			}
		}

		// Run the field's validators
		if (!checkFieldSchema(value, schema.inner, anyField, errors)) {
			result = false;
		}
	}
	return result;
}

function checkFieldSchema(
	value: unknown,
	schema: SchemaValue,
	field: string,
	errors: Error[],
): boolean {
	if (schema.type === "object") {
		if (value === null || typeof value !== "object") {
			errors.push({
				path: [],
				message: `'${field}' must be an object`,
			});
			return false;
		}
		return checkObjectSchema(value as Record<PropertyKey, unknown>, schema as ObjectSchema, errors);
	} else if (schema.type === "array") {
		if (!Array.isArray(value)) {
			errors.push({
				path: [],
				message: `'${field}' must be an array`,
			});
			return false;
		}
		return checkArraySchema(value, schema as ArraySchema, errors);
	} else if (schema.type === "union") {
		return checkUnionSchema(value, schema as UnionSchema, field, errors);
	} else {
		return checkFieldSchemaValue(value, schema, field, errors);
	}
}

function checkFieldSchemaValue(
	value: unknown,
	schema: FieldSchema,
	field: string,
	errors: Error[],
): boolean {
	if (value === undefined && schema.type !== "undef") {
		errors.push({
			path: [],
			message: `Field not found: ${field}`,
		});
		return false;
	}

	// Check the value's type
	switch (schema.type) {
		case "undef":
			if (value !== undefined) {
				errors.push({
					path: [],
					message: `'${field}' must be undefined`,
				});
				return false;
			}
			break;
		case "bool":
			if (typeof value !== "boolean") {
				errors.push({
					path: [],
					message: `'${field}' must be a boolean value`,
				});
				return false;
			}
			break;
		case "int":
			if (typeof value !== "number" || !Number.isInteger(value)) {
				errors.push({
					path: [],
					message: `'${field}' must be an integer value`,
				});
				return false;
			}
			break;
		case "num":
			if (typeof value !== "number") {
				errors.push({
					path: [],
					message: `'${field}' must be a number value`,
				});
				return false;
			}
			break;
		case "date":
			if (value instanceof Date === false) {
				errors.push({
					path: [],
					message: `'${field}' must be a date value`,
				});
				return false;
			}
			break;
		case "string":
			if (typeof value !== "string") {
				errors.push({
					path: [],
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
				errors.push({
					path: [],
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
				if (!validate(field, value, raw, required, errors)) {
					return false;
				}
			} else {
				// This should never happen...
				errors.push({
					path: [],
					message: `Unsupported validation method for '${field}': ${method}`,
				});
				return false;
			}
		}
	}

	return true;
}
