import { FieldSchema } from "./FieldSchema";
import { SchemaValue } from "./Schema";

export interface ArraySchema extends FieldSchema {
	type: "array";
	inner: SchemaValue;
}
