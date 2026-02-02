import Validator from "./Validator";

export default interface FieldSchema {
	type: string;
	description?: string;
	validators?: Record<string, Validator>;
}
