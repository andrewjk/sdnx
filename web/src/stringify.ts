interface Status {
	indent: number;
	result: string;
	ansi: boolean;
	indentText: string;
}

interface Options {
	ansi?: boolean;
	indent?: string;
}

/**
 * Converts an object into a string containing Structured Data Notation.
 */
export default function stringify(obj: Record<PropertyKey, any>, options?: Options): string {
	let status = {
		indent: 0,
		result: "",
		ansi: options?.ansi ?? false,
		indentText: options?.indent ?? "\t",
	};

	printValue(obj, status);

	return status.result;
}

function printValue(obj: any, status: Status) {
	if (obj === null) {
		status.result += "null";
	} else if (Array.isArray(obj)) {
		status.result += "[";
		status.indent += 1;

		for (let i = 0; i < obj.length; i++) {
			status.result += "\n";
			indent(status);
			printValue(obj[i], status);
			if (i < obj.length - 1) {
				status.result += ",";
			}
		}

		status.indent -= 1;
		status.result += "\n";
		indent(status);
		status.result += "]";
	} else if (obj instanceof Date) {
		const dateStr = formatDate(obj);
		status.result += status.ansi ? `\x1b[35m${dateStr}\x1b[0m` : dateStr;
	} else if (typeof obj === "object") {
		status.result += "{";
		status.indent += 1;

		const keys = Object.keys(obj);
		for (let i = 0; i < keys.length; i++) {
			status.result += "\n";
			const key = keys[i];
			indent(status);
			status.result += key + ": ";
			printValue(obj[key], status);
			if (i < keys.length - 1) {
				status.result += ",";
			}
		}

		status.indent -= 1;
		status.result += "\n";
		indent(status);
		status.result += "}";
	} else if (typeof obj === "string") {
		status.result += status.ansi ? `\x1b[32m"${obj}"\x1b[0m` : `"${obj}"`;
	} else if (typeof obj === "number") {
		status.result += status.ansi ? `\x1b[33m${String(obj)}\x1b[0m` : String(obj);
	} else if (typeof obj === "boolean") {
		status.result += status.ansi ? `\x1b[34m${String(obj)}\x1b[0m` : String(obj);
	} else {
		status.result += String(obj);
	}
}

function indent(status: Status) {
	status.result += status.indentText.repeat(status.indent);
}

function formatDate(date: Date): string {
	const year = date.getFullYear();
	const month = String(date.getMonth() + 1).padStart(2, "0");
	const day = String(date.getDate()).padStart(2, "0");
	const hours = String(date.getHours()).padStart(2, "0");
	const minutes = String(date.getMinutes()).padStart(2, "0");
	const seconds = String(date.getSeconds()).padStart(2, "0");

	if (hours === "00" && minutes === "00" && seconds === "00") {
		return `${year}-${month}-${day}`;
	} else {
		return `${year}-${month}-${day}T${hours}:${minutes}`;
	}
}
