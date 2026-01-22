import { CheckError } from "./types/CheckError";
import { createRegex } from "./utils";

// TODO: array minlen, maxlen, minval, maxval

type Validator = (
	field: string,
	value: any,
	raw: string,
	required: any,
	errors: CheckError[],
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
		minlen,
		maxlen,
		pattern,
	},
};
export default validators;

function min(field: string, value: number, raw: string, required: number, errors: CheckError[]) {
	if (value < required) {
		errors.push({
			path: [],
			message: `'${field}' must be at least ${raw}`,
		});
		return false;
	}
	return true;
}

function max(field: string, value: number, raw: string, required: number, errors: CheckError[]) {
	if (value > required) {
		errors.push({
			path: [],
			message: `'${field}' cannot be more than ${raw}`,
		});
		return false;
	}
	return true;
}

function mindate(field: string, value: Date, raw: string, required: Date, errors: CheckError[]) {
	if (value < required) {
		errors.push({
			path: [],
			message: `'${field}' must be at least ${raw}`,
		});
		return false;
	}
	return true;
}

function maxdate(field: string, value: Date, raw: string, required: Date, errors: CheckError[]) {
	if (value > required) {
		errors.push({
			path: [],
			message: `'${field}' cannot be after ${raw}`,
		});
		return false;
	}
	return true;
}

function minlen(field: string, value: string, raw: string, required: number, errors: CheckError[]) {
	if (value.length < required) {
		errors.push({
			path: [],
			message: `'${field}' must be at least ${raw} characters`,
		});
		return false;
	}
	return true;
}

function maxlen(field: string, value: string, raw: string, required: number, errors: CheckError[]) {
	if (value.length > required) {
		errors.push({
			path: [],
			message: `'${field}' cannot be more than ${raw} characters`,
		});
		return false;
	}
	return true;
}

function pattern(
	field: string,
	value: string,
	raw: string,
	required: string,
	errors: CheckError[],
) {
	const regex = createRegex(required);
	if (regex === undefined) {
		// This should never happen...
		errors.push({
			path: [],
			message: `Unsupported pattern for '${field}': ${raw}`,
		});
		return false;
	}
	if (!regex.test(value)) {
		errors.push({
			path: [],
			message: `'${field}' doesn't match pattern '${raw}'`,
		});
		return false;
	}
	return true;
}
