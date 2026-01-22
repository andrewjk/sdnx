interface Status {
	indent: number;
	result: string;
}

/**
 * Converts an object into a string containing Structured Data Notation.
 */
export default function stringify(obj: Record<PropertyKey, any>): string {
	let status = {
		indent: 0,
		result: "",
	};

	printValue(obj, status);

	return status.result;
}

function printValue(obj: any, status: Status) {
	if (Array.isArray(obj)) {
		indent(status);
		status.result += "[";
		status.indent += 1;

		for (let i = 0; i < obj.length; i++) {
			status.result += "\n";
			printValue(obj[i], status);
			if (i < obj.length - 1) {
				status.result += ",";
			}
		}

		status.indent -= 1;
		status.result += "\n";
		indent(status);
		status.result += "]";
	} else if (typeof obj === "object") {
		indent(status);
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
		status.result += `"${obj}"`;
	} else if (typeof obj === "number") {
		status.result += String(obj);
	} else if (typeof obj === "boolean") {
		status.result += String(obj);
	} else if (obj instanceof Date) {
		status.result += formatDate(obj);
	} else if (obj === null) {
		status.result += "null";
	} else {
		status.result += String(obj);
	}
}

function indent(status: Status) {
	status.result += "\t".repeat(status.indent);
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
