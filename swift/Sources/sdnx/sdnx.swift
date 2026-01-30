import Foundation
import Collections

// SDN (Structured Data Notation) Parser
// Multi-language implementation supporting TypeScript, Zig, and Swift

// MARK: - Main Entry Points

/// Parse SDN data from a string
/// - Parameter input: The SDN data string to parse
/// - Returns: A dictionary representing the parsed data
/// - Throws: ParseError if the input is invalid
public func parseSDN(_ input: String) throws -> OrderedDictionary<String, Any> {
    return try parse(input)
}

/// Parse SDN schema from a string
/// - Parameter input: The SDN schema string to parse
/// - Returns: A schema definition
/// - Throws: ParseSchemaError if the input is invalid
public func parseSDNSchema(_ input: String) throws -> OrderedDictionary<String, SchemaValue> {
    return try parseSchema(input)
}

/// Check SDN data against a schema
/// - Parameter input: The SDN schema string to parse
/// - Returns: A check result
public func checkSDN(_ input: OrderedDictionary<String, Any>, schema: Schema) -> CheckResult {
    return check(input, schema: schema)
}
