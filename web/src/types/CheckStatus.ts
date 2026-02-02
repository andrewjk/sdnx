import CheckError from "./CheckError";

export default interface CheckStatus {
	path: string[];
	errors: CheckError[];
}
