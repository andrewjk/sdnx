import { FieldSchema } from "./FieldSchema";
import { SchemaValue } from "./Schema";

export interface UnionSchema extends FieldSchema {
	type: "union";
	inner: SchemaValue[];
}
