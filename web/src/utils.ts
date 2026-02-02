import ParseException from "./types/ParseException";
import ParseStatus from "./types/ParseStatus";

export function trim(status: ParseStatus): void {
	while (/\s/.test(status.input[status.i])) {
		status.i++;
	}
}

export function accept(char: string, status: ParseStatus): boolean {
	if (status.input[status.i] === char) {
		status.i++;
		return true;
	}
	return false;
}

export function expect(char: string, status: ParseStatus): boolean {
	if (status.input[status.i] === char) {
		status.i++;
		return true;
	}
	status.errors.push({
		message: `Expected '${char}' but found '${status.input[status.i]}'`,
		index: status.i,
		length: 1,
	});
	throw new ParseException();
}

export function createRegex(input: string): RegExp | undefined {
	const match = input.match(/\/(.+?)\/(.+?)*/);
	if (!match) {
		return;
	}
	const pattern = match[1];
	const flags = match[2];
	return new RegExp(pattern, flags);
}
