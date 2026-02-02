import FieldSchema from "./FieldSchema";
import Schema from "./Schema";

export default interface MixSchema extends FieldSchema {
	type: "mix";
	inner: Schema[];
}
