import FieldSchema from "./FieldSchema";

export default interface RefSchema extends FieldSchema {
	type: string;
	inner: string;
}
