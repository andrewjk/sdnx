import FieldSchema from "./FieldSchema";
import SchemaValue from "./SchemaValue";

export default interface PropsSchema extends FieldSchema {
	// For a props schema, this contains the pattern
	type: string;
	inner: SchemaValue;
}
