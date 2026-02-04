import ArraySchema from "./ArraySchema";
import FieldSchema from "./FieldSchema";
import MixSchema from "./MixSchema";
import ObjectSchema from "./ObjectSchema";
import PropsSchema from "./PropsSchema";
import UnionSchema from "./UnionSchema";

type SchemaValue = FieldSchema | ObjectSchema | ArraySchema | UnionSchema | MixSchema | PropsSchema;
export default SchemaValue;
