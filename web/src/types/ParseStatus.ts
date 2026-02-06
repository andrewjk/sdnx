import ParseError from "./ParseError";
import ParseMapping from "./ParseMapping";

export default interface ParseStatus {
	input: string;
	i: number;
	errors: ParseError[];

	mapped: boolean;
	path?: string[];
	mapping?: Record<string, ParseMapping>;
}
