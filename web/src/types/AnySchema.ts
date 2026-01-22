import { FieldSchema } from "./FieldSchema";
import { SchemaValue } from "./Schema";

export interface AnySchema extends FieldSchema {
	type: string;
	inner: SchemaValue;
}
