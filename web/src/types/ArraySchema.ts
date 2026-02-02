import FieldSchema from "./FieldSchema";
import SchemaValue from "./SchemaValue";

export default interface ArraySchema extends FieldSchema {
	type: "array";
	inner: SchemaValue;
}
