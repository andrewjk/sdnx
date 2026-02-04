import Testing
@testable import sdnx

@Suite("Check tests") struct CheckTests {
    @Test func nullTypeValid() throws {
        let schemaInput = "{ meeting_at: null | date }"
        let input = "{ meeting_at: null }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func boolTypeValid() throws {
        let schemaInput = "{ is_active: bool }"
        let input = "{ is_active: true }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func boolTypeInvalid() throws {
        let schemaInput = "{ is_active: bool }"
        let input = "{ is_active: 1 }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
        if case let .failure(failure) = result {
            #expect(failure.errors.count == 1)
            #expect(failure.errors[0].message == "'is_active' must be a boolean value")
        }
    }
    
    @Test func intTypeValid() throws {
        let schemaInput = "{ age: int }"
        let input = "{ age: 25 }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func intTypeInvalid() throws {
        let schemaInput = "{ age: int }"
        let input = "{ age: 25.5 }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
        if case let .failure(failure) = result {
            #expect(failure.errors.count == 1)
            #expect(failure.errors[0].message == "'age' must be an integer value")
        }
    }
    
    @Test func numTypeValid() throws {
        let schemaInput = "{ rating: num }"
        let input = "{ rating: 4.5 }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func numTypeInvalid() throws {
        let schemaInput = "{ rating: num }"
        let input = "{ rating: \"excellent\" }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
        if case let .failure(failure) = result {
            #expect(failure.errors.count == 1)
            #expect(failure.errors[0].message == "'rating' must be a number value")
        }
    }
    
    @Test func dateTypeValid() throws {
        let schemaInput = "{ birthday: date }"
        let input = "{ birthday: 2025-01-15 }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func dateTypeInvalid() throws {
        let schemaInput = "{ birthday: date }"
        let input = "{ birthday: \"2025-01-15\" }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
        if case let .failure(failure) = result {
            #expect(failure.errors.count == 1)
            #expect(failure.errors[0].message == "'birthday' must be a date value")
        }
    }
    
    @Test func stringTypeValid() throws {
        let schemaInput = "{ name: string }"
        let input = "{ name: \"Alice\" }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func stringTypeInvalid() throws {
        let schemaInput = "{ name: string }"
        let input = "{ name: 123 }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
        if case let .failure(failure) = result {
            #expect(failure.errors.count == 1)
            #expect(failure.errors[0].message == "'name' must be a string value")
        }
    }
    
    @Test func intUnion() throws {
        let schemaInput = "{ age: 15 | 16 | 17 }"
        let input = "{ age: 22 }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
        if case let .failure(failure) = result {
            #expect(failure.errors.count == 1)
            #expect(failure.errors[0].message == "'age' must be '15' | 'age' must be '16' | 'age' must be '17'")
        }
    }
    
    @Test func intMinValidatorValid() throws {
        let schemaInput = "{ age: int min(18) }"
        let input = "{ age: 20 }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func intMinValidatorInvalid() throws {
        let schemaInput = "{ age: int min(18) }"
        let input = "{ age: 15 }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
        if case let .failure(failure) = result {
            #expect(failure.errors.count == 1)
            #expect(failure.errors[0].message == "'age' must be at least 18")
        }
    }
    
    @Test func intMaxValidatorValid() throws {
        let schemaInput = "{ age: int max(100) }"
        let input = "{ age: 50 }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func intMaxValidatorInvalid() throws {
        let schemaInput = "{ age: int max(100) }"
        let input = "{ age: 120 }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
        if case let .failure(failure) = result {
            #expect(failure.errors.count == 1)
            #expect(failure.errors[0].message == "'age' cannot be more than 100")
        }
    }
    
    @Test func numMinValidatorValid() throws {
        let schemaInput = "{ rating: num min(0) }"
        let input = "{ rating: 4.5 }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func numMinValidatorInvalid() throws {
        let schemaInput = "{ rating: num min(0) }"
        let input = "{ rating: -0.5 }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
        if case let .failure(failure) = result {
            #expect(failure.errors.count == 1)
            #expect(failure.errors[0].message == "'rating' must be at least 0")
        }
    }
    
    @Test func numMaxValidatorValid() throws {
        let schemaInput = "{ rating: num max(5) }"
        let input = "{ rating: 4.5 }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func numMaxValidatorInvalid() throws {
        let schemaInput = "{ rating: num max(5) }"
        let input = "{ rating: 5.5 }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
        if case let .failure(failure) = result {
            #expect(failure.errors.count == 1)
            #expect(failure.errors[0].message == "'rating' cannot be more than 5")
        }
    }
    
    @Test func fieldNotFound() throws {
        let schemaInput = "{ name: string, age: int }"
        let input = "{ name: \"Alice\" }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
        if case let .failure(failure) = result {
            #expect(failure.errors.count == 1)
            #expect(failure.errors[0].message == "Field not found: age")
        }
    }
    
    @Test func multipleFieldsValid() throws {
        let schemaInput = "{ name: string, age: int, is_active: bool }"
        let input = "{ name: \"Alice\", age: 25, is_active: true }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func multipleFieldsInvalid() throws {
        let schemaInput = "{ name: string, age: int, is_active: bool }"
        let input = "{ name: \"Alice\", age: 25.5, is_active: \"yes\" }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
        if case let .failure(failure) = result {
            #expect(failure.errors.count == 2)
        }
    }
    
    @Test func arrayValid() throws {
        let schemaInput = "{ fruits: [string] }"
        let input = "{ fruits: [\"apple\", \"banana\"] }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func arrayInvalid() throws {
        let schemaInput = "{ fruits: [string] }"
        let input = "{ fruits: [\"apple\", 5] }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
        if case let .failure(failure) = result {
            #expect(failure.errors.count == 1)
            #expect(failure.errors[0].message == "'1' must be a string value")
        }
    }
    
    @Test func nestedObjectValid() throws {
        let schemaInput = "{ child: { is_active: bool } }"
        let input = "{ child: { is_active: true } }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func nestedObjectInvalid() throws {
        let schemaInput = "{ child: { is_active: bool } }"
        let input = "{ child: { is_active: 1 } }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
        if case let .failure(failure) = result {
            #expect(failure.errors.count == 1)
            #expect(failure.errors[0].message == "'is_active' must be a boolean value")
        }
    }
    
    @Test func nestedArrayValid() throws {
        let schemaInput = "{ points: [[ int ]] }"
        let input = "{ points: [[0, 1], [1, 2]] }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func nestedArrayInvalid() throws {
        let schemaInput = "{ points: [[ int ]] }"
        let input = "{ points: [[0, 1], [\"one\", \"two\"]] }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
        if case let .failure(failure) = result {
            #expect(failure.errors.count == 2)
            #expect(failure.errors[0].message == "'0' must be an integer value")
            #expect(failure.errors[1].message == "'1' must be an integer value")
        }
    }
    
    @Test func objectInArrayValid() throws {
        let schemaInput = "{ children: [ { name: string, age: int }] }"
        let input = "{ children: [ { name: \"Child A\", age: 12 }] }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func objectInArrayInvalid() throws {
        let schemaInput = "{ children: [ { name: string, age: int }] }"
        let input = "{ children: [ { name: 12, age: 12 }] }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
        if case let .failure(failure) = result {
            #expect(failure.errors.count == 1)
            #expect(failure.errors[0].message == "'name' must be a string value")
        }
    }
    
    @Test func unionTypeValidFirst() throws {
        let schemaInput = "{ value: string | int }"
        let input = "{ value: \"hello\" }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func unionTypeValidSecond() throws {
        let schemaInput = "{ value: string | int }"
        let input = "{ value: 42 }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func unionTypeInvalid() throws {
        let schemaInput = "{ value: string | int }"
        let input = "{ value: true }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
        if case let .failure(failure) = result {
            #expect(failure.errors.count == 1)
            #expect(failure.errors[0].message == "'value' must be a string value | 'value' must be an integer value")
        }
    }
    
    @Test func unionOfThreeTypesValid() throws {
        let schemaInput = "{ value: string | int | bool }"
        let input = "{ value: false }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func unionTypeInArrayValid() throws {
        let schemaInput = "{ values: [string | int] }"
        let input = "{ values: [\"hello\", 45] }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func unionTypeInArrayInvalid() throws {
        let schemaInput = "{ values: [ string | int ] }"
        let input = "{ values: [ true ] }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
        if case let .failure(failure) = result {
            #expect(failure.errors.count == 1)
            #expect(failure.errors[0].message == "'0' must be a string value | '0' must be an integer value")
        }
    }
    
    @Test func stringMinLengthValid() throws {
        let schemaInput = "{ name: string minlen(3) }"
        let input = "{ name: \"Alice\" }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func stringMinLengthInvalid() throws {
        let schemaInput = "{ name: string minlen(3) }"
        let input = "{ name: \"Al\" }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
        if case let .failure(failure) = result {
            #expect(failure.errors.count == 1)
            #expect(failure.errors[0].message == "'name' must be at least 3 characters")
        }
    }
    
    @Test func stringMaxLengthValid() throws {
        let schemaInput = "{ name: string maxlen(10) }"
        let input = "{ name: \"Alice\" }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func stringMaxLengthInvalid() throws {
        let schemaInput = "{ name: string maxlen(5) }"
        let input = "{ name: \"Alexander\" }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
        if case let .failure(failure) = result {
            #expect(failure.errors.count == 1)
            #expect(failure.errors[0].message == "'name' cannot be more than 5 characters")
        }
    }
    
    @Test func stringRegexValid() throws {
        let schemaInput = "{ email: string pattern(/^[^@]+@[^@]+$/) }"
        let input = "{ email: \"user@example.com\" }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func stringRegexInvalid() throws {
        let schemaInput = "{ email: string pattern(/^[^@]+@[^@]+$/) }"
        let input = "{ email: \"not-an-email\" }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
        if case let .failure(failure) = result {
            #expect(failure.errors.count == 1)
            #expect(failure.errors[0].message == "'email' doesn't match pattern '/^[^@]+@[^@]+$/'")
        }
    }
    
    @Test func dateMinValid() throws {
        let schemaInput = "{ birthday: date min(2000-01-01) }"
        let input = "{ birthday: 2005-06-15 }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func dateMinInvalid() throws {
        let schemaInput = "{ birthday: date min(2000-01-01) }"
        let input = "{ birthday: 1995-06-15 }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
        if case let .failure(failure) = result {
            #expect(failure.errors.count == 1)
            #expect(failure.errors[0].message == "'birthday' must be at least 2000-01-01")
        }
    }
    
    @Test func dateMaxValid() throws {
        let schemaInput = "{ birthday: date max(2025-01-01) }"
        let input = "{ birthday: 2020-06-15 }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func dateMaxInvalid() throws {
        let schemaInput = "{ birthday: date max(2020-01-01) }"
        let input = "{ birthday: 2025-06-15 }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
        if case let .failure(failure) = result {
            #expect(failure.errors.count == 1)
            #expect(failure.errors[0].message == "'birthday' cannot be after 2020-01-01")
        }
    }
    
    @Test func mixValidFirstAlternative() throws {
        let schemaInput = "{ @mix({ role: \"admin\", level: int } | { role: \"user\", plan: string }) }"
        let input = "{ role: \"admin\", level: 5 }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func mixValidSecondAlternative() throws {
        let schemaInput = "{ @mix({ role: \"admin\", level: int } | { role: \"user\", plan: string }) }"
        let input = "{ role: \"user\", plan: \"premium\" }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func mixInvalidAllAlternatives() throws {
        let schemaInput = "{ @mix({ role: \"admin\", level: int } | { role: \"user\", plan: string }) }"
        let input = "{ role: \"guest\", plan: \"free\" }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
        if case let .failure(failure) = result {
            #expect(failure.errors.count == 1)
            #expect(failure.errors[0].message.contains("'role' must be 'admin' & Field not found: level | 'role' must be 'user'"))
        }
    }
    
    @Test func anyNoPatternValid() throws {
        let schemaInput = "{ @props(): string }"
        let input = "{ greeting: \"hello\", farewell: \"goodbye\" }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func anyNoPatternInvalidType() throws {
        let schemaInput = "{ @props(): string }"
        let input = "{ greeting: \"hello\", count: 5 }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func anyWithPatternValid() throws {
        let schemaInput = "{ @props(/v\\d/): string }"
        let input = "{ v1: \"version 1\", v2: \"version 2\" }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func anyWithPatternInvalidName() throws {
        let schemaInput = "{ @props(/v\\d/): string }"
        let input = "{ version1: \"version 1\", v2: \"version 2\" }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
        if case let .failure(failure) = result {
            #expect(failure.errors.count == 1)
            #expect(failure.errors[0].message == "'version1' name doesn't match pattern '/v\\d/'")
        }
    }
    
    @Test func anyWithPatternInvalidType() throws {
        let schemaInput = "{ @props(/v\\d/): int }"
        let input = "{ v1: \"version 1\", v2: \"version 2\" }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
        if case let .failure(failure) = result {
            #expect(failure.errors.count == 2)
            #expect(failure.errors[0].message == "'v1' must be an integer value")
            #expect(failure.errors[1].message == "'v2' must be an integer value")
        }
    }
    
    @Test func multipleValidatorsOnInt() throws {
        let schemaInput = "{ age: int min(18) max(100) }"
        let input = "{ age: 25 }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func multipleValidatorsOnIntInvalidMin() throws {
        let schemaInput = "{ age: int min(18) max(100) }"
        let input = "{ age: 15 }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
        if case let .failure(failure) = result {
            #expect(failure.errors.count == 1)
            #expect(failure.errors[0].message == "'age' must be at least 18")
        }
    }
    
    @Test func multipleValidatorsOnIntInvalidMax() throws {
        let schemaInput = "{ age: int min(18) max(100) }"
        let input = "{ age: 120 }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
        if case let .failure(failure) = result {
            #expect(failure.errors.count == 1)
            #expect(failure.errors[0].message == "'age' cannot be more than 100")
        }
    }
    
    @Test func multipleValidatorsOnString() throws {
        let schemaInput = "{ username: string minlen(3) maxlen(20) pattern(/^[a-z]+$/) }"
        let input = "{ username: \"alice\" }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func multipleValidatorsOnStringInvalidMin() throws {
        let schemaInput = "{ username: string minlen(3) maxlen(20) pattern(/^[a-z]+$/) }"
        let input = "{ username: \"al\" }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
        if case let .failure(failure) = result {
            #expect(failure.errors.count == 1)
            #expect(failure.errors[0].message == "'username' must be at least 3 characters")
        }
    }
    
    @Test func multipleValidatorsOnStringInvalidRegex() throws {
        let schemaInput = "{ username: string minlen(3) maxlen(20) pattern(/^[a-z]+$/) }"
        let input = "{ username: \"Alice123\" }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
        if case let .failure(failure) = result {
            #expect(failure.errors.count == 1)
            #expect(failure.errors[0].message.contains("doesn't match pattern"))
        }
    }
    
    @Test func boolFixedValueValid() throws {
        let schemaInput = "{ accepted: true }"
        let input = "{ accepted: true }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func boolFixedValueInvalid() throws {
        let schemaInput = "{ accepted: true }"
        let input = "{ accepted: false }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
        if case let .failure(failure) = result {
            #expect(failure.errors.count == 1)
            #expect(failure.errors[0].message == "'accepted' must be 'true'")
        }
    }
    
    @Test func emptyArrayValid() throws {
        let schemaInput = "{ items: [string] }"
        let input = "{ items: [] }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func emptyObjectValid() throws {
        let schemaInput = "{ data: {} }"
        let input = "{ data: {} }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func deeplyNestedValid() throws {
        let schemaInput = "{ data: { user: { profile: { name: string, age: int } } } }"
        let input = "{ data: { user: { profile: { name: \"Alice\", age: 30 } } } }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func deeplyNestedInvalid() throws {
        let schemaInput = "{ data: { user: { profile: { name: string, age: int } } } }"
        let input = "{ data: { user: { profile: { name: 123, age: 30 } } } }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
        if case let .failure(failure) = result {
            #expect(failure.errors.count == 1)
            #expect(failure.errors[0].message == "'name' must be a string value")
        }
    }
    
    @Test func arrayWithNestedObjectsValid() throws {
        let schemaInput = "{ users: [ { name: string, age: int } ] }"
        let input = "{ users: [ { name: \"Alice\", age: 30 }, { name: \"Bob\", age: 25 } ] }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func arrayWithNestedObjectsPartialInvalid() throws {
        let schemaInput = "{ users: [ { name: string, age: int } ] }"
        let input = "{ users: [ { name: \"Alice\", age: 30 }, { name: 45, age: 25 } ] }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
        if case let .failure(failure) = result {
            #expect(failure.errors.count == 1)
            #expect(failure.errors[0].message == "'name' must be a string value")
        }
    }
    
    @Test func unionWithArrayValid() throws {
        let schemaInput = "{ items: string | [string] }"
        let input = "{ items: [\"a\", \"b\"] }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func unionWithArrayInvalid() throws {
        let schemaInput = "{ items: string | [string] }"
        let input = "{ items: [\"a\", 5] }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
        if case let .failure(failure) = result {
            #expect(failure.errors.count == 1)
            #expect(failure.errors[0].message == "'items' must be a string value | '1' must be a string value")
        }
    }
    
    @Test func unionWithObjectValid() throws {
        let schemaInput = "{ item: { name: string } | string }"
        let input = "{ item: { name: \"a\" } }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func unionWithObjectInvalid() throws {
        let schemaInput = "{ item: { name: string } | string }"
        let input = "{ item: { name: 5 } }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
        if case let .failure(failure) = result {
            #expect(failure.errors.count == 1)
            #expect(failure.errors[0].message == "'name' must be a string value | 'item' must be a string value")
        }
    }
    
    @Test func undefinedField() throws {
        let schemaInput = "{ name: string, age: undef | num }"
        let input = "{ name: \"Harold\" }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case let .failure(failure) = result {
            let errorMessage = failure.errors.map { $0.message }.joined(separator: ", ")
            #expect(errorMessage == "")
        }
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func defInMixValid() throws {
        let schemaInput = "{ @def(admin): { role: \"admin\", level: int }, @mix(admin) }"
        let input = "{ role: \"admin\", level: 5 }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
    
    @Test func defInMixInvalid() throws {
        let schemaInput = "{ @def(admin): { role: \"admin\", level: int }, @mix(admin) }"
        let input = "{ role: \"user\", level: 5 }"
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .failure = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
        if case let .failure(failure) = result {
            #expect(failure.errors.count == 1)
            #expect(failure.errors[0].message.contains("'role' must be 'admin'"))
        }
    }
    
    @Test func recursiveDef() throws {
        let schemaInput = """
    {
        @def(node): {
            type: string,
            children: [{
                @mix(node)
            }]
        },
        @mix(node)
    }
    """
        let input = """
    {
        type: "root",
        children: [{
            type: "p",
            children: [{
                type: "h1",
                children: [],
            },
            {
                type: "text",
                children: []
            }]
        }]
    }
    """
        let obj = try unwrapParseResult(parse(input))
        let schema = try unwrapParseSchemaResult(parseSchema(schemaInput))
        let result = check(obj, schema: schema)
        if case .success = result {
            #expect(Bool(true))
        } else {
            #expect(Bool(false))
        }
    }
}
