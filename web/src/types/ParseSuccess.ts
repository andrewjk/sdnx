import ParseMapping from "./ParseMapping";

export default interface ParseSuccess<T> {
	ok: true;
	data: T;
	mapping?: Record<string, ParseMapping>;
}
