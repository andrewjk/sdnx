export default function space(value: string): string {
	let spacedChars = "{}[]():,";
	let result = "";
	for (let i = 0; i < value.length; i++) {
		const char = value[i];
		if (char === '"') {
			result += ' "';
			i++;
			while (i < value.length && !(value[i] === '"' && value[i - 1] !== "\\")) {
				result += value[i];
				i++;
			}
			result += value[i];
		} else if (char === "#") {
			result += " #";
			i++;
			while (i < value.length && value[i] !== "\n") {
				result += value[i];
				i++;
			}
			result += value[i];
		} else if (spacedChars.includes(char)) {
			result += " " + value[i] + " ";
		} else {
			result += value[i];
		}
	}
	return result;
}
