import Foundation
import Collections
import sdnx

// ANSI color codes for terminal output
enum ANSIColor {
    static let reset = "\u{001B}[0m"
    static let red = "\u{001B}[31m"
    static let yellow = "\u{001B}[33m"
    static let bold = "\u{001B}[1m"
}

// Main entry point
@main
struct SDNCLI {
    static func main() {
        let arguments = CommandLine.arguments
        
        guard arguments.count >= 2 else {
            print("Usage: sdnx <file> [schema]")
            exit(1)
        }
        
        let file = arguments[1]
        let schema = arguments.count > 2 ? arguments[2] : nil
        
        do {
            let result: ReadResult
            if let schemaPath = schema {
                result = try read(file, schema: schemaPath)
            } else {
                result = try read(file)
            }
            
            switch result {
            case .success(let success):
                print("\nFile read with no errors.\n")
                printData(success.data)
                exit(0)
                
            case .failure(let failure):
                printReadErrors(failure.schemaErrors, label: "error", labelPlural: "errors", source: "schema file")
                printReadErrors(failure.dataErrors, label: "error", labelPlural: "errors", source: "data file")
                printCheckErrors(failure.checkErrors)
                exit(1)
            }
        } catch {
            if let readError = error as? ReadError {
                print("\(ANSIColor.red)Error:\(ANSIColor.reset) \(readError.message)")
            } else {
                print("\(ANSIColor.red)Error:\(ANSIColor.reset) \(error)")
            }
            exit(1)
        }
    }
    
    private static func printData(_ data: OrderedDictionary<String, Any>) {
        let stringified = stringify(data, options: StringifyOptions(ansi: true, indent: "    "))
        print(stringified)
    }
    
    private static func convertToNSDictionary(_ data: OrderedDictionary<String, Any>) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in data {
            if let dict = value as? OrderedDictionary<String, Any> {
                result[key] = convertToNSDictionary(dict)
            } else if let array = value as? [Any] {
                var convertedArray: [Any] = []
                for item in array {
                    if let dict = item as? OrderedDictionary<String, Any> {
                        convertedArray.append(convertToNSDictionary(dict))
                    } else {
                        convertedArray.append(item)
                    }
                }
                result[key] = convertedArray
            } else {
                result[key] = value
            }
        }
        return result
    }
    
    private static func printReadErrors(_ errors: [ReadError], label: String, labelPlural: String, source: String) {
        guard !errors.isEmpty else { return }
        
        let count = errors.count
        let errorWord = count == 1 ? label : labelPlural
        print("\n\(ANSIColor.bold)\(ANSIColor.red)\(count) \(errorWord) in \(source):\(ANSIColor.reset)\n")
        
        for error in errors {
            print("\(ANSIColor.yellow)\(error.index)\(ANSIColor.reset): \(error.message)")
            // Replace tabs with spaces for consistent display
            let line = error.line.replacingOccurrences(of: "\t", with: " ")
            print(line)
            
            // Print caret under the error location
            let spaces = String(repeating: " ", count: error.char)
            let tildes = String(repeating: "~", count: error.length)
            print("\(spaces)\(ANSIColor.red)\(tildes)\(ANSIColor.reset)")
            print("")
        }
    }
    
    private static func printCheckErrors(_ errors: [CheckError]) {
        guard !errors.isEmpty else { return }
        
        let count = errors.count
        let errorWord = count == 1 ? "error" : "errors"
        print("\n\(ANSIColor.bold)\(ANSIColor.red)\(count) \(errorWord) in data:\(ANSIColor.reset)\n")
        
        for error in errors {
            let path = error.path.joined(separator: ".")
            print("\(ANSIColor.yellow)\(path)\(ANSIColor.reset): \(error.message)")
        }
    }
}
