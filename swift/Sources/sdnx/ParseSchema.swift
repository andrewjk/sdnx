import Foundation

// MARK: - Parse Schema Result Types

public enum ParseSchemaResult {
    case success(ParseSuccess<Schema>)
    case failure(ParseFailure)
}

// MARK: - Internal Error Types

private enum InternalParseSchemaError: Error {
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

private enum ParseException: Error {
    case earlyExit
}

// MARK: - Parsing Status

private struct Status {
    let input: String
    var i: String.Index
    var description: String
    var mix: Int
    var any: Int
    var errors: [ParseError]
    
    init(input: String) {
        self.input = input
        self.i = input.startIndex
        self.description = ""
        self.mix = 1
        self.any = 1
        self.errors = []
    }
}

// MARK: - Main Parser

public func parseSchema(_ input: String) -> ParseSchemaResult {
    var status = Status(input: input)
    
    trim(&status)
    
    do {
        if accept("{", &status) {
            let data = try parseObject(&status)
            if status.errors.isEmpty {
                return .success(ParseSuccess(data: data))
            } else {
                return .failure(ParseFailure(errors: status.errors))
            }
        } else {
            let found = status.i < status.input.endIndex ? String(status.input[status.i]) : "EOF"
            let startIndex = status.input.startIndex
            let index = status.input.distance(from: startIndex, to: status.i)
            status.errors.append(ParseError(
                message: "Expected '{' but found '\(found)'",
                index: index,
                length: 1
            ))
            throw ParseException.earlyExit
        }
    } catch ParseException.earlyExit {
        return .failure(ParseFailure(errors: status.errors))
    } catch {
        return .failure(ParseFailure(errors: status.errors))
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
        let startIndex = status.input.startIndex
        let index = status.input.distance(from: startIndex, to: status.i)
        status.errors.append(ParseError(
            message: "Expected '\(char)' but found EOF",
            index: index,
            length: 1
        ))
        throw ParseException.earlyExit
    }
    if status.input[status.i] == char.first! {
        status.input.formIndex(after: &status.i)
    } else {
        let startIndex = status.input.startIndex
        let index = status.input.distance(from: startIndex, to: status.i)
        status.errors.append(ParseError(
            message: "Expected '\(char)' but found '\(status.input[status.i])'",
            index: index,
            length: 1
        ))
        throw ParseException.earlyExit
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
            let startIndex = status.input.startIndex
            let index = status.input.distance(from: startIndex, to: start)
            status.errors.append(ParseError(
                message: "Schema object not closed",
                index: index,
                length: 1
            ))
            throw ParseException.earlyExit
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
        let startIndex = status.input.startIndex
        let index = status.input.distance(from: startIndex, to: start)
        let length = status.input.distance(from: start, to: status.i)
        status.errors.append(ParseError(
            message: "Schema array empty",
            index: index,
            length: length
        ))
    } else if accept("}", &status) {
        let startIndex = status.input.startIndex
        let index = status.input.distance(from: startIndex, to: start)
        status.errors.append(ParseError(
            message: "Schema array not closed",
            index: index,
            length: 1
        ))
        throw ParseException.earlyExit
    }
    
    let value = try parseValue(&status)
    
    trim(&status)
    if status.i >= status.input.endIndex || !accept("]", &status) {
        let startIndex = status.input.startIndex
        let index = status.input.distance(from: startIndex, to: start)
        status.errors.append(ParseError(
            message: "Schema array not closed",
            index: index,
            length: 1
        ))
        throw ParseException.earlyExit
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
            
        case "props":
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
            result["props$\(status.any)"] = anyResult
            status.any += 1
            
        default:
            let startIndex = status.input.startIndex
            let index = status.input.distance(from: startIndex, to: status.input.index(status.i, offsetBy: -macro.count))
            status.errors.append(ParseError(
                message: "Unknown macro: '\(macro)'",
                index: index,
                length: macro.count
            ))
            throw ParseException.earlyExit
        }
        return
    }
    
    var name = ""
    if accept("\"", &status) {
        name = try parseString(&status)
    } else {
        if status.i >= status.input.endIndex || !isAlphaOrUnderscore(status.input[status.i]) {
            let startIndex = status.input.startIndex
            let index = status.input.distance(from: startIndex, to: start)
            status.errors.append(ParseError(
                message: "Field must start with quote or alpha",
                index: index,
                length: 1
            ))
            throw ParseException.earlyExit
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
        let index = status.input.distance(from: status.input.startIndex, to: start)
        _ = convertValue(type, start: index, errors: &status.errors)
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
        
        // Check if validator is supported for this type
        let validatorsDict = getValidators()
        if let typeValidators = validatorsDict[type] {
            if typeValidators[validator] == nil {
                let index = status.input.distance(from: status.input.startIndex, to: validatorStart)
                status.errors.append(ParseError(
                    message: "Unsupported validator '\(validator)'",
                    index: index,
                    length: validator.count
                ))
            }
        }
        
        var raw = "true"
        var required: Any? = true
        
        trim(&status)
        if accept("(", &status) {
            trim(&status)
            if accept("\"", &status) {
                raw = try parseString(&status, withQuotes: true)
                let index = status.input.distance(from: status.input.startIndex, to: start)
                required = convertValue(raw, start: index, errors: &status.errors)
            } else if accept("/", &status) {
                raw = try parseRegex(&status)
                let index = status.input.distance(from: status.input.startIndex, to: start)
                required = convertValue(raw, start: index, errors: &status.errors)
            } else {
                let valStart = status.i
                while status.i < status.input.endIndex && !status.input[status.i].isWhitespace && status.input[status.i] != ")" {
                    status.input.formIndex(after: &status.i)
                }
                raw = String(status.input[valStart..<status.i])
                let index = status.input.distance(from: status.input.startIndex, to: start)
                required = convertValue(raw, start: index, errors: &status.errors)
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
                let startIndex = status.input.startIndex
                let index = status.input.distance(from: startIndex, to: status.input.index(before: status.i))
                status.errors.append(ParseError(
                    message: "Invalid escape sequence '\\\(escapeChar)'",
                    index: index,
                    length: 2
                ))
            }
            status.input.formIndex(after: &status.i)
        } else if status.input[status.i] == "\"" {
            break
        } else {
            status.input.formIndex(after: &status.i)
        }
    }
    
    if status.i >= status.input.endIndex {
        let startIndex = status.input.startIndex
        let index = status.input.distance(from: startIndex, to: start)
        status.errors.append(ParseError(
            message: "String not closed",
            index: index,
            length: 1
        ))
        throw ParseException.earlyExit
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
        let startIndex = status.input.startIndex
        let index = status.input.distance(from: startIndex, to: start)
        status.errors.append(ParseError(
            message: "Pattern not closed",
            index: index,
            length: 1
        ))
        throw ParseException.earlyExit
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
