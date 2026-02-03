import Foundation
import Collections

// SDN (Structured Data Notation) Parser
// Multi-language implementation supporting TypeScript, Zig, and Swift

// MARK: - Main Entry Points

/// Parse SDN data from a string
/// - Parameter input: The SDN data string to parse
/// - Returns: A parse result containing success or failure
public func parseSDN(_ input: String) -> ParseResult {
    return parse(input)
}

/// Parse SDN schema from a string
/// - Parameter input: The SDN schema string to parse
/// - Returns: A parse schema result containing success or failure
public func parseSDNSchema(_ input: String) -> ParseSchemaResult {
    return parseSchema(input)
}

/// Check SDN data against a schema
/// - Parameter input: The SDN schema string to parse
/// - Returns: A check result
public func checkSDN(_ input: OrderedDictionary<String, Any>, schema: Schema) -> CheckResult {
    return check(input, schema: schema)
}

/// Convert SDN data to string representation
/// - Parameters:
///   - obj: The SDN data to stringify
///   - ansi: Whether to use ANSI color codes (default: false)
/// - Returns: A string representation of the SDN data
public func stringifySDN(_ obj: OrderedDictionary<String, Any>, options: StringifyOptions?) -> String {
    return stringify(obj, options: options)
}
