import Foundation
import Collections

// MARK: - Check Result Types

public struct CheckSuccess {
    public let ok = true
}

public struct CheckFailure {
    public let ok = false
    public let errors: [CheckError]
}

public enum CheckResult {
    case success(CheckSuccess)
    case failure(CheckFailure)
}

// MARK: - Main Check Function

public func check(_ input: OrderedDictionary<String, Any>, schema: Schema) -> CheckResult {
    var status = CheckStatus(path: [], errors: [], defs: [:])
    
    _ = checkObjectSchemaInner(input, schema: schema, status: &status)
    
    if status.errors.isEmpty {
        return .success(CheckSuccess())
    } else {
        return .failure(CheckFailure(errors: status.errors))
    }
}

// MARK: - Check Functions

func checkObjectSchema(_ input: OrderedDictionary<String, Any>, schema: ObjectSchema, status: inout CheckStatus) -> Bool {
    return checkObjectSchemaInner(input, schema: schema.inner, status: &status)
}

func checkObjectSchemaInner(_ input: OrderedDictionary<String, Any>, schema: Schema, status: inout CheckStatus) -> Bool {
    var result = true
    for (field, fieldSchema) in schema {
        status.path.append(field)
        if field.hasPrefix("def$") {
            if let defSchema = fieldSchema as? DefSchema {
                status.defs[defSchema.name] = defSchema.inner
            }
        } else if field.hasPrefix("ref$") {
            if let refSchema = fieldSchema as? RefSchema {
                if !checkRefSchema(input, ref: refSchema.inner, status: &status) {
                    result = false
                }
            }
        } else if field.hasPrefix("mix$") {
            if let mixSchema = fieldSchema as? MixSchema {
                if !checkMixSchema(input, schema: mixSchema, status: &status) {
                    result = false
                }
            }
        } else if field.hasPrefix("props$") {
            if let propsSchema = fieldSchema as? PropsSchema {
                if !checkPropsSchema(input, schema: propsSchema, field: field, status: &status) {
                    result = false
                }
            }
        } else {
            let value = input[field]
            if !checkFieldSchema(value, schema: fieldSchema, field: field, status: &status) {
                result = false
            }
        }
        status.path.removeLast()
    }
    return result
}

func checkArraySchema(_ input: [Any], schema: ArraySchema, status: inout CheckStatus) -> Bool {
    var result = true
    for (i, value) in input.enumerated() {
        status.path.append(String(i))
        if !checkFieldSchema(value, schema: schema.inner, field: String(i), status: &status) {
            result = false
        }
        let _ = status.path.popLast()
    }
    return result
}

func checkUnionSchema(_ value: Any?, schema: UnionSchema, field: String, status: inout CheckStatus) -> Bool {
    var fieldStatus = CheckStatus(path: status.path, errors: [], defs: status.defs)
    var ok = false
    for fs in schema.inner {
        if checkFieldSchema(value, schema: fs, field: field, status: &fieldStatus) {
            ok = true
            break
        }
    }
    if !ok {
        status.errors.append(CheckError(
            path: status.path,
            message: fieldStatus.errors.map { $0.message }.joined(separator: " | ")
        ))
    }
    return ok
}

func checkRefSchema(_ input: OrderedDictionary<String, Any>, ref: String, status: inout CheckStatus) -> Bool {
    guard let def = status.defs[ref] else {
        status.errors.append(CheckError(
            path: status.path,
            message: "Undefined def: \(ref)"
        ))
        return false
    }
    
    return checkObjectSchemaInner(input, schema: def, status: &status)
}

func checkMixSchema(_ input: OrderedDictionary<String, Any>, schema: MixSchema, status: inout CheckStatus) -> Bool {
    var fieldErrors: [CheckError] = []
    var ok = false
    for fs in schema.inner {
        var fieldStatus = CheckStatus(path: status.path, errors: [], defs: status.defs)
        if checkObjectSchemaInner(input, schema: fs, status: &fieldStatus) {
            ok = true
            break
        } else {
            fieldErrors.append(CheckError(
                path: status.path,
                message: fieldStatus.errors.map { $0.message }.joined(separator: " & ")
            ))
        }
    }
    if !ok {
        status.errors.append(CheckError(
            path: status.path,
            message: fieldErrors.map { $0.message }.joined(separator: " | ")
        ))
    }
    return ok
}

func checkPropsSchema(_ input: OrderedDictionary<String, Any>, schema: PropsSchema, field: String, status: inout CheckStatus) -> Bool {
    var result = true
    for (anyField, value) in input {
        // PERF: could cache this
        if let regexp = createRegex(schema.type) {
            if !regexp.test(anyField) {
                status.errors.append(CheckError(
                    path: status.path,
                    message: "'\(anyField)' name doesn't match pattern '\(schema.type)'"
                ))
                return false
            }
        }
        
        // Run the field's validators
        if !checkFieldSchema(value, schema: schema.inner, field: anyField, status: &status) {
            result = false
        }
    }
    return result
}

func checkFieldSchema(_ value: Any?, schema: SchemaValue, field: String, status: inout CheckStatus) -> Bool {
    switch schema.type {
    case "object":
        if let objSchema = schema as? ObjectSchema {
            guard let dictValue = value as? OrderedDictionary<String, Any> else {
                status.errors.append(CheckError(
                    path: status.path,
                    message: "'\(field)' must be an object"
                ))
                return false
            }
            return checkObjectSchema(dictValue, schema: objSchema, status: &status)
        }
        return false
        
    case "array":
        if let arrSchema = schema as? ArraySchema {
            guard let arrayValue = value as? [Any] else {
                status.errors.append(CheckError(
                    path: status.path,
                    message: "'\(field)' must be an array"
                ))
                return false
            }
            return checkArraySchema(arrayValue, schema: arrSchema, status: &status)
        }
        return false
        
    case "union":
        if let unionSchema = schema as? UnionSchema {
            return checkUnionSchema(value, schema: unionSchema, field: field, status: &status)
        }
        return false
        
    default:
        return checkFieldSchemaValue(value, schema: schema, field: field, status: &status)
    }
}

func checkFieldSchemaValue(_ value: Any?, schema: SchemaValue, field: String, status: inout CheckStatus) -> Bool {
    // Check if value is undefined (nil in Swift)
    // Allow "undef" and "null" types to have nil values
    if value == nil && schema.type != "undef" && schema.type != "null" {
        status.errors.append(CheckError(
            path: status.path,
            message: "Field not found: \(field)"
        ))
        return false
    }
    
    // Check the value's type
    switch schema.type {
    case "undef":
        if value != nil {
            status.errors.append(CheckError(
                path: status.path,
                message: "'\(field)' must be undefined"
            ))
            return false
        }
        
    case "null":
        if value != nil {
            // HACK: Can't figure out how to wrangle Swift nils
            guard value is String, value as? String == "null" else { 
                status.errors.append(CheckError(
                    path: status.path,
                    message: "'\(field)' must be null"
                ))
                return false
            }
        }
        
    case "bool":
        guard value is Bool else {
            status.errors.append(CheckError(
                path: status.path,
                message: "'\(field)' must be a boolean value"
            ))
            return false
        }
        
    case "int":
        guard let numValue = value as? NSNumber, numValue.isInt else {
            status.errors.append(CheckError(
                path: status.path,
                message: "'\(field)' must be an integer value"
            ))
            return false
        }
        
    case "num":
        guard let _ = value as? NSNumber else {
            status.errors.append(CheckError(
                path: status.path,
                message: "'\(field)' must be a number value"
            ))
            return false
        }
        
    case "date":
        guard value is Date else {
            status.errors.append(CheckError(
                path: status.path,
                message: "'\(field)' must be a date value"
            ))
            return false
        }
        
    case "string":
        guard let _ = value as? String else {
            status.errors.append(CheckError(
                path: status.path,
                message: "'\(field)' must be a string value"
            ))
            return false
        }
        
    default:
        // It may be a fixed value e.g. `true`, `false`, `null`, or a string
        var expectedType = schema.type
        if expectedType.hasPrefix("\"") && expectedType.hasSuffix("\"") {
            expectedType = String(expectedType.dropFirst().dropLast())
        }
        
        // Handle special cases for fixed values
        var matches = false
        if expectedType == "true" {
            matches = value as? Bool == true
        } else if expectedType == "false" {
            matches = value as? Bool == false
        } else if expectedType == "null" {
            matches = value == nil
        } else {
            // For string values, compare the string representation
            matches = value as? String == expectedType
        }
        
        if !matches {
            status.errors.append(CheckError(
                path: status.path,
                message: "'\(field)' must be '\(expectedType)'"
            ))
            return false
        }
        
        // There can't be any more validators after a fixed value
        return true
    }
    
    // Run the validators
    if let validatorDict = schema.validators {
        for (method, validator) in validatorDict {
            if method == "type" || method == "description" {
                continue
            }
            
            if let validate = getValidators()[schema.type]?[method] {
                if !validate(field, value ?? NSNull(), validator.raw, validator.required ?? NSNull(), &status) {
                    return false
                }
            } else {
                // This should never happen...
                status.errors.append(CheckError(
                    path: status.path,
                    message: "Unsupported validation method for '\(field)': \(method)"
                ))
                return false
            }
        }
    }
    
    return true
}
