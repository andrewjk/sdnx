import Foundation


// MARK: - Parsing Status

private struct Status {
    let input: String
    var i: String.Index
    var description: String
    var mix: Int
    var any: Int
    
    init(input: String) {
        self.input = input
        self.i = input.startIndex
        self.description = ""
        self.mix = 1
        self.any = 1
    }
}

// MARK: - Main Parser

public enum ParseSchemaError: Error {
    case unexpectedCharacter(expected: String, found: String)
    case schemaNotClosed(start: String.Index)
    case emptyArray(start: String.Index)
    case invalidEscapeSequence(String)
    case stringNotClosed(start: String.Index)
    case regexNotClosed(start: String.Index)
    case unknownMacro(String)
    case invalidFieldName(start: String.Index)
    case unsupportedValidator(String)
    case unsupportedValueType(String, start: String.Index)
    case invalidDate(String, start: String.Index)
    case invalidTime(String, start: String.Index)
}

public func parseSchema(_ input: String) throws -> Schema {
    var status = Status(input: input)
    
    trim(&status)
    
    if accept("{", &status) {
        return try parseObject(&status)
    } else {
        let found = status.i < status.input.endIndex ? String(status.input[status.i]) : "EOF"
        throw ParseSchemaError.unexpectedCharacter(expected: "{", found: found)
    }
}

// MARK: - Helper Functions

private func trim(_ status: inout Status) {
    while status.i < status.input.endIndex && status.input[status.i].isWhitespace {
        status.input.formIndex(after: &status.i)
    }
}

private func accept(_ char: String, _ status: inout Status) -> Bool {
    guard status.i < status.input.endIndex else { return false }
    if status.input[status.i] == char.first! {
        status.input.formIndex(after: &status.i)
        return true
    }
    return false
}

private func expect(_ char: String, _ status: inout Status) throws {
    guard status.i < status.input.endIndex else {
        throw ParseSchemaError.unexpectedCharacter(expected: char, found: "EOF")
    }
    if status.input[status.i] == char.first! {
        status.input.formIndex(after: &status.i)
    } else {
        throw ParseSchemaError.unexpectedCharacter(expected: char, found: String(status.input[status.i]))
    }
}

// MARK: - Parsing Functions

private func parseObject(_ status: inout Status) throws -> Schema {
    var result: Schema = [:]
    let start = status.i
    
    while true {
        trim(&status)
        
        if accept("}", &status) {
            break
        } else if status.i >= status.input.endIndex || accept("]", &status) {
            throw ParseSchemaError.schemaNotClosed(start: start)
        }
        
        try parseField(&result, &status)
        
        trim(&status)
        let _ = accept(",", &status)
    }
    
    return result
}

private func parseArray(_ status: inout Status) throws -> SchemaValue {
    trim(&status)
    let start = status.i
    
    if accept("]", &status) {
        throw ParseSchemaError.emptyArray(start: start)
    } else if accept("}", &status) {
        throw ParseSchemaError.schemaNotClosed(start: start)
    }
    
    let value = try parseValue(&status)
    
    trim(&status)
    if status.i >= status.input.endIndex || !accept("]", &status) {
        throw ParseSchemaError.schemaNotClosed(start: start)
    }
    
    return value
}

private func parseField(_ result: inout Schema, _ status: inout Status) throws {
    trim(&status)
    let start = status.i
    
    // Check for comments
    if accept("#", &status) {
        let addDescription = accept("#", &status)
        while status.i < status.input.endIndex && status.input[status.i] != "\n" {
            status.input.formIndex(after: &status.i)
        }
        if addDescription {
            let descStart = status.input.index(start, offsetBy: 2)
            let descEnd = status.i
            status.description += String(status.input[descStart..<descEnd])
        }
        return
    }
    
    // Check for macros
    if accept("@", &status) {
        let macroStart = status.i
        while status.i < status.input.endIndex && !status.input[status.i].isWhitespace && status.input[status.i] != "(" {
            status.input.formIndex(after: &status.i)
        }
        let macro = String(status.input[macroStart..<status.i])
        trim(&status)
        try expect("(", &status)
        
        switch macro {
        case "mix":
            trim(&status)
            try expect("{", &status)
            var alternatives = [try parseObject(&status)]
            trim(&status)
            while accept("|", &status) {
                trim(&status)
                try expect("{", &status)
                alternatives.append(try parseObject(&status))
                trim(&status)
            }
            try expect(")", &status)
            result["mix$\(status.mix)"] = MixSchema(inner: alternatives)
            status.mix += 1
            
        case "any":
            trim(&status)
            let patternStart = status.i
            var level = 1
            while status.i < status.input.endIndex {
                let char = status.input[status.i]
                if char == "(" && status.input[status.input.index(before: status.i)] != "\\" {
                    level += 1
                } else if char == ")" && status.input[status.input.index(before: status.i)] != "\\" {
                    level -= 1
                    if level == 0 { break }
                } else if char.isWhitespace {
                    break
                }
                status.input.formIndex(after: &status.i)
            }
            let pattern = String(status.input[patternStart..<status.i])
            trim(&status)
            try expect(")", &status)
            trim(&status)
            try expect(":", &status)
            let anyResult = AnySchema(pattern: pattern, inner: try parseValue(&status))
            result["any$\(status.any)"] = anyResult
            status.any += 1
            
        default:
            throw ParseSchemaError.unknownMacro(macro)
        }
        return
    }
    
    var name = ""
    if accept("\"", &status) {
        name = try parseString(&status)
    } else {
        if status.i >= status.input.endIndex || !isAlphaOrUnderscore(status.input[status.i]) {
            throw ParseSchemaError.invalidFieldName(start: start)
        }
        status.input.formIndex(after: &status.i)
        while status.i < status.input.endIndex && isAlphaNumericOrUnderscore(status.input[status.i]) {
            status.input.formIndex(after: &status.i)
        }
        name = String(status.input[start..<status.i])
    }
    
    trim(&status)
    try expect(":", &status)
    
    result[name] = try parseValue(&status)
}

private func parseValue(_ status: inout Status) throws -> SchemaValue {
    var value = try parseSingleValue(&status)
    
    trim(&status)
    if accept("|", &status) {
        var inner = [value]
        while true {
            trim(&status)
            inner.append(try parseSingleValue(&status))
            trim(&status)
            if !accept("|", &status) {
                break
            }
        }
        value = UnionSchema(inner: inner)
    }
    
    return value
}

private func parseSingleValue(_ status: inout Status) throws -> SchemaValue {
    trim(&status)
    if accept("{", &status) {
        return ObjectSchema(inner: try parseObject(&status))
    } else if accept("[", &status) {
        return ArraySchema(inner: try parseArray(&status))
    } else if accept("\"", &status) {
        return FieldSchema(type: try parseString(&status, withQuotes: true))
    } else {
        return try parseType(&status)
    }
}

private func parseType(_ status: inout Status) throws -> FieldSchema {
    let start = status.i
    while status.i < status.input.endIndex && !["|", ",", "}", "]", "["].contains(status.input[status.i]) && !status.input[status.i].isWhitespace {
        status.input.formIndex(after: &status.i)
    }
    
    let type = String(status.input[start..<status.i]).trimmingCharacters(in: .whitespaces)
    
    // Validate type
    let validTypes = ["undef", "null", "bool", "int", "num", "string", "date"]
    if !validTypes.contains(type) {
        _ = try convertValue(type, start: -1)
    }
    
    var result = FieldSchema(type: type)
    if !status.description.isEmpty {
        result.description = status.description.trimmingCharacters(in: .whitespaces)
        status.description = ""
    }
    
    // Parse validators
    trim(&status)
    var validators: [String: ValidatorInfo] = [:]
    
    while status.i < status.input.endIndex && !["|", ",", "}", "]", "["].contains(status.input[status.i]) {
        let validatorStart = status.i
        while status.i < status.input.endIndex && !["|", ",", "}", "]", "[", "("].contains(status.input[status.i]) && !status.input[status.i].isWhitespace {
            status.input.formIndex(after: &status.i)
        }
        let validator = String(status.input[validatorStart..<status.i])
        
        var raw = "true"
        var required: Any? = true
        
        trim(&status)
        if accept("(", &status) {
            trim(&status)
            if accept("\"", &status) {
                raw = try parseString(&status, withQuotes: true)
                required = try convertValue(raw, start: -1)
            } else if accept("/", &status) {
                raw = try parseRegex(&status)
                required = try convertValue(raw, start: -1)
            } else {
                let valStart = status.i
                while status.i < status.input.endIndex && !status.input[status.i].isWhitespace && status.input[status.i] != ")" {
                    status.input.formIndex(after: &status.i)
                }
                raw = String(status.input[valStart..<status.i])
                required = try convertValue(raw, start: -1)
            }
            trim(&status)
            try expect(")", &status)
            trim(&status)
        }
        
        validators[validator] = ValidatorInfo(raw: raw, required: required)
    }
    
    if !validators.isEmpty {
        result.validators = validators
    }
    
    return result
}

private func parseString(_ status: inout Status, withQuotes: Bool = false) throws -> String {
    let start = withQuotes ? status.input.index(before: status.i) : status.i
    
    while status.i < status.input.endIndex {
        if status.input[status.i] == "\\" {
            status.input.formIndex(after: &status.i)
            if status.i >= status.input.endIndex || status.input[status.i] != "\"" {
                let escapeChar = status.i < status.input.endIndex ? String(status.input[status.i]) : "EOF"
                throw ParseSchemaError.invalidEscapeSequence("\\\(escapeChar)")
            }
            status.input.formIndex(after: &status.i)
        } else if status.input[status.i] == "\"" {
            break
        } else {
            status.input.formIndex(after: &status.i)
        }
    }
    
    if status.i >= status.input.endIndex {
        throw ParseSchemaError.stringNotClosed(start: start)
    }
    
    status.input.formIndex(after: &status.i)
    let end = withQuotes ? status.i : status.input.index(before: status.i)
    return String(status.input[start..<end])
}

private func parseRegex(_ status: inout Status) throws -> String {
    let start = status.input.index(before: status.i)
    
    while status.i < status.input.endIndex {
        if status.input[status.i] == "/" && status.input[status.input.index(before: status.i)] != "\\" {
            break
        }
        status.input.formIndex(after: &status.i)
    }
    
    if status.i >= status.input.endIndex {
        throw ParseSchemaError.regexNotClosed(start: start)
    }
    
    while status.i < status.input.endIndex && !status.input[status.i].isWhitespace && status.input[status.i] != ")" {
        status.input.formIndex(after: &status.i)
    }
    
    return String(status.input[start..<status.i])
}

// MARK: - Character Helpers

private func isAlphaOrUnderscore(_ char: Character) -> Bool {
    return char == "_" || char.isLetter
}

private func isAlphaNumericOrUnderscore(_ char: Character) -> Bool {
    return char == "_" || char.isLetter || char.isNumber
}
