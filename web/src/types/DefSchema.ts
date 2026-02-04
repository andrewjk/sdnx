import FieldSchema from "./FieldSchema";
import Schema from "./Schema";

export default interface DefSchema extends FieldSchema {
	type: "def";
	name: string;
	inner: Schema;
}
