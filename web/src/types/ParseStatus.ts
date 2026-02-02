import ParseError from "./ParseError";

export default interface ParseStatus {
	input: string;
	i: number;
	errors: ParseError[];
}
