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
		min: minDate,
		max: maxDate,
	},
	string: {
		minlen,
		maxlen,
		pattern,
	},
	array: {
		minlen: minlenArray,
		maxlen: maxlenArray,
		unique: unique,
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

function minDate(field: string, value: Date, raw: string, required: Date, status: CheckStatus) {
	if (value < required) {
		status.errors.push({
			path: [...status.path],
			message: `'${field}' must be at least ${raw}`,
		});
		return false;
	}
	return true;
}

function maxDate(field: string, value: Date, raw: string, required: Date, status: CheckStatus) {
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
function minlenArray(
	field: string,
	value: Array<any>,
	raw: string,
	required: number,
	status: CheckStatus,
) {
	if (value.length < required) {
		status.errors.push({
			path: [...status.path],
			message: `'${field}' must contain at least ${raw} items`,
		});
		return false;
	}
	return true;
}

function maxlenArray(
	field: string,
	value: Array<any>,
	raw: string,
	required: number,
	status: CheckStatus,
) {
	if (value.length > required) {
		status.errors.push({
			path: [...status.path],
			message: `'${field}' cannot contain more than ${raw} items`,
		});
		return false;
	}
	return true;
}

function unique(
	field: string,
	value: Array<any>,
	_raw: string,
	_required: number,
	status: CheckStatus,
) {
	// Maybe only use a Set if longer than a certain length?
	let set = new Set();
	let ok = true;
	for (let i = 0; i < value.length; i++) {
		if (set.has(value[i])) {
			status.errors.push({
				path: [...status.path],
				message: `'${field}' value '${value[i]}' is not unique`,
			});
			ok = false;
		} else {
			set.add(value[i]);
		}
	}
	return ok;
}
