interface Status {
	input: string;
	i: number;
}

export function trim(status: Status): void {
	while (/\s/.test(status.input[status.i])) {
		status.i++;
	}
}

export function accept(char: string, status: Status): boolean {
	if (status.input[status.i] === char) {
		status.i++;
		return true;
	}
	return false;
}

export function expect(char: string, status: Status): boolean {
	if (status.input[status.i] === char) {
		status.i++;
		return true;
	}
	throw new Error(`Expected '${char}' but found '${status.input[status.i]}'`);
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
