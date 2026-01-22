import { FieldSchema } from "./FieldSchema";
import { Schema } from "./Schema";

export interface MixSchema extends FieldSchema {
	type: "mix";
	inner: Schema[];
}
