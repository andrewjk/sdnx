import Foundation

// MARK: - ValidatorFunction Type

typealias ValidatorFunction = @Sendable (
    _ field: String,
    _ value: Any,
    _ raw: String,
    _ required: Any,
    _ status: inout CheckStatus
) -> Bool

// MARK: - Validators Dictionary

func getValidators() -> [String: [String: ValidatorFunction]] {
    var validators: [String: [String: ValidatorFunction]] = [:]
    validators["bool"] = [:]
    validators["int"] = [
        "min": validateMin,
        "max": validateMax,
    ]
    validators["num"] = [
        "min": validateMin,
        "max": validateMax,
    ]
    validators["date"] = [
        "min": validateMinDate,
        "max": validateMaxDate,
    ]
    validators["string"] = [
        "minlen": validateMinLen,
        "maxlen": validateMaxLen,
        "pattern": validatePattern,
    ]
    validators["array"] = [
        "minlen": validateMinLenArray,
        "maxlen": validateMaxLenArray,
        "unique": validateUnique,
    ]
    return validators
}

// MARK: - Validator Functions

func validateMin(field: String, value: Any, raw: String, required: Any, status: inout CheckStatus) -> Bool {
    guard let numValue = value as? NSNumber,
          let requiredNum = required as? NSNumber else {
        return false
    }
    
    if numValue.doubleValue < requiredNum.doubleValue {
        status.errors.append(CheckError(
            path: status.path,
            message: "'\(field)' must be at least \(raw)"
        ))
        return false
    }
    return true
}

func validateMax(field: String, value: Any, raw: String, required: Any, status: inout CheckStatus) -> Bool {
    guard let numValue = value as? NSNumber,
          let requiredNum = required as? NSNumber else {
        return false
    }
    
    if numValue.doubleValue > requiredNum.doubleValue {
        status.errors.append(CheckError(
            path: status.path,
            message: "'\(field)' cannot be more than \(raw)"
        ))
        return false
    }
    return true
}

func validateMinDate(field: String, value: Any, raw: String, required: Any, status: inout CheckStatus) -> Bool {
    guard let dateValue = value as? Date,
          let requiredDate = required as? Date else {
        return false
    }
    
    if dateValue < requiredDate {
        status.errors.append(CheckError(
            path: status.path,
            message: "'\(field)' must be at least \(raw)"
        ))
        return false
    }
    return true
}

func validateMaxDate(field: String, value: Any, raw: String, required: Any, status: inout CheckStatus) -> Bool {
    guard let dateValue = value as? Date,
          let requiredDate = required as? Date else {
        return false
    }
    
    if dateValue > requiredDate {
        status.errors.append(CheckError(
            path: status.path,
            message: "'\(field)' cannot be after \(raw)"
        ))
        return false
    }
    return true
}

func validateMinLen(field: String, value: Any, raw: String, required: Any, status: inout CheckStatus) -> Bool {
    guard let strValue = value as? String,
          let requiredLen = required as? NSNumber else {
        return false
    }
    
    if strValue.count < requiredLen.intValue {
        status.errors.append(CheckError(
            path: status.path,
            message: "'\(field)' must be at least \(raw) characters"
        ))
        return false
    }
    return true
}

func validateMaxLen(field: String, value: Any, raw: String, required: Any, status: inout CheckStatus) -> Bool {
    guard let strValue = value as? String,
          let requiredLen = required as? NSNumber else {
        return false
    }
    
    if strValue.count > requiredLen.intValue {
        status.errors.append(CheckError(
            path: status.path,
            message: "'\(field)' cannot be more than \(raw) characters"
        ))
        return false
    }
    return true
}

func validatePattern(field: String, value: Any, raw: String, required: Any, status: inout CheckStatus) -> Bool {
    guard let strValue = value as? String else {
        return false
    }
    
    guard let requiredStr = required as? String,
          let regex = createRegex(requiredStr) else {
        status.errors.append(CheckError(
            path: status.path,
            message: "Unsupported pattern for '\(field)': \(raw)"
        ))
        return false
    }
    
    if !regex.test(strValue) {
        status.errors.append(CheckError(
            path: status.path,
            message: "'\(field)' doesn't match pattern '\(raw)'"
        ))
        return false
    }
    return true
}

func validateMinLenArray(field: String, value: Any, raw: String, required: Any, status: inout CheckStatus) -> Bool {
    guard let arrayValue = value as? [Any],
          let requiredLen = required as? NSNumber else {
        return false
    }
    
    if arrayValue.count < requiredLen.intValue {
        status.errors.append(CheckError(
            path: status.path,
            message: "'\(field)' must contain at least \(raw) items"
        ))
        return false
    }
    return true
}

func validateMaxLenArray(field: String, value: Any, raw: String, required: Any, status: inout CheckStatus) -> Bool {
    guard let arrayValue = value as? [Any],
          let requiredLen = required as? NSNumber else {
        return false
    }
    
    if arrayValue.count > requiredLen.intValue {
        status.errors.append(CheckError(
            path: status.path,
            message: "'\(field)' cannot contain more than \(raw) items"
        ))
        return false
    }
    return true
}

func validateUnique(field: String, value: Any, raw: String, required: Any, status: inout CheckStatus) -> Bool {
    guard let arrayValue = value as? [Any] else {
        return false
    }
    
    var seen: Set<String> = []
    var ok = true
    
    for item in arrayValue {
        let itemKey: String
        if let strItem = item as? String {
            itemKey = strItem
        } else if let numItem = item as? NSNumber {
            itemKey = numItem.stringValue
        } else if let boolItem = item as? Bool {
            itemKey = boolItem.description
        } else if let dateItem = item as? Date {
            itemKey = ISO8601DateFormatter().string(from: dateItem)
        } else {
            continue
        }
        
        if seen.contains(itemKey) {
            status.errors.append(CheckError(
                path: status.path,
                message: "'\(field)' value '\(itemKey)' is not unique"
            ))
            ok = false
        } else {
            seen.insert(itemKey)
        }
    }
    
    return ok
}

// MARK: - NSNumber Extension

extension NSNumber {
    var isInt: Bool {
        return self === self.intValue as NSNumber
    }
}

// MARK: - Regex Helper

class Regex {
    private let regex: NSRegularExpression
    
    init?(pattern: String, options: NSRegularExpression.Options = []) {
        do {
            self.regex = try NSRegularExpression(pattern: pattern, options: options)
        } catch {
            return nil
        }
    }
    
    func test(_ string: String) -> Bool {
        let range = NSRange(string.startIndex..., in: string)
        return regex.firstMatch(in: string, options: [], range: range) != nil
    }
}

func createRegex(_ input: String) -> Regex? {
    guard input.hasPrefix("/") else { return nil }
    
    let patternStart = input.index(after: input.startIndex)
    var patternEnd = patternStart
    var flags = ""
    var escaped = false
    
    for char in input[patternStart...] {
        if escaped {
            escaped = false
        } else if char == "\\" {
            escaped = true
        } else if char == "/" {
            break
        }
        patternEnd = input.index(after: patternEnd)
    }
    
    let pattern = String(input[patternStart..<patternEnd])
    
    if patternEnd < input.endIndex {
        let flagsStart = input.index(after: patternEnd)
        flags = String(input[flagsStart...])
    }
    
    var options: NSRegularExpression.Options = []
    if flags.contains("i") {
        options.insert(.caseInsensitive)
    }
    
    return Regex(pattern: pattern, options: options)
}
