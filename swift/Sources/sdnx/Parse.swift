import Foundation
import Collections

// MARK: - Parse Result Types

public enum ParseResult {
    case success(ParseSuccess<OrderedDictionary<String, Any>>)
    case failure(ParseFailure)
}

// MARK: - Internal Error Types

private enum InternalParseError: Error {
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

private enum ParseException: Error {
    case earlyExit
}

// MARK: - Parsing Status

private struct Status {
    let input: String
    var i: String.Index
    var errors: [ParseError]
    
    init(input: String) {
        self.input = input
        self.i = input.startIndex
        self.errors = []
    }
}

// MARK: - Main Parser

public func parse(_ input: String) -> ParseResult {
    var status = Status(input: input)
    
    trim(&status)
    
    while true {
        if accept("#", &status) {
            parseComment(&status)
            trim(&status)
        } else if accept("@", &status) {
            do {
                try parseMacro(&status)
            } catch {
                if error is ParseException {
                    break
                }
                return .failure(ParseFailure(errors: status.errors))
            }
            trim(&status)
        } else {
            break
        }
    }
    
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

private func parseObject(_ status: inout Status) throws -> OrderedDictionary<String, Any> {
    var result: OrderedDictionary<String, Any> = [:]
    let start = status.i
    
    while true {
        trim(&status)
        
        if accept("}", &status) {
            break
        } else if status.i >= status.input.endIndex || accept("]", &status) {
            let startIndex = status.input.startIndex
            let index = status.input.distance(from: startIndex, to: start)
            status.errors.append(ParseError(
                message: "Object not closed",
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

private func parseArray(_ status: inout Status) throws -> [Any] {
    var result: [Any] = []
    let start = status.i
    
    while true {
        trim(&status)
        
        if accept("]", &status) {
            break
        } else if status.i >= status.input.endIndex || accept("}", &status) {
            let startIndex = status.input.startIndex
            let index = status.input.distance(from: startIndex, to: start)
            status.errors.append(ParseError(
                message: "Array not closed",
                index: index,
                length: 1
            ))
            throw ParseException.earlyExit
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
        let startIndex = status.input.startIndex
        let index = status.input.distance(from: startIndex, to: start)
        status.errors.append(ParseError(
            message: "Field must start with quote or alpha",
            index: index,
            length: 1
        ))
        throw ParseException.earlyExit
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
        let index = status.input.distance(from: status.input.startIndex, to: start)
        return convertValue(value, start: index, errors: &status.errors) ?? NSNull()
    }
}

private func parseString(_ status: inout Status) throws -> String {
    let start = status.i
    var result = ""
    
    while status.i < status.input.endIndex {
        if status.input[status.i] == "\\" {
            status.input.formIndex(after: &status.i)
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
                let startIndex = status.input.startIndex
                let index = status.input.distance(from: startIndex, to: status.input.index(before: status.i))
                status.errors.append(ParseError(
                    message: "Invalid escape sequence '\\\(nextChar)'",
                    index: index,
                    length: 2
                ))
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
        let startIndex = status.input.startIndex
        let index = status.input.distance(from: startIndex, to: status.input.index(status.i, offsetBy: -macro.count))
        status.errors.append(ParseError(
            message: "Unknown macro: '\(macro)'",
            index: index,
            length: macro.count
        ))
        throw ParseException.earlyExit
    }
}

// MARK: - Character Helpers

private func isAlphaOrUnderscore(_ char: Character) -> Bool {
    return char == "_" || char.isLetter
}

private func isAlphaNumericOrUnderscore(_ char: Character) -> Bool {
    return char == "_" || char.isLetter || char.isNumber
}
