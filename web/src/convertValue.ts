import ParseError from "./types/ParseError";

let intRegex = new RegExp(/^(\+|-)?[\d_]+$/);
let hexRegex = new RegExp(/^(\+|-)?0x[0-9a-f]+$/i);
let floatRegex = new RegExp(/^(\+|-)?[\d_]+\.[\d_]+$/);
let scientificRegex = new RegExp(/^(\+|-)?\d+(?:\.\d+)?[eE]-?\d+$/);
let stringRegex = new RegExp(/^".*"$/);
let regexRegex = new RegExp(/^\/.*\/[gmixsuUAJD]*$/);
let dateRegex = new RegExp(/\d{4}-\d{2}-\d{2}/);
let timeRegex = new RegExp(/\d{2}:\d{2}(?:\d{2})? ?(?:U|L|(?:(?:\+|-)\d{2}:\d{2}))?/);
let dateTimeRegex = new RegExp(
	/\d{4}-\d{2}-\d{2}(?:T| )\d{2}:\d{2}(?:\d{2})? ?(?:U|L|(?:(?:\+|-)\d{2}:\d{2}))?/,
);

export default function convertValue(value: string, start: number, errors: ParseError[]): any {
	if (value === "null") {
		return null;
	} else if (value === "true") {
		return true;
	} else if (value === "false") {
		return false;
	} else if (stringRegex.test(value)) {
		return value.substring(1, value.length - 1);
	} else if (regexRegex.test(value)) {
		return value;
	} else if (intRegex.test(value) || hexRegex.test(value)) {
		return parseInt(value.replaceAll("_", ""));
	} else if (floatRegex.test(value) || scientificRegex.test(value)) {
		return parseFloat(value.replaceAll("_", ""));
	} else if (dateRegex.test(value) || dateTimeRegex.test(value)) {
		const date = new Date(value.replace("U", "Z").replace("L", ""));
		if (isNaN(date.getTime())) {
			errors.push({
				message: `Invalid date '${value}'`,
				index: start,
				length: value.length,
			});
		}
		return date;
	} else if (timeRegex.test(value)) {
		// HACK: Is there a better way to store a time without a date in Javascript?
		const date = new Date(
			"1900-01-01T" + value.replace("U", "Z").replace("L", "").replace(" ", ""),
		);
		if (isNaN(date.getTime())) {
			errors.push({
				message: `Invalid time '${value}'`,
				index: start,
				length: value.length,
			});
		}
		return date;
	} else {
		errors.push({
			message: `Unsupported value type '${value}'`,
			index: start,
			length: value.length,
		});
	}
}
