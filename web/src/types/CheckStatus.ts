import CheckError from "./CheckError";
import Schema from "./Schema";

export default interface CheckStatus {
	path: string[];
	errors: CheckError[];
	defs: Record<string, Schema>;
}
