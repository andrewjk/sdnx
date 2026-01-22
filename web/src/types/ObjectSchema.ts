import { FieldSchema } from "./FieldSchema";
import { Schema } from "./Schema";

export interface ObjectSchema extends FieldSchema {
	type: "object";
	inner: Schema;
}
