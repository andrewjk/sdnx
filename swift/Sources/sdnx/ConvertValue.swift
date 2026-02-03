import Foundation

// MARK: - Internal Error Types for Old API

private enum ConvertValueError: Error {
    case invalidDate(String, start: String.Index)
    case invalidTime(String, start: String.Index)
    case unsupportedValueType(String, start: String.Index)
}

// MARK: - Date/Time Normalization

/// Normalizes a datetime string to ISO8601 format with seconds.
/// Handles adding missing seconds, timezone conversions (U->Z, L removal), and space removal.
private func normalizeDateTimeString(_ value: String, isDateTime: Bool = true) -> String {
    // First, handle U -> Z, remove L, and remove spaces
    var normalized = value
        .replacingOccurrences(of: "U", with: "Z")
        .replacingOccurrences(of: "L", with: "")
        .replacingOccurrences(of: " ", with: "")
    
    // Check if there's a timezone indicator (Z or +/- offset) at the end
    // A timezone offset is +/-HH:MM at the very end of the string
    let hasTimezone: Bool
    if normalized.hasSuffix("Z") {
        hasTimezone = true
    } else {
        // Check for +/-HH:MM pattern at the end
        let tzPattern = "[+-]\\d{2}:?\\d{2}$"
        if let regex = try? NSRegularExpression(pattern: tzPattern, options: []),
           regex.firstMatch(in: normalized, options: [], range: NSRange(normalized.startIndex..., in: normalized)) != nil {
            hasTimezone = true
        } else {
            hasTimezone = false
        }
    }
    
    if isDateTime {
        // For datetime: Check if seconds are present
        if hasTimezone {
            // Has timezone, check if seconds exist before it
            var timeEndIndex = normalized.endIndex
            if normalized.hasSuffix("Z") {
                timeEndIndex = normalized.index(before: timeEndIndex)
            } else if let match = try? NSRegularExpression(pattern: "[+-]\\d{2}:?\\d{2}$", options: [])
                        .firstMatch(in: normalized, options: [], range: NSRange(normalized.startIndex..., in: normalized)) {
                timeEndIndex = normalized.index(normalized.startIndex, offsetBy: match.range.location)
            }
            
            let timePart = String(normalized[..<timeEndIndex])
            if let tIndex = timePart.firstIndex(where: { $0 == "T" }) {
                let afterT = String(timePart[timePart.index(after: tIndex)...])
                let colonCount = afterT.filter { $0 == ":" }.count
                if colonCount == 1 {
                    // Missing seconds, add :00 before timezone
                    let beforeTimezone = String(normalized[..<timeEndIndex])
                    let timezone = String(normalized[timeEndIndex...])
                    normalized = beforeTimezone + ":00" + timezone
                }
            }
        } else {
            // No timezone, check if we need to add seconds
            if let tIndex = normalized.firstIndex(where: { $0 == "T" }) {
                let afterT = String(normalized[normalized.index(after: tIndex)...])
                let colonCount = afterT.filter { $0 == ":" }.count
                if colonCount == 1 {
                    // Missing seconds, add :00
                    normalized = normalized + ":00"
                }
            }
        }
    } else {
        // For time-only values: HH:MM or HH:MM:SS with optional timezone
        let colonCount = normalized.filter { $0 == ":" }.count
        if colonCount == 1 {
            // Missing seconds (only HH:MM), add :00
            normalized = normalized + ":00"
        }
    }
    
    return normalized
}

// MARK: - Date Parsing

/// Check if string has a timezone indicator
private func hasTimezoneIndicator(_ value: String) -> Bool {
    if value.hasSuffix("Z") {
        return true
    }
    // Check for +/-HH:MM pattern at the end
    let tzPattern = "[+-]\\d{2}:?\\d{2}$"
    if let regex = try? NSRegularExpression(pattern: tzPattern, options: []),
       regex.firstMatch(in: value, options: [], range: NSRange(value.startIndex..., in: value)) != nil {
        return true
    }
    return false
}

/// Parses a datetime string, using appropriate formatter based on whether it has timezone
private func parseDateTime(_ value: String) -> Date? {
    let normalized = normalizeDateTimeString(value, isDateTime: true)
    let hasTimezone = hasTimezoneIndicator(normalized)
    
    if hasTimezone {
        // Use ISO8601DateFormatter for timezone dates
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withFullTime, .withTimeZone]
        return formatter.date(from: normalized)
    } else {
        // Use DateFormatter for local dates (without timezone)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.date(from: normalized)
    }
}

/// Parses a time-only string
private func parseTime(_ value: String) -> Date? {
    let normalized = normalizeDateTimeString(value, isDateTime: false)
    let hasTimezone = hasTimezoneIndicator(normalized)
    
    let timeStr = "1900-01-01T" + normalized
    
    if hasTimezone {
        // Use ISO8601DateFormatter for timezone times
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withFullTime, .withTimeZone]
        return formatter.date(from: timeStr)
    } else {
        // Use DateFormatter for local times (without timezone)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.date(from: timeStr)
    }
}

// MARK: - Convert Value

// Convert value with error collection (for parsing)
public func convertValue(_ value: String, start: Int, errors: inout [ParseError]) -> Any? {
    // HACK: Can't figure out how to wrangle Swift nils
    if value == "null" {
        return "null"
    } else if value == "true" {
        return true
    } else if value == "false" {
        return false
    } else if isStringValue(value) {
        return String(value.dropFirst().dropLast())
    } else if isRegexValue(value) {
        return value
    } else if isIntValue(value) || isHexValue(value) {
        let cleaned = value.replacingOccurrences(of: "_", with: "")
        if isHexValue(value) {
            let hexString = String(cleaned.dropFirst(2))
            return Int(hexString, radix: 16)
        }
        return Int(cleaned)
    } else if isFloatValue(value) || isScientificValue(value) {
        let cleaned = value.replacingOccurrences(of: "_", with: "")
        return Double(cleaned)
    } else if isDateValue(value) {
        // Plain date without time component
        let dateStr = value + "T00:00:00"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        guard let date = formatter.date(from: dateStr) else {
            errors.append(ParseError(
                message: "Invalid date '\(value)'",
                index: start,
                length: value.count
            ))
            return nil
        }
        return date
    } else if isDateTimeValue(value) {
        // DateTime with time component
        guard let date = parseDateTime(value) else {
            errors.append(ParseError(
                message: "Invalid date '\(value)'",
                index: start,
                length: value.count
            ))
            return nil
        }
        return date
    } else if isTimeValue(value) {
        // Time-only value
        guard let date = parseTime(value) else {
            errors.append(ParseError(
                message: "Invalid time '\(value)'",
                index: start,
                length: value.count
            ))
            return nil
        }
        return date
    } else {
        errors.append(ParseError(
            message: "Unsupported value type '\(value)'",
            index: start,
            length: value.count
        ))
        return nil
    }
}

// MARK: - Type Checkers

public func isStringValue(_ value: String) -> Bool {
    return value.hasPrefix("\"") && value.hasSuffix("\"")
}

public func isRegexValue(_ value: String) -> Bool {
    return value.hasPrefix("/")
}

public func isIntValue(_ value: String) -> Bool {
    let pattern = "^[+-]?\\d+(?:_\\d+)*$"
    return matchesPattern(value, pattern: pattern)
}

public func isHexValue(_ value: String) -> Bool {
    let pattern = "^0[xX][0-9a-fA-F]+(?:_[0-9a-fA-F]+)*$"
    return matchesPattern(value, pattern: pattern)
}

public func isFloatValue(_ value: String) -> Bool {
    let pattern = "^[+-]?\\d+(?:_\\d+)*\\.\\d+(?:_\\d+)*$"
    return matchesPattern(value, pattern: pattern)
}

public func isScientificValue(_ value: String) -> Bool {
    let pattern = "^[+-]?\\d+(?:\\.\\d+)?[eE]-?\\d+$"
    return matchesPattern(value, pattern: pattern)
}

public func isDateValue(_ value: String) -> Bool {
    let pattern = "^\\d{4}-\\d{2}-\\d{2}$"
    return matchesPattern(value, pattern: pattern)
}

public func isDateTimeValue(_ value: String) -> Bool {
    let pattern = "^\\d{4}-\\d{2}-\\d{2}(?:T| )\\d{2}:\\d{2}(?::\\d{2})?(?: ?(?:U|L|[+-]\\d{2}:\\d{2}))?$"
    return matchesPattern(value, pattern: pattern)
}

public func isTimeValue(_ value: String) -> Bool {
    let pattern = "^\\d{2}:\\d{2}(?::\\d{2})?(?: ?(?:U|L|[+-]\\d{2}:\\d{2}))?$"
    return matchesPattern(value, pattern: pattern)
}

public func matchesPattern(_ string: String, pattern: String) -> Bool {
    do {
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(string.startIndex..., in: string)
        return regex.firstMatch(in: string, options: [], range: range) != nil
    } catch {
        return false
    }
}
