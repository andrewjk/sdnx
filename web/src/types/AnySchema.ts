import FieldSchema from "./FieldSchema";
import SchemaValue from "./SchemaValue";

export default interface AnySchema extends FieldSchema {
	type: string;
	inner: SchemaValue;
}
