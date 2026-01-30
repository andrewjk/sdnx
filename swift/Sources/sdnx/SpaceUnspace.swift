import Foundation

/// Adds spaces around structural characters ({}[]:,)
/// Preserves content inside strings and comments
public func space(_ value: String) -> String {
    let spacedChars = "{}[]():,"
    var result = ""
    var i = value.startIndex
    
    while i < value.endIndex {
        let char = value[i]
        
        if char == "\"" {
            // Handle string literals - preserve content
            result.append(" \"")
            i = value.index(after: i)
            while i < value.endIndex {
                let currentChar = value[i]
                result.append(currentChar)
                if currentChar == "\"" {
                    // Check if it's an escaped quote
                    let prevIndex = value.index(i, offsetBy: -1, limitedBy: value.startIndex)
                    if prevIndex == nil || value[prevIndex!] != "\\" {
                        break
                    }
                }
                i = value.index(after: i)
            }
        } else if char == "#" {
            // Handle comments - preserve content
            result.append(" #")
            i = value.index(after: i)
            while i < value.endIndex && value[i] != "\n" {
                result.append(value[i])
                i = value.index(after: i)
            }
            if i < value.endIndex {
                result.append(value[i]) // Add the newline
            }
        } else if spacedChars.contains(char) {
            // Add spaces around structural characters
            result.append(" ")
            result.append(char)
            result.append(" ")
        } else {
            result.append(char)
        }
        
        if i < value.endIndex {
            i = value.index(after: i)
        }
    }
    
    return result
}

/// Removes unnecessary whitespace while preserving content inside strings and comments
public func unspace(_ value: String) -> String {
    var result = ""
    var i = value.startIndex
    
    while i < value.endIndex {
        let char = value[i]
        
        if char == "\"" {
            // Handle string literals - preserve content
            result.append(char)
            i = value.index(after: i)
            while i < value.endIndex {
                let currentChar = value[i]
                result.append(currentChar)
                if currentChar == "\"" {
                    // Check if it's an escaped quote
                    let prevIndex = value.index(i, offsetBy: -1, limitedBy: value.startIndex)
                    if prevIndex == nil || value[prevIndex!] != "\\" {
                        break
                    }
                }
                i = value.index(after: i)
            }
        } else if char == "#" {
            // Handle comments - preserve content with space before #
            result.append(" #")
            i = value.index(after: i)
            while i < value.endIndex && value[i] != "\n" {
                result.append(value[i])
                i = value.index(after: i)
            }
            if i < value.endIndex {
                result.append(value[i]) // Add the newline
            }
        } else if char != " " && char != "\t" && char != "\n" {
            // Keep non-whitespace characters
            result.append(char)
        }
        
        if i < value.endIndex {
            i = value.index(after: i)
        }
    }
    
    return result
}
