import Foundation
import Collections

// MARK: - Parsing Status

private struct Status {
    let input: String
    var i: String.Index
    
    init(input: String) {
        self.input = input
        self.i = input.startIndex
    }
}

// MARK: - Main Parser

public enum ParseError: Error {
    case unexpectedCharacter(expected: String, found: String)
    case objectNotClosed(start: String.Index)
    case arrayNotClosed(start: String.Index)
    case invalidEscapeSequence(String)
    case stringNotClosed(start: String.Index)
    case unknownMacro(String)
    case invalidFieldName(start: String.Index)
    case unsupportedValueType(String, start: String.Index)
    case invalidDate(String, start: String.Index)
    case invalidTime(String, start: String.Index)
}

public func parse(_ input: String) throws -> OrderedDictionary<String, Any> {
    var status = Status(input: input)
    
    trim(&status)
    
    while true {
        if accept("#", &status) {
            parseComment(&status)
            trim(&status)
        } else if accept("@", &status) {
            try parseMacro(&status)
            trim(&status)
        } else {
            break
        }
    }
    
    if accept("{", &status) {
        return try parseObject(&status)
    } else {
        let found = status.i < status.input.endIndex ? String(status.input[status.i]) : "EOF"
        throw ParseError.unexpectedCharacter(expected: "{", found: found)
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
        throw ParseError.unexpectedCharacter(expected: char, found: "EOF")
    }
    if status.input[status.i] == char.first! {
        status.input.formIndex(after: &status.i)
    } else {
        throw ParseError.unexpectedCharacter(expected: char, found: String(status.input[status.i]))
    }
}

// MARK: - Parsing Functions

private func parseObject(_ status: inout Status) throws -> OrderedDictionary<String, Any> {
    var result: OrderedDictionary<String, Any> = [:]
    let start = status.i
    
    while true {
        trim(&status)
        
        if accept("}", &status) {
            break
        } else if status.i >= status.input.endIndex || accept("]", &status) {
            throw ParseError.objectNotClosed(start: start)
        }
        
        try parseField(&result, &status)
        
        trim(&status)
        let _ = accept(",", &status)
    }
    
    return result
}

private func parseArray(_ status: inout Status) throws -> [Any] {
    var result: [Any] = []
    let start = status.i
    
    while true {
        trim(&status)
        
        if accept("]", &status) {
            break
        } else if status.i >= status.input.endIndex || accept("}", &status) {
            throw ParseError.arrayNotClosed(start: start)
        } else if !result.isEmpty {
            try expect(",", &status)
            trim(&status)
        }
        
        let value = try parseValue(&status)
        result.append(value)
    }
    
    return result
}

private func parseField(_ result: inout OrderedDictionary<String, Any>, _ status: inout Status) throws {
    trim(&status)
    
    if accept("#", &status) {
        parseComment(&status)
        return
    }
    
    let start = status.i
    var name = ""
    
    if accept("\"", &status) {
        while status.i < status.input.endIndex && status.input[status.i] != "\"" {
            status.input.formIndex(after: &status.i)
        }
        status.input.formIndex(after: &status.i)
        name = String(status.input[start..<status.i])
    } else if status.i < status.input.endIndex && isAlphaOrUnderscore(status.input[status.i]) {
        status.input.formIndex(after: &status.i)
        while status.i < status.input.endIndex && isAlphaNumericOrUnderscore(status.input[status.i]) {
            status.input.formIndex(after: &status.i)
        }
        name = String(status.input[start..<status.i])
    } else {
        throw ParseError.invalidFieldName(start: start)
    }
    
    trim(&status)
    try expect(":", &status)

    result[name] = try parseValue(&status)
}

private func parseValue(_ status: inout Status) throws -> Any {
    trim(&status)
    if accept("{", &status) {
        return try parseObject(&status)
    } else if accept("[", &status) {
        return try parseArray(&status)
    } else if accept("\"", &status) {
        return try parseString(&status)
    } else {
        let start = status.i
        while status.i < status.input.endIndex && ![",", "}", "]"].contains(status.input[status.i]) && !status.input[status.i].isWhitespace {
            status.input.formIndex(after: &status.i)
        }
        let value = String(status.input[start..<status.i]).trimmingCharacters(in: .whitespaces)
        return try convertValue(value, start: start) ?? NSNull()
    }
}

private func parseString(_ status: inout Status) throws -> String {
    let start = status.i
    var result = ""
    
    while status.i < status.input.endIndex {
        if status.input[status.i] == "\\" {
            status.input.formIndex(after: &status.i)
            if status.i >= status.input.endIndex {
                throw ParseError.stringNotClosed(start: start)
            }
            let nextChar = status.input[status.i]
            if nextChar == "\"" {
                result.append("\"")
            } else if nextChar == "\\" {
                result.append("\\")
            } else if nextChar == "n" {
                result.append("\n")
            } else if nextChar == "t" {
                result.append("\t")
            } else if nextChar == "r" {
                result.append("\r")
            } else {
                throw ParseError.invalidEscapeSequence("\\\(nextChar)")
            }
            status.input.formIndex(after: &status.i)
        } else if status.input[status.i] == "\"" {
            break
        } else {
            result.append(status.input[status.i])
            status.input.formIndex(after: &status.i)
        }
    }
    
    if status.i >= status.input.endIndex {
        throw ParseError.stringNotClosed(start: start)
    }
    
    status.input.formIndex(after: &status.i)
    
    // Trim leading spaces from multiline strings
    if result.hasPrefix("\n") {
        let lines = result.components(separatedBy: "\n")
        if lines.count > 1 {
            let secondLine = lines[1]
            if let spaceMatch = secondLine.range(of: "^\\s+", options: .regularExpression) {
                let space = String(secondLine[spaceMatch])
                let trimmedLines = lines.dropFirst().map { line in
                    if line.hasPrefix(space) {
                        return String(line.dropFirst(space.count))
                    }
                    return line
                }
                result = trimmedLines.joined(separator: "\n").trimmingCharacters(in: .whitespaces)
            }
        }
    }
    
    return result
}

private func parseComment(_ status: inout Status) {
    while status.i < status.input.endIndex && status.input[status.i] != "\n" {
        status.input.formIndex(after: &status.i)
    }
}

private func parseMacro(_ status: inout Status) throws {
    let start = status.i
    while status.i < status.input.endIndex && !status.input[status.i].isWhitespace && status.input[status.i] != "(" {
        status.input.formIndex(after: &status.i)
    }
    let macro = String(status.input[start..<status.i])
    trim(&status)
    try expect("(", &status)
    
    switch macro {
    case "schema":
        trim(&status)
        while status.i < status.input.endIndex && !status.input[status.i].isWhitespace && status.input[status.i] != ")" {
            status.input.formIndex(after: &status.i)
        }
        trim(&status)
        try expect(")", &status)
    default:
        throw ParseError.unknownMacro(macro)
    }
}

// MARK: - Character Helpers

private func isAlphaOrUnderscore(_ char: Character) -> Bool {
    return char == "_" || char.isLetter
}

private func isAlphaNumericOrUnderscore(_ char: Character) -> Bool {
    return char == "_" || char.isLetter || char.isNumber
}
