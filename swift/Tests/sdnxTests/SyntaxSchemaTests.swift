import Testing
@testable import sdnx

@Suite("Schema syntax error tests") struct SyntaxSchemaTests {
    @Test("no opening brace at top level") func noOpeningBrace() {
        let input = "age: int"
        let result = parseSchema(input)
        
        switch result {
        case .failure(let failure):
            #expect(failure.errors.contains(where: { $0.message == "Expected '{' but found 'a'" }))
        case .success:
            #expect(Bool(false), "Expected parse to fail")
        }
    }
    
    @Test("no closing brace at top level") func noClosingBrace() {
        let input = "{ age: int "
        let result = parseSchema(input)
        
        switch result {
        case .failure(let failure):
            #expect(failure.errors.contains(where: { $0.message == "Schema object not closed" }))
        case .success:
            #expect(Bool(false), "Expected parse to fail")
        }
    }
    
    @Test("no closing array brace") func noClosingArrayBrace() {
        let input = "{ foods: [string }"
        let result = parseSchema(input)
        
        switch result {
        case .failure(let failure):
            #expect(failure.errors.contains(where: { $0.message == "Schema array not closed" }))
        case .success:
            #expect(Bool(false), "Expected parse to fail")
        }
    }
    
    @Test("no field value") func noFieldValue() {
        let input = "{ foods, things: boolean }"
        let result = parseSchema(input)
        
        switch result {
        case .failure(let failure):
            #expect(failure.errors.contains(where: { $0.message == "Expected ':' but found ','" }))
        case .success:
            #expect(Bool(false), "Expected parse to fail")
        }
    }
    
    @Test("unsupported value type") func unsupportedValueType() {
        let input = "{ foods: things }"
        let result = parseSchema(input)
        
        switch result {
        case .failure(let failure):
            #expect(failure.errors.contains(where: { $0.message == "Unsupported value type 'things'" }))
        case .success:
            #expect(Bool(false), "Expected parse to fail")
        }
    }
    
    @Test("empty input") func emptyInput() {
        let input = ""
        let result = parseSchema(input)
        
        switch result {
        case .failure(let failure):
            #expect(failure.errors.contains(where: { $0.message == "Expected '{' but found 'EOF'" }))
        case .success:
            #expect(Bool(false), "Expected parse to fail")
        }
    }
    
    @Test("just whitespace") func justWhitespace() {
        let input = "   \n\t  "
        let result = parseSchema(input)
        
        switch result {
        case .failure(let failure):
            #expect(failure.errors.contains(where: { $0.message == "Expected '{' but found 'EOF'" }))
        case .success:
            #expect(Bool(false), "Expected parse to fail")
        }
    }
    
    @Test("field name starts with number") func fieldNameStartsWithNumber() {
        let input = "{ 1field: string }"
        let result = parseSchema(input)
        
        switch result {
        case .failure(let failure):
            #expect(failure.errors.contains(where: { $0.message == "Field must start with quote or alpha" }))
        case .success:
            #expect(Bool(false), "Expected parse to fail")
        }
    }
    
    @Test("field name with special chars") func fieldNameWithSpecialChars() {
        let input = "{ field-name: string }"
        let result = parseSchema(input)
        
        switch result {
        case .failure(let failure):
            #expect(failure.errors.contains(where: { $0.message == "Expected ':' but found '-'" }))
        case .success:
            #expect(Bool(false), "Expected parse to fail")
        }
    }
    
    @Test("unclosed string") func unclosedString() {
        let input = "{ name: \"Alice }"
        let result = parseSchema(input)
        
        switch result {
        case .failure(let failure):
            #expect(failure.errors.contains(where: { $0.message == "String not closed" }))
        case .success:
            #expect(Bool(false), "Expected parse to fail")
        }
    }
    
    @Test("invalid escape sequence") func invalidEscapeSequence() {
        let input = "{ quote: \"Hel\\lo\" }"
        let result = parseSchema(input)
        
        switch result {
        case .failure(let failure):
            #expect(failure.errors.contains(where: { $0.message == "Invalid escape sequence '\\l'" }))
        case .success:
            #expect(Bool(false), "Expected parse to fail")
        }
    }
    
    @Test("number with decimal but no digits") func numberWithDecimalNoDigits() {
        let input = "{ value: 123. }"
        let result = parseSchema(input)
        
        switch result {
        case .failure(let failure):
            #expect(failure.errors.contains(where: { $0.message == "Unsupported value type '123.'" }))
        case .success:
            #expect(Bool(false), "Expected parse to fail")
        }
    }
    
    @Test("hex number with invalid chars") func hexNumberWithInvalidChars() {
        let input = "{ color: 0xGHIJKL }"
        let result = parseSchema(input)
        
        switch result {
        case .failure(let failure):
            #expect(failure.errors.contains(where: { $0.message == "Unsupported value type '0xGHIJKL'" }))
        case .success:
            #expect(Bool(false), "Expected parse to fail")
        }
    }
    
    @Test("invalid date format") func invalidDateFormat() {
        let input = "{ dob: 2025-13-01 }"
        let result = parseSchema(input)
        
        switch result {
        case .failure(let failure):
            #expect(failure.errors.contains(where: { $0.message == "Invalid date '2025-13-01'" }))
        case .success:
            #expect(Bool(false), "Expected parse to fail")
        }
    }
    
    @Test("boolean with wrong case") func booleanWrongCase() {
        let input = "{ active: True }"
        let result = parseSchema(input)
        
        switch result {
        case .failure(let failure):
            #expect(failure.errors.contains(where: { $0.message == "Unsupported value type 'True'" }))
        case .success:
            #expect(Bool(false), "Expected parse to fail")
        }
    }
    
    @Test("negative without digits") func negativeWithoutDigits() {
        let input = "{ value: - }"
        let result = parseSchema(input)
        
        switch result {
        case .failure(let failure):
            #expect(failure.errors.contains(where: { $0.message == "Unsupported value type '-'" }))
        case .success:
            #expect(Bool(false), "Expected parse to fail")
        }
    }
    
    @Test("scientific notation missing exponent") func scientificNotationMissingExponent() {
        let input = "{ value: 1.5e }"
        let result = parseSchema(input)
        
        switch result {
        case .failure(let failure):
            #expect(failure.errors.contains(where: { $0.message == "Unsupported value type '1.5e'" }))
        case .success:
            #expect(Bool(false), "Expected parse to fail")
        }
    }
    
    @Test("multiple colons in field") func multipleColonsInField() {
        let input = "{ name:: string }"
        let result = parseSchema(input)
        
        switch result {
        case .failure(let failure):
            #expect(failure.errors.contains(where: { $0.message == "Unsupported value type ':'" }))
        case .success:
            #expect(Bool(false), "Expected parse to fail")
        }
    }
    
    @Test("array with trailing comma not followed by item") func arrayTrailingCommaNoItem() {
        let input = "{ items: [\"a\",] }"
        let result = parseSchema(input)
        
        switch result {
        case .failure(let failure):
            #expect(failure.errors.contains(where: { $0.message == "Schema array not closed" }))
        case .success:
            #expect(Bool(false), "Expected parse to fail")
        }
    }
    
    @Test("nested object not closed") func nestedObjectNotClosed() {
        let input = "{ data: { nested: string }"
        let result = parseSchema(input)
        
        switch result {
        case .failure(let failure):
            #expect(failure.errors.contains(where: { $0.message == "Schema object not closed" }))
        case .success:
            #expect(Bool(false), "Expected parse to fail")
        }
    }
    
    @Test("nested array not closed") func nestedArrayNotClosed() {
        let input = "{ matrix: [[int] }"
        let result = parseSchema(input)
        
        switch result {
        case .failure(let failure):
            #expect(failure.errors.contains(where: { $0.message == "Schema array not closed" }))
        case .success:
            #expect(Bool(false), "Expected parse to fail")
        }
    }
    
    @Test("object with missing colon after field name") func missingColonAfterFieldName() {
        let input = "{ name string }"
        let result = parseSchema(input)
        
        switch result {
        case .failure(let failure):
            #expect(failure.errors.contains(where: { $0.message == "Expected ':' but found 's'" }))
        case .success:
            #expect(Bool(false), "Expected parse to fail")
        }
    }
    
    @Test("array with just opening brace") func arrayJustOpeningBrace() {
        let input = "{ items: [ }"
        let result = parseSchema(input)
        
        switch result {
        case .failure(let failure):
            #expect(failure.errors.contains(where: { $0.message == "Schema array not closed" }))
        case .success:
            #expect(Bool(false), "Expected parse to fail")
        }
    }
    
    @Test("array with missing opening brace") func arrayMissingOpeningBrace() {
        let input = "{ items: int] }"
        let result = parseSchema(input)
        
        switch result {
        case .failure(let failure):
            #expect(failure.errors.contains(where: { $0.message == "Schema object not closed" }))
        case .success:
            #expect(Bool(false), "Expected parse to fail")
        }
    }
    
    @Test("field name with starting underscore") func fieldNameWithStartingUnderscore() {
        let input = "{ _private: string }"
        let result = parseSchema(input)
        
        #expect((try? unwrapParseSchemaResult(result)) != nil, "Parse should succeed")
    }
    
    @Test("field name in quotes") func fieldNameInQuotes() {
        let input = "{ \"private-field\": string }"
        let result = parseSchema(input)
        
        #expect((try? unwrapParseSchemaResult(result)) != nil, "Parse should succeed")
    }
    
    @Test("multiple commas in object") func multipleCommasInObject() {
        let input = "{ name: string,, age: int }"
        let result = parseSchema(input)
        
        switch result {
        case .failure(let failure):
            #expect(failure.errors.contains(where: { $0.message == "Field must start with quote or alpha" }))
        case .success:
            #expect(Bool(false), "Expected parse to fail")
        }
    }
    
    @Test("comma at start of object") func commaAtStartOfObject() {
        let input = "{ , name: string }"
        let result = parseSchema(input)
        
        switch result {
        case .failure(let failure):
            #expect(failure.errors.contains(where: { $0.message == "Field must start with quote or alpha" }))
        case .success:
            #expect(Bool(false), "Expected parse to fail")
        }
    }
    
    @Test("invalid time format") func invalidTimeFormat() {
        let input = "{ time: 25:00 }"
        let result = parseSchema(input)
        
        switch result {
        case .failure(let failure):
            #expect(failure.errors.contains(where: { $0.message == "Invalid time '25:00'" }))
        case .success:
            #expect(Bool(false), "Expected parse to fail")
        }
    }
    
    @Test("invalid datetime format") func invalidDatetimeFormat() {
        let input = "{ created: 2025-01-15T14:90+02:00 }"
        let result = parseSchema(input)
        
        switch result {
        case .failure(let failure):
            #expect(failure.errors.contains(where: { $0.message == "Invalid date '2025-01-15T14:90+02:00'" }))
        case .success:
            #expect(Bool(false), "Expected parse to fail")
        }
    }
    
    @Test("string with unescaped quote") func stringWithUnescapedQuote() {
        let input = "{ text: \"Hello \"World\"\" }"
        let result = parseSchema(input)
        
        switch result {
        case .failure(let failure):
            #expect(failure.errors.contains(where: { $0.message == "Expected ':' but found '\"'" }))
        case .success:
            #expect(Bool(false), "Expected parse to fail")
        }
    }
    
    @Test("unknown validator") func unknownValidator() {
        let input = "{ text: string required }"
        let result = parseSchema(input)
        
        switch result {
        case .failure(let failure):
            #expect(failure.errors.contains(where: { $0.message == "Unsupported validator 'required'" }))
        case .success:
            #expect(Bool(false), "Expected parse to fail")
        }
    }
}
