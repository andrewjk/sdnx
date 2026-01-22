import { Error } from "./check";
import { createRegex } from "./utils";

type Validator = (
	field: string,
	value: any,
	raw: string,
	required: any,
	errors: Error[],
) => boolean;

const validators: Record<string, Record<string, Validator>> = {
	bool: {},
	int: {
		min,
		max,
	},
	num: {
		min,
		max,
	},
	date: {
		min: mindate,
		max: maxdate,
	},
	string: {
		min: minlen,
		max: maxlen,
		regex,
	},
};
export default validators;

function min(field: string, value: number, raw: string, required: number, errors: Error[]) {
	if (value < required) {
		errors.push({
			path: [],
			message: `'${field}' must be at least ${raw}`,
		});
		return false;
	}
	return true;
}

function max(field: string, value: number, raw: string, required: number, errors: Error[]) {
	if (value > required) {
		errors.push({
			path: [],
			message: `'${field}' cannot be more than ${raw}`,
		});
		return false;
	}
	return true;
}

function mindate(field: string, value: Date, raw: string, required: Date, errors: Error[]) {
	if (value < required) {
		errors.push({
			path: [],
			message: `'${field}' must be at least ${raw}`,
		});
		return false;
	}
	return true;
}

function maxdate(field: string, value: Date, raw: string, required: Date, errors: Error[]) {
	if (value > required) {
		errors.push({
			path: [],
			message: `'${field}' cannot be after ${raw}`,
		});
		return false;
	}
	return true;
}

function minlen(field: string, value: string, raw: string, required: number, errors: Error[]) {
	if (value.length < required) {
		errors.push({
			path: [],
			message: `'${field}' must be at least ${raw} characters`,
		});
		return false;
	}
	return true;
}

function maxlen(field: string, value: string, raw: string, required: number, errors: Error[]) {
	if (value.length > required) {
		errors.push({
			path: [],
			message: `'${field}' cannot be more than ${raw} characters`,
		});
		return false;
	}
	return true;
}

function regex(field: string, value: string, raw: string, required: string, errors: Error[]) {
	const regexp = createRegex(required);
	if (regexp === undefined) {
		// This should never happen...
		errors.push({
			path: [],
			message: `Unsupported pattern for '${field}': ${raw}`,
		});
		return false;
	}
	if (!regexp.test(value)) {
		errors.push({
			path: [],
			message: `'${field}' doesn't match pattern '${raw}'`,
		});
		return false;
	}
	return true;
}
