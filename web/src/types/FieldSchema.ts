import { Validator } from "./Validator";

export interface FieldSchema {
	type: string;
	description?: string;
	validators?: Record<string, Validator>;
}
