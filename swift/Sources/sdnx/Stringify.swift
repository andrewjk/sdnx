import Foundation
import Collections

// MARK: - Status Type

private struct Status {
    var indent: Int
    var result: String
    var ansi: Bool
    var indentText: String
}

public struct StringifyOptions {
    var ansi: Bool?
    var indent: String?

    public init(ansi: Bool?, indent: String?) {
        self.ansi = ansi
        self.indent = indent
    }
}

// MARK: - Main Stringify Function

/// Converts an object into a string containing Structured Data Notation.
public func stringify(_ obj: OrderedDictionary<String, Any>, options: StringifyOptions? = nil) -> String {
    var status = Status(indent: 0, result: "", ansi: options?.ansi ?? false, indentText: options?.indent ?? "\t")
    printValue(obj, &status)
    return status.result
}

// MARK: - Private Helper Functions

private func printValue(_ obj: Any, _ status: inout Status) {
    if let array = obj as? [Any] {
        printArray(array, &status)
    } else if let date = obj as? Date {
        let dateStr = formatDate(date)
        if status.ansi {
            status.result += "\u{001B}[35m\(dateStr)\u{001B}[0m"
        } else {
            status.result += dateStr
        }
    } else if let dict = obj as? OrderedDictionary<String, Any> {
        printDictionary(dict, &status)
    } else if let dict = obj as? [String: Any] {
        printDictionary(OrderedDictionary(uniqueKeysWithValues: dict.map { ($0.key, $0.value) }), &status)
    } else if let str = obj as? String {
        if status.ansi {
            status.result += "\u{001B}[32m\"\(str)\"\u{001B}[0m"
        } else {
            status.result += "\"\(str)\""
        }
    } else if let bool = obj as? Bool {
        if status.ansi {
            status.result += "\u{001B}[34m\(bool)\u{001B}[0m"
        } else {
            status.result += "\(bool)"
        }
    } else if let num = obj as? NSNumber {
        // Handle both integers and floats
        if status.ansi {
            status.result += "\u{001B}[33m\(num)\u{001B}[0m"
        } else {
            status.result += "\(num)"
        }
    } else if obj is NSNull || obj is Void {
        status.result += "null"
    } else {
        status.result += "\(obj)"
    }
}

private func printArray(_ array: [Any], _ status: inout Status) {
    status.result += "["
    status.indent += 1

    for i in array.indices {
        status.result += "\n"
        indent(&status)
        printValue(array[i], &status)
        if i < array.count - 1 {
            status.result += ","
        }
    }

    status.indent -= 1
    status.result += "\n"
    indent(&status)
    status.result += "]"
}

private func printDictionary(_ dict: OrderedDictionary<String, Any>, _ status: inout Status) {
    status.result += "{"
    status.indent += 1

    let keys = Array(dict.keys)
    for i in keys.indices {
        status.result += "\n"
        let key = keys[i]
        indent(&status)
        status.result += "\(key): "
        if let value = dict[key] {
            printValue(value, &status)
        }
        if i < keys.count - 1 {
            status.result += ","
        }
    }

    status.indent -= 1
    status.result += "\n"
    indent(&status)
    status.result += "}"
}

private func indent(_ status: inout Status) {
    status.result += String(repeating: status.indentText, count: status.indent)
}

private func formatDate(_ date: Date) -> String {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)

    let year = components.year ?? 0
    let month = String(format: "%02d", components.month ?? 0)
    let day = String(format: "%02d", components.day ?? 0)
    let hours = String(format: "%02d", components.hour ?? 0)
    let minutes = String(format: "%02d", components.minute ?? 0)
    let seconds = String(format: "%02d", components.second ?? 0)

    if hours == "00" && minutes == "00" && seconds == "00" {
        return "\(year)-\(month)-\(day)"
    } else {
        return "\(year)-\(month)-\(day)T\(hours):\(minutes)"
    }
}
