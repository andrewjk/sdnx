import AnySchema from "./AnySchema";
import ArraySchema from "./ArraySchema";
import FieldSchema from "./FieldSchema";
import MixSchema from "./MixSchema";
import ObjectSchema from "./ObjectSchema";
import UnionSchema from "./UnionSchema";

type SchemaValue = FieldSchema | ObjectSchema | ArraySchema | UnionSchema | MixSchema | AnySchema;
export default SchemaValue;
