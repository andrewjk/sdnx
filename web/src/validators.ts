import CheckStatus from "./types/CheckStatus";
import { createRegex } from "./utils";

// TODO: array minlen, maxlen, minval, maxval

type ValidatorFunction = (
	field: string,
	value: any,
	raw: string,
	required: any,
	status: CheckStatus,
) => boolean;

const validators: Record<string, Record<string, ValidatorFunction>> = {
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

function min(field: string, value: number, raw: string, required: number, status: CheckStatus) {
	if (value < required) {
		status.errors.push({
			path: [...status.path],
			message: `'${field}' must be at least ${raw}`,
		});
		return false;
	}
	return true;
}

function max(field: string, value: number, raw: string, required: number, status: CheckStatus) {
	if (value > required) {
		status.errors.push({
			path: [...status.path],
			message: `'${field}' cannot be more than ${raw}`,
		});
		return false;
	}
	return true;
}

function mindate(field: string, value: Date, raw: string, required: Date, status: CheckStatus) {
	if (value < required) {
		status.errors.push({
			path: [...status.path],
			message: `'${field}' must be at least ${raw}`,
		});
		return false;
	}
	return true;
}

function maxdate(field: string, value: Date, raw: string, required: Date, status: CheckStatus) {
	if (value > required) {
		status.errors.push({
			path: [...status.path],
			message: `'${field}' cannot be after ${raw}`,
		});
		return false;
	}
	return true;
}

function minlen(field: string, value: string, raw: string, required: number, status: CheckStatus) {
	if (value.length < required) {
		status.errors.push({
			path: [...status.path],
			message: `'${field}' must be at least ${raw} characters`,
		});
		return false;
	}
	return true;
}

function maxlen(field: string, value: string, raw: string, required: number, status: CheckStatus) {
	if (value.length > required) {
		status.errors.push({
			path: [...status.path],
			message: `'${field}' cannot be more than ${raw} characters`,
		});
		return false;
	}
	return true;
}

function pattern(field: string, value: string, raw: string, required: string, status: CheckStatus) {
	const regex = createRegex(required);
	if (regex === undefined) {
		// This should never happen...
		status.errors.push({
			path: [...status.path],
			message: `Unsupported pattern for '${field}': ${raw}`,
		});
		return false;
	}
	if (!regex.test(value)) {
		status.errors.push({
			path: [...status.path],
			message: `'${field}' doesn't match pattern '${raw}'`,
		});
		return false;
	}
	return true;
}
