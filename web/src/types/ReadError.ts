import ParseError from "./ParseError";

export default interface ReadError extends ParseError {
	line: string;
	char: number;
}
