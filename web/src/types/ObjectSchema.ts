import FieldSchema from "./FieldSchema";
import Schema from "./Schema";

export default interface ObjectSchema extends FieldSchema {
	type: "object";
	inner: Schema;
}
