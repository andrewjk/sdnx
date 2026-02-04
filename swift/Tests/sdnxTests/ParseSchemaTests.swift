import Testing
@testable import sdnx
import Foundation

@Suite("Parse schema tests") struct ParseSchemaTests {
    // MARK: - Helper Functions

    func applyUnspaceReplacements(_ value: String) -> String {
        return value
            .replacingOccurrences(of: "min(", with: " min(")
            .replacingOccurrences(of: "max(", with: " max(")
            .replacingOccurrences(of: "len(", with: " len(")
            .replacingOccurrences(of: "min len(", with: " minlen(")
    }

    // MARK: - Test Helpers

    func areSchemasEqual(_ lhs: Schema, _ rhs: Schema) -> Bool {
        guard lhs.keys.count == rhs.keys.count else { return false }
        
        for (key, leftValue) in lhs {
            guard let rightValue = rhs[key] else { return false }
            if !areSchemaValuesEqual(leftValue, rightValue) {
                return false
            }
        }
        
        return true
    }

    func areSchemaValuesEqual(_ lhs: SchemaValue, _ rhs: SchemaValue) -> Bool {
        guard lhs.type == rhs.type else { return false }
        
        // Compare descriptions
        if lhs.description != rhs.description {
            return false
        }
        
        // Compare validators
        if let leftValidators = lhs.validators, let rightValidators = rhs.validators {
            guard leftValidators.count == rightValidators.count else { return false }
            for (key, leftValidator) in leftValidators {
                guard let rightValidator = rightValidators[key] else { return false }
                if !areValidatorsEqual(leftValidator, rightValidator) {
                    return false
                }
            }
        } else if lhs.validators != nil || rhs.validators != nil {
            return false
        }
        
        // Handle special types
        if let leftObj = lhs as? ObjectSchema, let rightObj = rhs as? ObjectSchema {
            return areSchemasEqual(leftObj.inner, rightObj.inner)
        }
        
        if let leftArr = lhs as? ArraySchema, let rightArr = rhs as? ArraySchema {
            return areSchemaValuesEqual(leftArr.inner, rightArr.inner)
        }
        
        if let leftUnion = lhs as? UnionSchema, let rightUnion = rhs as? UnionSchema {
            guard leftUnion.inner.count == rightUnion.inner.count else { return false }
            for (i, leftAlt) in leftUnion.inner.enumerated() {
                if !areSchemaValuesEqual(leftAlt, rightUnion.inner[i]) {
                    return false
                }
            }
            return true
        }
        
        if let leftMix = lhs as? MixSchema, let rightMix = rhs as? MixSchema {
            guard leftMix.inner.count == rightMix.inner.count else { return false }
            for (i, leftAlt) in leftMix.inner.enumerated() {
                if !areSchemasEqual(leftAlt, rightMix.inner[i]) {
                    return false
                }
            }
            return true
        }
        
        return true
    }

    func areValidatorsEqual(_ lhs: ValidatorInfo, _ rhs: ValidatorInfo) -> Bool {
        guard lhs.raw == rhs.raw else { return false }
        
        // Compare required values
        if let leftReq = lhs.required, let rightReq = rhs.required {
            if let leftInt = leftReq as? Int, let rightInt = rightReq as? Int {
                return leftInt == rightInt
            } else if let leftDouble = leftReq as? Double, let rightDouble = rightReq as? Double {
                return leftDouble == rightDouble
            } else if let leftString = leftReq as? String, let rightString = rightReq as? String {
                return leftString == rightString
            } else if let leftBool = leftReq as? Bool, let rightBool = rightReq as? Bool {
                return leftBool == rightBool
            }
            return false
        } else if lhs.required != nil || rhs.required != nil {
            return false
        }
        
        return true
    }

    // MARK: - Tests

    @Test func parseSchemaBasicTest() throws {
        let input = """
    {
        active: bool,
        # a comment
        name: string minlen(2),
        age: int min(16),
        rating: num max(5),	
        ## a description of this field
        skills: string,
        started_at: date,
        meeting_at: null | date,
        children: [{
            age: int,
            name: string,
        }],
    }
    """
        
        let result = try unwrapParseSchemaResult(parseSchema(input))
        
        #expect(result["active"]?.type == "bool")
        #expect(result["active"]?.description == nil)
        
        #expect(result["name"]?.type == "string")
        #expect(result["name"]?.validators?["minlen"]?.raw == "2")
        
        #expect(result["age"]?.type == "int")
        #expect(result["age"]?.validators?["min"]?.raw == "16")
        
        #expect(result["rating"]?.type == "num")
        #expect(result["rating"]?.validators?["max"]?.raw == "5")
        
        #expect(result["skills"]?.type == "string")
        #expect(result["skills"]?.description == "a description of this field")
        
        #expect(result["started_at"]?.type == "date")
        
        #expect(result["meeting_at"]?.type == "union")
        if let meetingAt = result["meeting_at"] as? UnionSchema {
            #expect(meetingAt.inner.count == 2)
            #expect(meetingAt.inner[0].type == "null")
            #expect(meetingAt.inner[1].type == "date")
        } else {
            #expect(Bool(false), "meeting_at should be a UnionSchema")
        }
        
        #expect(result["children"]?.type == "array")
        if let children = result["children"] as? ArraySchema {
            #expect(children.inner.type == "object")
            if let childObj = children.inner as? ObjectSchema {
                #expect(childObj.inner["age"]?.type == "int")
                #expect(childObj.inner["name"]?.type == "string")
            } else {
                #expect(Bool(false), "children inner should be an ObjectSchema")
            }
        } else {
            #expect(Bool(false), "children should be an ArraySchema")
        }
        
        // Test with spaced input
        let spacedInput = space(input)
        let spacedResult = try unwrapParseSchemaResult(parseSchema(spacedInput))
        #expect(spacedResult["active"]?.type == "bool")
        #expect(spacedResult["name"]?.type == "string")
        #expect(spacedResult["name"]?.validators?["minlen"]?.raw == "2")
        #expect(spacedResult["age"]?.type == "int")
        #expect(spacedResult["age"]?.validators?["min"]?.raw == "16")
        #expect(spacedResult["rating"]?.type == "num")
        #expect(spacedResult["rating"]?.validators?["max"]?.raw == "5")
        #expect(spacedResult["meeting_at"]?.type == "union")
        #expect(spacedResult["children"]?.type == "array")
        
        // Test with unspaced input
        let unspacedInput = applyUnspaceReplacements(unspace(input))
        let unspacedResult = try unwrapParseSchemaResult(parseSchema(unspacedInput))
        #expect(unspacedResult["active"]?.type == "bool")
        #expect(unspacedResult["name"]?.type == "string")
        #expect(unspacedResult["name"]?.validators?["minlen"]?.raw == "2")
        #expect(unspacedResult["age"]?.type == "int")
        #expect(unspacedResult["age"]?.validators?["min"]?.raw == "16")
        #expect(unspacedResult["rating"]?.type == "num")
        #expect(unspacedResult["rating"]?.validators?["max"]?.raw == "5")
        #expect(unspacedResult["meeting_at"]?.type == "union")
        #expect(unspacedResult["children"]?.type == "array")
    }
    
    @Test func parseSchemaSimpleType() throws {
        let input = """
    {
        name: string,
    }
    """
        
        let result = try unwrapParseSchemaResult(parseSchema(input))
        #expect(result["name"]?.type == "string")
        
        // Test with spaced input
        let spacedInput = space(input)
        let spacedResult = try unwrapParseSchemaResult(parseSchema(spacedInput))
        #expect(spacedResult["name"]?.type == "string")
        
        // Test with unspaced input
        let unspacedInput = unspace(input)
        let unspacedResult = try unwrapParseSchemaResult(parseSchema(unspacedInput))
        #expect(unspacedResult["name"]?.type == "string")
    }
    
    @Test func parseSchemaTypeWithDescription() throws {
        let input = """
    {
        ## This is a name
        name: string,
    }
    """
        
        let result = try unwrapParseSchemaResult(parseSchema(input))
        #expect(result["name"]?.type == "string")
        #expect(result["name"]?.description == "This is a name")
        
        // Test with spaced input
        let spacedInput = space(input)
        let spacedResult = try unwrapParseSchemaResult(parseSchema(spacedInput))
        #expect(spacedResult["name"]?.type == "string")
        #expect(spacedResult["name"]?.description == "This is a name")
        
        // Test with unspaced input
        let unspacedInput = unspace(input)
        let unspacedResult = try unwrapParseSchemaResult(parseSchema(unspacedInput))
        #expect(unspacedResult["name"]?.type == "string")
        #expect(unspacedResult["name"]?.description == "This is a name")
    }
    
    @Test func parseSchemaUnionType() throws {
        let input = """
    {
        value: string | int,
    }
    """
        
        let result = try unwrapParseSchemaResult(parseSchema(input))
        #expect(result["value"]?.type == "union")
        if let union = result["value"] as? UnionSchema {
            #expect(union.inner.count == 2)
            #expect(union.inner[0].type == "string")
            #expect(union.inner[1].type == "int")
        } else {
            #expect(Bool(false), "value should be a UnionSchema")
        }
        
        // Test with spaced input
        let spacedInput = space(input)
        let spacedResult = try unwrapParseSchemaResult(parseSchema(spacedInput))
        #expect(spacedResult["value"]?.type == "union")
        if let spacedUnion = spacedResult["value"] as? UnionSchema {
            #expect(spacedUnion.inner.count == 2)
            #expect(spacedUnion.inner[0].type == "string")
            #expect(spacedUnion.inner[1].type == "int")
        }
        
        // Test with unspaced input
        let unspacedInput = unspace(input)
        let unspacedResult = try unwrapParseSchemaResult(parseSchema(unspacedInput))
        #expect(unspacedResult["value"]?.type == "union")
        if let unspacedUnion = unspacedResult["value"] as? UnionSchema {
            #expect(unspacedUnion.inner.count == 2)
            #expect(unspacedUnion.inner[0].type == "string")
            #expect(unspacedUnion.inner[1].type == "int")
        }
    }
    
    @Test func parseSchemaTypeWithParameter() throws {
        let input = """
    {
        age: int min(0),
    }
    """
        
        let result = try unwrapParseSchemaResult(parseSchema(input))
        #expect(result["age"]?.type == "int")
        #expect(result["age"]?.validators?["min"]?.raw == "0")
        
        // Test with spaced input
        let spacedInput = space(input)
        let spacedResult = try unwrapParseSchemaResult(parseSchema(spacedInput))
        #expect(spacedResult["age"]?.type == "int")
        #expect(spacedResult["age"]?.validators?["min"]?.raw == "0")
        
        // Test with unspaced input
        let unspacedInput = unspace(input).replacingOccurrences(of: "min(", with: " min(")
        let unspacedResult = try unwrapParseSchemaResult(parseSchema(unspacedInput))
        #expect(unspacedResult["age"]?.type == "int")
        #expect(unspacedResult["age"]?.validators?["min"]?.raw == "0")
    }
    
    @Test func parseSchemaObjectType() throws {
        let input = """
    {
        dob: { year: int, month: int, day: int }
    }
    """
        
        let result = try unwrapParseSchemaResult(parseSchema(input))
        #expect(result["dob"]?.type == "object")
        if let obj = result["dob"] as? ObjectSchema {
            #expect(obj.inner["year"]?.type == "int")
            #expect(obj.inner["month"]?.type == "int")
            #expect(obj.inner["day"]?.type == "int")
        } else {
            #expect(Bool(false), "dob should be an ObjectSchema")
        }
        
        // Test with spaced input
        let spacedInput = space(input)
        let spacedResult = try unwrapParseSchemaResult(parseSchema(spacedInput))
        #expect(spacedResult["dob"]?.type == "object")
        if let spacedObj = spacedResult["dob"] as? ObjectSchema {
            #expect(spacedObj.inner["year"]?.type == "int")
            #expect(spacedObj.inner["month"]?.type == "int")
            #expect(spacedObj.inner["day"]?.type == "int")
        }
        
        // Test with unspaced input
        let unspacedInput = unspace(input)
        let unspacedResult = try unwrapParseSchemaResult(parseSchema(unspacedInput))
        #expect(unspacedResult["dob"]?.type == "object")
        if let unspacedObj = unspacedResult["dob"] as? ObjectSchema {
            #expect(unspacedObj.inner["year"]?.type == "int")
            #expect(unspacedObj.inner["month"]?.type == "int")
            #expect(unspacedObj.inner["day"]?.type == "int")
        }
    }
    
    @Test func parseSchemaArrayType() throws {
        let input = """
    {
        children: [ string ]
    }
    """
        
        let result = try unwrapParseSchemaResult(parseSchema(input))
        #expect(result["children"]?.type == "array")
        if let arr = result["children"] as? ArraySchema {
            #expect(arr.inner.type == "string")
        } else {
            #expect(Bool(false), "children should be an ArraySchema")
        }
        
        // Test with spaced input
        let spacedInput = space(input)
        let spacedResult = try unwrapParseSchemaResult(parseSchema(spacedInput))
        #expect(spacedResult["children"]?.type == "array")
        if let spacedArr = spacedResult["children"] as? ArraySchema {
            #expect(spacedArr.inner.type == "string")
        }
        
        // Test with unspaced input
        let unspacedInput = unspace(input)
        let unspacedResult = try unwrapParseSchemaResult(parseSchema(unspacedInput))
        #expect(unspacedResult["children"]?.type == "array")
        if let unspacedArr = unspacedResult["children"] as? ArraySchema {
            #expect(unspacedArr.inner.type == "string")
        }
    }
    
    @Test func parseSchemaMixMacro() throws {
        let input = """
    {
        name: string minlen(2),
        @mix({
            age: int min(16),
            rating: num max(5),
        }),
        active: bool,
    }
    """
        
        let result = try unwrapParseSchemaResult(parseSchema(input))
        
        #expect(result["name"]?.type == "string")
        #expect(result["active"]?.type == "bool")
        
        #expect(result["mix$1"]?.type == "mix")
        if let mix = result["mix$1"] as? MixSchema {
            #expect(mix.inner.count == 1)
            let innerSchema = mix.inner[0]
            #expect(innerSchema["age"]?.type == "int")
            #expect(innerSchema["rating"]?.type == "num")
        } else {
            #expect(Bool(false), "mix$1 should be a MixSchema")
        }
        
        // Test with spaced input
        let spacedInput = space(input)
        let spacedResult = try unwrapParseSchemaResult(parseSchema(spacedInput))
        #expect(spacedResult["name"]?.type == "string")
        #expect(spacedResult["active"]?.type == "bool")
        #expect(spacedResult["mix$1"]?.type == "mix")
        
        // Test with unspaced input
        let unspacedInput = applyUnspaceReplacements(unspace(input))
        let unspacedResult = try unwrapParseSchemaResult(parseSchema(unspacedInput))
        #expect(unspacedResult["name"]?.type == "string")
        #expect(unspacedResult["active"]?.type == "bool")
        #expect(unspacedResult["mix$1"]?.type == "mix")
    }
    
    @Test func parseSchemaPropsMacro() throws {
        let input = """
    {
        name: string minlen(2),
        @props(): int min(16),
        active: bool,
    }
    """
        
        let result = try unwrapParseSchemaResult(parseSchema(input))
        
        #expect(result["name"]?.type == "string")
        #expect(result["active"]?.type == "bool")
        
        if let anySchema = result["props$1"] as? AnySchema {
            #expect(anySchema.inner.type == "int")
            #expect(anySchema.inner.validators?["min"]?.raw == "16")
        } else {
            #expect(Bool(false), "props$1 should exist")
        }
        
        // Test with spaced input
        let spacedInput = space(input)
        let spacedResult = try unwrapParseSchemaResult(parseSchema(spacedInput))
        #expect(spacedResult["name"]?.type == "string")
        #expect(spacedResult["active"]?.type == "bool")
        #expect(spacedResult["props$1"]?.type == "")
        
        // Test with unspaced input
        let unspacedInput = applyUnspaceReplacements(unspace(input))
        let unspacedResult = try unwrapParseSchemaResult(parseSchema(unspacedInput))
        #expect(unspacedResult["name"]?.type == "string")
        #expect(unspacedResult["active"]?.type == "bool")
        #expect(unspacedResult["props$1"]?.type == "")
    }
    
    @Test func parseSchemaPropsMacroWithPattern() throws {
        let input = """
    {
        @props(/v\\d/): string,
    }
    """
        
        let result = try unwrapParseSchemaResult(parseSchema(input))
        
        if let anySchema = result["props$1"] as? AnySchema {
            #expect(anySchema.type == "/v\\d/")
            #expect(anySchema.inner.type == "string")
        } else {
            #expect(Bool(false), "props$1 should exist")
        }
        
        // Test with spaced input
        let spacedInput = space(input)
        let spacedResult = try unwrapParseSchemaResult(parseSchema(spacedInput))
        if let spacedAnySchema = spacedResult["props$1"] as? AnySchema {
            #expect(spacedAnySchema.type == "/v\\d/")
            #expect(spacedAnySchema.inner.type == "string")
        }
        
        // Test with unspaced input
        let unspacedInput = unspace(input)
        let unspacedResult = try unwrapParseSchemaResult(parseSchema(unspacedInput))
        if let unspacedAnySchema = unspacedResult["props$1"] as? AnySchema {
            #expect(unspacedAnySchema.type == "/v\\d/")
            #expect(unspacedAnySchema.inner.type == "string")
        }
    }
    
    @Test func parseSchemaTypeWithMultipleParameters() throws {
        let input = """
    {
        rating: num min(0) max(5),
    }
    """
        
        let result = try unwrapParseSchemaResult(parseSchema(input))
        #expect(result["rating"]?.type == "num")
        #expect(result["rating"]?.validators?["min"]?.raw == "0")
        #expect(result["rating"]?.validators?["max"]?.raw == "5")
        
        // Test with spaced input
        let spacedInput = space(input)
        let spacedResult = try unwrapParseSchemaResult(parseSchema(spacedInput))
        #expect(spacedResult["rating"]?.type == "num")
        #expect(spacedResult["rating"]?.validators?["min"]?.raw == "0")
        #expect(spacedResult["rating"]?.validators?["max"]?.raw == "5")
        
        // Test with unspaced input
        let unspacedInput = unspace(input)
            .replacingOccurrences(of: "min(", with: " min(")
            .replacingOccurrences(of: "max(", with: " max(")
        let unspacedResult = try unwrapParseSchemaResult(parseSchema(unspacedInput))
        #expect(unspacedResult["rating"]?.type == "num")
        #expect(unspacedResult["rating"]?.validators?["min"]?.raw == "0")
        #expect(unspacedResult["rating"]?.validators?["max"]?.raw == "5")
    }
    
    @Test func parseSchemaNestedObject() throws {
        let input = """
    {
        address: {
            street: string,
            city: string,
            zip: string,
        },
    }
    """
        
        let result = try unwrapParseSchemaResult(parseSchema(input))
        #expect(result["address"]?.type == "object")
        if let obj = result["address"] as? ObjectSchema {
            #expect(obj.inner["street"]?.type == "string")
            #expect(obj.inner["city"]?.type == "string")
            #expect(obj.inner["zip"]?.type == "string")
        } else {
            #expect(Bool(false), "address should be an ObjectSchema")
        }
        
        // Test with spaced input
        let spacedInput = space(input)
        let spacedResult = try unwrapParseSchemaResult(parseSchema(spacedInput))
        #expect(spacedResult["address"]?.type == "object")
        if let spacedObj = spacedResult["address"] as? ObjectSchema {
            #expect(spacedObj.inner["street"]?.type == "string")
            #expect(spacedObj.inner["city"]?.type == "string")
            #expect(spacedObj.inner["zip"]?.type == "string")
        }
        
        // Test with unspaced input
        let unspacedInput = unspace(input)
        let unspacedResult = try unwrapParseSchemaResult(parseSchema(unspacedInput))
        #expect(unspacedResult["address"]?.type == "object")
        if let unspacedObj = unspacedResult["address"] as? ObjectSchema {
            #expect(unspacedObj.inner["street"]?.type == "string")
            #expect(unspacedObj.inner["city"]?.type == "string")
            #expect(unspacedObj.inner["zip"]?.type == "string")
        }
    }
    
    @Test func parseSchemaArrayOfObjects() throws {
        let input = """
    {
        items: [{ id: int, name: string }],
    }
    """
        
        let result = try unwrapParseSchemaResult(parseSchema(input))
        #expect(result["items"]?.type == "array")
        if let arr = result["items"] as? ArraySchema {
            #expect(arr.inner.type == "object")
            if let obj = arr.inner as? ObjectSchema {
                #expect(obj.inner["id"]?.type == "int")
                #expect(obj.inner["name"]?.type == "string")
            } else {
                #expect(Bool(false), "items inner should be an ObjectSchema")
            }
        } else {
            #expect(Bool(false), "items should be an ArraySchema")
        }
        
        // Test with spaced input
        let spacedInput = space(input)
        let spacedResult = try unwrapParseSchemaResult(parseSchema(spacedInput))
        #expect(spacedResult["items"]?.type == "array")
        if let spacedArr = spacedResult["items"] as? ArraySchema {
            #expect(spacedArr.inner.type == "object")
        }
        
        // Test with unspaced input
        let unspacedInput = unspace(input)
        let unspacedResult = try unwrapParseSchemaResult(parseSchema(unspacedInput))
        #expect(unspacedResult["items"]?.type == "array")
        if let unspacedArr = unspacedResult["items"] as? ArraySchema {
            #expect(unspacedArr.inner.type == "object")
        }
    }
    
    @Test func parseSchemaArrayOfArrays() throws {
        let input = """
    {
        matrix: [[ int ]],
    }
    """
        
        let result = try unwrapParseSchemaResult(parseSchema(input))
        #expect(result["matrix"]?.type == "array")
        if let arr = result["matrix"] as? ArraySchema {
            #expect(arr.inner.type == "array")
            if let innerArr = arr.inner as? ArraySchema {
                #expect(innerArr.inner.type == "int")
            } else {
                #expect(Bool(false), "matrix inner should be an ArraySchema")
            }
        } else {
            #expect(Bool(false), "matrix should be an ArraySchema")
        }
        
        // Test with spaced input
        let spacedInput = space(input)
        let spacedResult = try unwrapParseSchemaResult(parseSchema(spacedInput))
        #expect(spacedResult["matrix"]?.type == "array")
        if let spacedArr = spacedResult["matrix"] as? ArraySchema {
            #expect(spacedArr.inner.type == "array")
        }
        
        // Test with unspaced input
        let unspacedInput = unspace(input)
        let unspacedResult = try unwrapParseSchemaResult(parseSchema(unspacedInput))
        #expect(unspacedResult["matrix"]?.type == "array")
        if let unspacedArr = unspacedResult["matrix"] as? ArraySchema {
            #expect(unspacedArr.inner.type == "array")
        }
    }
    
    @Test func parseSchemaUnionOfThreeTypes() throws {
        let input = """
    {
        value: string | int | bool,
    }
    """
        
        let result = try unwrapParseSchemaResult(parseSchema(input))
        #expect(result["value"]?.type == "union")
        if let union = result["value"] as? UnionSchema {
            #expect(union.inner.count == 3)
            #expect(union.inner[0].type == "string")
            #expect(union.inner[1].type == "int")
            #expect(union.inner[2].type == "bool")
        } else {
            #expect(Bool(false), "value should be a UnionSchema")
        }
        
        // Test with spaced input
        let spacedInput = space(input)
        let spacedResult = try unwrapParseSchemaResult(parseSchema(spacedInput))
        #expect(spacedResult["value"]?.type == "union")
        if let spacedUnion = spacedResult["value"] as? UnionSchema {
            #expect(spacedUnion.inner.count == 3)
            #expect(spacedUnion.inner[0].type == "string")
            #expect(spacedUnion.inner[1].type == "int")
            #expect(spacedUnion.inner[2].type == "bool")
        }
        
        // Test with unspaced input
        let unspacedInput = unspace(input)
        let unspacedResult = try unwrapParseSchemaResult(parseSchema(unspacedInput))
        #expect(unspacedResult["value"]?.type == "union")
        if let unspacedUnion = unspacedResult["value"] as? UnionSchema {
            #expect(unspacedUnion.inner.count == 3)
            #expect(unspacedUnion.inner[0].type == "string")
            #expect(unspacedUnion.inner[1].type == "int")
            #expect(unspacedUnion.inner[2].type == "bool")
        }
    }
    
    @Test func parseSchemaMultipleMixMacros() throws {
        let input = """
    {
        @mix({
            role: "admin",
            level: int min(1),
        }),
        @mix({
            role: "user",
            plan: string,
        }),
    }
    """
        
        let result = try unwrapParseSchemaResult(parseSchema(input))
        
        if let mix1 = result["mix$1"] as? MixSchema {
            #expect(mix1.inner.count == 1)
            let inner1 = mix1.inner[0]
            #expect(inner1["role"]?.type == "\"admin\"")
            #expect(inner1["level"]?.type == "int")
        } else {
            #expect(Bool(false), "mix$1 should be a MixSchema")
        }
        
        if let mix2 = result["mix$2"] as? MixSchema {
            #expect(mix2.inner.count == 1)
            let inner2 = mix2.inner[0]
            #expect(inner2["role"]?.type == "\"user\"")
            #expect(inner2["plan"]?.type == "string")
        } else {
            #expect(Bool(false), "mix$2 should be a MixSchema")
        }
        
        // Test with spaced input
        let spacedInput = space(input)
        let spacedResult = try unwrapParseSchemaResult(parseSchema(spacedInput))
        #expect(spacedResult["mix$1"]?.type == "mix")
        #expect(spacedResult["mix$2"]?.type == "mix")
        
        // Test with unspaced input
        let unspacedInput = unspace(input).replacingOccurrences(of: "min(", with: " min(")
        let unspacedResult = try unwrapParseSchemaResult(parseSchema(unspacedInput))
        #expect(unspacedResult["mix$1"]?.type == "mix")
        #expect(unspacedResult["mix$2"]?.type == "mix")
    }
    
    @Test func parseSchemaMixWithMultipleAlternatives() throws {
        let input = """
    {
        @mix({
            minor: false
        } | {
            minor: true,
            guardian: string
        } | {
            minor: true,
            age: int min(18)
        }),
    }
    """
        
        let result = try unwrapParseSchemaResult(parseSchema(input))
        
        if let mix = result["mix$1"] as? MixSchema {
            #expect(mix.inner.count == 3)
            
            let inner1 = mix.inner[0]
            #expect(inner1["minor"]?.type == "false")
            
            let inner2 = mix.inner[1]
            #expect(inner2["minor"]?.type == "true")
            #expect(inner2["guardian"]?.type == "string")
            
            let inner3 = mix.inner[2]
            #expect(inner3["minor"]?.type == "true")
            #expect(inner3["age"]?.type == "int")
        } else {
            #expect(Bool(false), "mix$1 should be a MixSchema")
        }
        
        // Test with spaced input
        let spacedInput = space(input)
        let spacedResult = try unwrapParseSchemaResult(parseSchema(spacedInput))
        #expect(spacedResult["mix$1"]?.type == "mix")
        
        // Test with unspaced input
        let unspacedInput = unspace(input).replacingOccurrences(of: "min(", with: " min(")
        let unspacedResult = try unwrapParseSchemaResult(parseSchema(unspacedInput))
        #expect(unspacedResult["mix$1"]?.type == "mix")
    }
    
    @Test func parseSchemaEmptyObject() throws {
        let input = "{}"
        
        let result = try unwrapParseSchemaResult(parseSchema(input))
        #expect(result.isEmpty)
        
        // Test with spaced input
        let spacedInput = space(input)
        let spacedResult = try unwrapParseSchemaResult(parseSchema(spacedInput))
        #expect(spacedResult.isEmpty)
        
        // Test with unspaced input
        let unspacedInput = unspace(input)
        let unspacedResult = try unwrapParseSchemaResult(parseSchema(unspacedInput))
        #expect(unspacedResult.isEmpty)
    }
    
    @Test func parseSchemaArrayWithUnionType() throws {
        let input = """
    {
        values: [ string | int ],
    }
    """
        
        let result = try unwrapParseSchemaResult(parseSchema(input))
        #expect(result["values"]?.type == "array")
        if let arr = result["values"] as? ArraySchema {
            #expect(arr.inner.type == "union")
            if let union = arr.inner as? UnionSchema {
                #expect(union.inner.count == 2)
                #expect(union.inner[0].type == "string")
                #expect(union.inner[1].type == "int")
            } else {
                #expect(Bool(false), "values inner should be a UnionSchema")
            }
        } else {
            #expect(Bool(false), "values should be an ArraySchema")
        }
        
        // Test with spaced input
        let spacedInput = space(input)
        let spacedResult = try unwrapParseSchemaResult(parseSchema(spacedInput))
        #expect(spacedResult["values"]?.type == "array")
        if let spacedArr = spacedResult["values"] as? ArraySchema {
            #expect(spacedArr.inner.type == "union")
        }
        
        // Test with unspaced input
        let unspacedInput = unspace(input)
        let unspacedResult = try unwrapParseSchemaResult(parseSchema(unspacedInput))
        #expect(unspacedResult["values"]?.type == "array")
        if let unspacedArr = unspacedResult["values"] as? ArraySchema {
            #expect(unspacedArr.inner.type == "union")
        }
    }
    
    @Test func parseSchemaUnionWithArrayFirst() throws {
        let input = """
     {
        values: [ string ] | string,
     }
    """
        
        let result = try unwrapParseSchemaResult(parseSchema(input))
        #expect(result["values"]?.type == "union")
        if let union = result["values"] as? UnionSchema {
            #expect(union.inner.count == 2)
            #expect(union.inner[0].type == "array")
            #expect(union.inner[1].type == "string")
        } else {
            #expect(Bool(false), "values should be a UnionSchema")
        }
        
        // Test with spaced input
        let spacedInput = space(input)
        let spacedResult = try unwrapParseSchemaResult(parseSchema(spacedInput))
        #expect(spacedResult["values"]?.type == "union")
        if let spacedUnion = spacedResult["values"] as? UnionSchema {
            #expect(spacedUnion.inner.count == 2)
            #expect(spacedUnion.inner[0].type == "array")
            #expect(spacedUnion.inner[1].type == "string")
        }
        
        // Test with unspaced input
        let unspacedInput = unspace(input)
        let unspacedResult = try unwrapParseSchemaResult(parseSchema(unspacedInput))
        #expect(unspacedResult["values"]?.type == "union")
        if let unspacedUnion = unspacedResult["values"] as? UnionSchema {
            #expect(unspacedUnion.inner.count == 2)
            #expect(unspacedUnion.inner[0].type == "array")
            #expect(unspacedUnion.inner[1].type == "string")
        }
    }
    
    @Test func parseSchemaUnionWithArraySecond() throws {
        let input = """
     {
        values: string | [ string ],
     }
    """
        
        let result = try unwrapParseSchemaResult(parseSchema(input))
        #expect(result["values"]?.type == "union")
        if let union = result["values"] as? UnionSchema {
            #expect(union.inner.count == 2)
            #expect(union.inner[0].type == "string")
            #expect(union.inner[1].type == "array")
        } else {
            #expect(Bool(false), "values should be a UnionSchema")
        }
        
        // Test with spaced input
        let spacedInput = space(input)
        let spacedResult = try unwrapParseSchemaResult(parseSchema(spacedInput))
        #expect(spacedResult["values"]?.type == "union")
        if let spacedUnion = spacedResult["values"] as? UnionSchema {
            #expect(spacedUnion.inner.count == 2)
            #expect(spacedUnion.inner[0].type == "string")
            #expect(spacedUnion.inner[1].type == "array")
        }
        
        // Test with unspaced input
        let unspacedInput = unspace(input)
        let unspacedResult = try unwrapParseSchemaResult(parseSchema(unspacedInput))
        #expect(unspacedResult["values"]?.type == "union")
        if let unspacedUnion = unspacedResult["values"] as? UnionSchema {
            #expect(unspacedUnion.inner.count == 2)
            #expect(unspacedUnion.inner[0].type == "string")
            #expect(unspacedUnion.inner[1].type == "array")
        }
    }
    
    @Test func parseSchemaUnionWithObjectFirst() throws {
        let input = """
     {
        values: { name: string } | string,
     }
    """
        
        let result = try unwrapParseSchemaResult(parseSchema(input))
        #expect(result["values"]?.type == "union")
        if let union = result["values"] as? UnionSchema {
            #expect(union.inner.count == 2)
            #expect(union.inner[0].type == "object")
            #expect(union.inner[1].type == "string")
        } else {
            #expect(Bool(false), "values should be a UnionSchema")
        }
        
        // Test with spaced input
        let spacedInput = space(input)
        let spacedResult = try unwrapParseSchemaResult(parseSchema(spacedInput))
        #expect(spacedResult["values"]?.type == "union")
        if let spacedUnion = spacedResult["values"] as? UnionSchema {
            #expect(spacedUnion.inner.count == 2)
            #expect(spacedUnion.inner[0].type == "object")
            #expect(spacedUnion.inner[1].type == "string")
        }
        
        // Test with unspaced input
        let unspacedInput = unspace(input)
        let unspacedResult = try unwrapParseSchemaResult(parseSchema(unspacedInput))
        #expect(unspacedResult["values"]?.type == "union")
        if let unspacedUnion = unspacedResult["values"] as? UnionSchema {
            #expect(unspacedUnion.inner.count == 2)
            #expect(unspacedUnion.inner[0].type == "object")
            #expect(unspacedUnion.inner[1].type == "string")
        }
    }
    
    @Test func parseSchemaUnionWithObjectSecond() throws {
        let input = """
     {
        values: string | { name: string },
     }
    """
        
        let result = try unwrapParseSchemaResult(parseSchema(input))
        #expect(result["values"]?.type == "union")
        if let union = result["values"] as? UnionSchema {
            #expect(union.inner.count == 2)
            #expect(union.inner[0].type == "string")
            #expect(union.inner[1].type == "object")
        } else {
            #expect(Bool(false), "values should be a UnionSchema")
        }
        
        // Test with spaced input
        let spacedInput = space(input)
        let spacedResult = try unwrapParseSchemaResult(parseSchema(spacedInput))
        #expect(spacedResult["values"]?.type == "union")
        if let spacedUnion = spacedResult["values"] as? UnionSchema {
            #expect(spacedUnion.inner.count == 2)
            #expect(spacedUnion.inner[0].type == "string")
            #expect(spacedUnion.inner[1].type == "object")
        }
        
        // Test with unspaced input
        let unspacedInput = unspace(input)
        let unspacedResult = try unwrapParseSchemaResult(parseSchema(unspacedInput))
        #expect(unspacedResult["values"]?.type == "union")
        if let unspacedUnion = unspacedResult["values"] as? UnionSchema {
            #expect(unspacedUnion.inner.count == 2)
            #expect(unspacedUnion.inner[0].type == "string")
            #expect(unspacedUnion.inner[1].type == "object")
        }
    }
    
    @Test func parseSchemaDeeplyNestedStructure() throws {
        let input = """
    {
        data: {
            user: {
                profile: {
                    name: string,
                    contacts: [{ type: string, value: string }],
                },
            },
        },
    }
    """
        
        let result = try unwrapParseSchemaResult(parseSchema(input))
        
        if let data = result["data"] as? ObjectSchema,
           let user = data.inner["user"] as? ObjectSchema,
           let profile = user.inner["profile"] as? ObjectSchema {
            #expect(profile.inner["name"]?.type == "string")
            if let contacts = profile.inner["contacts"] as? ArraySchema,
               let contactObj = contacts.inner as? ObjectSchema {
                #expect(contactObj.inner["type"]?.type == "string")
                #expect(contactObj.inner["value"]?.type == "string")
            } else {
                #expect(Bool(false), "contacts should be an array of objects")
            }
        } else {
            #expect(Bool(false), "Deeply nested structure should be parseable")
        }
        
        // Test with spaced input
        let spacedInput = space(input)
        let spacedResult = try unwrapParseSchemaResult(parseSchema(spacedInput))
        if let spacedData = spacedResult["data"] as? ObjectSchema,
           let spacedUser = spacedData.inner["user"] as? ObjectSchema,
           let spacedProfile = spacedUser.inner["profile"] as? ObjectSchema {
            #expect(spacedProfile.inner["name"]?.type == "string")
        }
        
        // Test with unspaced input
        let unspacedInput = unspace(input)
        let unspacedResult = try unwrapParseSchemaResult(parseSchema(unspacedInput))
        if let unspacedData = unspacedResult["data"] as? ObjectSchema,
           let unspacedUser = unspacedData.inner["user"] as? ObjectSchema,
           let unspacedProfile = unspacedUser.inner["profile"] as? ObjectSchema {
            #expect(unspacedProfile.inner["name"]?.type == "string")
        }
    }
}
