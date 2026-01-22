import { CheckError } from "./CheckError";

export interface CheckFailure {
	ok: false;
	errors: CheckError[];
}
