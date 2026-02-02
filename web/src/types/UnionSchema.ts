import FieldSchema from "./FieldSchema";
import SchemaValue from "./SchemaValue";

export default interface UnionSchema extends FieldSchema {
	type: "union";
	inner: SchemaValue[];
}
