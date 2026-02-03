import Foundation
import Collections

public func read(_ file: String, schema: Any? = nil) throws -> ReadResult {
    let filePath = try locate(file)
    
    guard let contents = try? String(contentsOfFile: filePath, encoding: .utf8) else {
        throw ReadError(message: "File not found: \(filePath)", index: 0, length: 0, line: "", char: 0)
    }
    
    let parsed = parse(contents)
    
    switch parsed {
    case .failure(let failure):
        return .failure(ReadFailure(
            schemaErrors: failure.errors.map { buildReadError($0, contents: contents) },
            dataErrors: [],
            checkErrors: []
        ))
    case .success(let success):
        var schemaValue: Schema?
        var schemaPath: String?
        
        // If there's a @schema directive, try to load the schema from there
        if schema == nil {
            let pattern = "^\\s*@schema\\(\"(.+?)\"\\)"
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: contents, options: [], range: NSRange(contents.startIndex..., in: contents)) {
                let schemaRange = match.range(at: 1)
                if let swiftRange = Range(schemaRange, in: contents) {
                    let directivePath = String(contents[swiftRange])
                    let fileURL = URL(fileURLWithPath: filePath)
                    schemaPath = URL(fileURLWithPath: directivePath, relativeTo: fileURL.deletingLastPathComponent()).path
                }
            }
            
            if schemaPath == nil {
                throw ReadError(message: "Schema required", index: 0, length: 0, line: "", char: 0)
            }
        } else if let s = schema as? String {
            schemaPath = try locate(s)
        } else if let s = schema as? Schema {
            schemaValue = s
        }
        
        // If schema is a path string, read and parse it
        if let path = schemaPath {
            guard let schemaContents = try? String(contentsOfFile: path, encoding: .utf8) else {
                throw ReadError(message: "Schema file not found: \(path)", index: 0, length: 0, line: "", char: 0)
            }
            
            let schemaParsed = parseSchema(schemaContents)
            switch schemaParsed {
            case .failure(let failure):
                return .failure(ReadFailure(
                    schemaErrors: failure.errors.map { buildReadError($0, contents: schemaContents) },
                    dataErrors: [],
                    checkErrors: []
                ))
            case .success(let schemaSuccess):
                schemaValue = schemaSuccess.data
            }
        }
        
        guard let finalSchema = schemaValue else {
            throw ReadError(message: "Invalid schema", index: 0, length: 0, line: "", char: 0)
        }
        
        let checked = check(success.data, schema: finalSchema)
        switch checked {
        case .success:
            return .success(ReadSuccess(data: success.data))
        case .failure(let failure):
            return .failure(ReadFailure(
                schemaErrors: [],
                dataErrors: [],
                checkErrors: failure.errors
            ))
        }
    }
}

private func locate(_ file: String) throws -> String {
    let fileManager = FileManager.default
    
    if fileManager.fileExists(atPath: file) {
        return file
    }
    
    let cwd = fileManager.currentDirectoryPath
    let cwdPath = (cwd as NSString).appendingPathComponent(file)
    
    if fileManager.fileExists(atPath: cwdPath) {
        return cwdPath
    }
    
    throw ReadError(message: "File not found: \(file)", index: 0, length: 0, line: "", char: 0)
}

private func buildReadError(_ error: ParseError, contents: String) -> ReadError {
    // Handle edge cases
    if contents.isEmpty {
        return ReadError(
            message: error.message,
            index: error.index,
            length: error.length,
            line: "",
            char: 0
        )
    }
    
    // Use NSString for safer UTF-16 based indexing
    let nsString = contents as NSString
    let length = nsString.length
    
    // Ensure index is within valid bounds (0 to length)
    let safeIndex = max(0, min(error.index, length))
    
    // Handle case where index is at the very end
    if safeIndex == 0 && length == 0 {
        return ReadError(
            message: error.message,
            index: safeIndex,
            length: error.length,
            line: "",
            char: 0
        )
    }
    
    // Find line start - scan backwards for newline
    var lineStartIndex = safeIndex
    while lineStartIndex > 0 {
        let prevChar = nsString.character(at: lineStartIndex - 1)
        if prevChar == 10 { // \n
            break
        }
        lineStartIndex -= 1
    }
    
    // Find line end - scan forwards for newline or end of string
    var lineEndIndex = safeIndex
    while lineEndIndex < length {
        let currChar = nsString.character(at: lineEndIndex)
        if currChar == 10 { // \n
            break
        }
        lineEndIndex += 1
    }
    
    // Ensure we have a valid range
    let rangeLength = max(0, lineEndIndex - lineStartIndex)
    let lineRange = NSRange(location: lineStartIndex, length: rangeLength)
    
    // Extract the line safely
    let line: String
    if lineRange.location < length && lineRange.length >= 0 {
        line = nsString.substring(with: lineRange)
    } else {
        line = ""
    }
    
    // Calculate char position (distance from line start)
    let char = safeIndex - lineStartIndex
    
    return ReadError(
        message: error.message,
        index: safeIndex,
        length: error.length,
        line: line,
        char: char
    )
}
