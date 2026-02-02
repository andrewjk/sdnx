import ParseError from "./ParseError";

export default interface ParseFailure {
	ok: false;
	errors: ParseError[];
}
