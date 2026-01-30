import Foundation
import Collections

// MARK: - Check Result Types

public enum CheckResult {
    case success(CheckSuccess)
    case failure(CheckFailure)
}

// MARK: - Main Check Function

public func check(_ input: OrderedDictionary<String, Any>, schema: Schema) -> CheckResult {
    var errors: [CheckError] = []
    
    _ = checkObjectSchemaInner(input, schema: schema, errors: &errors)
    
    if errors.isEmpty {
        return .success(CheckSuccess())
    } else {
        return .failure(CheckFailure(errors: errors))
    }
}

// MARK: - Check Functions

func checkObjectSchema(_ input: OrderedDictionary<String, Any>, schema: ObjectSchema, errors: inout [CheckError]) -> Bool {
    return checkObjectSchemaInner(input, schema: schema.inner, errors: &errors)
}

func checkObjectSchemaInner(_ input: OrderedDictionary<String, Any>, schema: Schema, errors: inout [CheckError]) -> Bool {
    var result = true
    for (field, fieldSchema) in schema {
        if field.hasPrefix("mix$") {
            if let mixSchema = fieldSchema as? MixSchema {
                if !checkMixSchema(input, schema: mixSchema, errors: &errors) {
                    result = false
                }
            }
        } else if field.hasPrefix("any$") {
            if let anySchema = fieldSchema as? AnySchema {
                if !checkAnySchema(input, schema: anySchema, field: field, errors: &errors) {
                    result = false
                }
            }
        } else {
            let value = input[field]
            if !checkFieldSchema(value, schema: fieldSchema, field: field, errors: &errors) {
                result = false
            }
        }
    }
    return result
}

func checkArraySchema(_ input: [Any], schema: ArraySchema, errors: inout [CheckError]) -> Bool {
    var result = true
    for (i, value) in input.enumerated() {
        if !checkFieldSchema(value, schema: schema.inner, field: String(i), errors: &errors) {
            result = false
        }
    }
    return result
}

func checkUnionSchema(_ value: Any?, schema: UnionSchema, field: String, errors: inout [CheckError]) -> Bool {
    var fieldErrors: [CheckError] = []
    var ok = false
    for fs in schema.inner {
        if checkFieldSchema(value, schema: fs, field: field, errors: &fieldErrors) {
            ok = true
            break
        }
    }
    if !ok {
        errors.append(CheckError(
            path: [],
            message: fieldErrors.map { $0.message }.joined(separator: " | ")
        ))
    }
    return ok
}

func checkMixSchema(_ input: OrderedDictionary<String, Any>, schema: MixSchema, errors: inout [CheckError]) -> Bool {
    var fieldErrors: [CheckError] = []
    var ok = false
    for fs in schema.inner {
        let mixResult = check(input, schema: fs)
        switch mixResult {
        case .success:
            ok = true
            break
        case .failure(let failure):
            fieldErrors.append(CheckError(
                path: [],
                message: failure.errors.map { $0.message }.joined(separator: " & ")
            ))
        }
    }
    if !ok {
        errors.append(CheckError(
            path: [],
            message: fieldErrors.map { $0.message }.joined(separator: " | ")
        ))
    }
    return ok
}

func checkAnySchema(_ input: OrderedDictionary<String, Any>, schema: AnySchema, field: String, errors: inout [CheckError]) -> Bool {
    var result = true
    for (anyField, value) in input {
        // PERF: could cache this
        if let regexp = createRegex(schema.type) {
            if !regexp.test(anyField) {
                errors.append(CheckError(
                    path: [],
                    message: "'\(anyField)' name doesn't match pattern '\(schema.type)'"
                ))
                return false
            }
        }
        
        // Run the field's validators
        if !checkFieldSchema(value, schema: schema.inner, field: anyField, errors: &errors) {
            result = false
        }
    }
    return result
}

func checkFieldSchema(_ value: Any?, schema: SchemaValue, field: String, errors: inout [CheckError]) -> Bool {
    switch schema.type {
    case "object":
        if let objSchema = schema as? ObjectSchema {
            guard let dictValue = value as? OrderedDictionary<String, Any> else {
                errors.append(CheckError(
                    path: [],
                    message: "'\(field)' must be an object"
                ))
                return false
            }
            return checkObjectSchema(dictValue, schema: objSchema, errors: &errors)
        }
        return false
        
    case "array":
        if let arrSchema = schema as? ArraySchema {
            guard let arrayValue = value as? [Any] else {
                errors.append(CheckError(
                    path: [],
                    message: "'\(field)' must be an array"
                ))
                return false
            }
            return checkArraySchema(arrayValue, schema: arrSchema, errors: &errors)
        }
        return false
        
    case "union":
        if let unionSchema = schema as? UnionSchema {
            return checkUnionSchema(value, schema: unionSchema, field: field, errors: &errors)
        }
        return false
        
    default:
        return checkFieldSchemaValue(value, schema: schema, field: field, errors: &errors)
    }
}

func checkFieldSchemaValue(_ value: Any?, schema: SchemaValue, field: String, errors: inout [CheckError]) -> Bool {
    // Check if value is undefined (nil in Swift)
    // Allow "undef" and "null" types to have nil values
    if value == nil && schema.type != "undef" && schema.type != "null" {
        errors.append(CheckError(
            path: [],
            message: "Field not found: \(field)"
        ))
        return false
    }
    
    // Check the value's type
    switch schema.type {
    case "undef":
        if value != nil {
            errors.append(CheckError(
                path: [],
                message: "'\(field)' must be undefined"
            ))
            return false
        }
        
    case "null":
        if value != nil {
            // HACK: Can't figure out how to wrangle Swift nils
            guard value is String, value as? String == "null" else { 
                errors.append(CheckError(
                    path: [],
                    message: "'\(field)' must be null"
                ))
                return false
            }
        }
        
    case "bool":
        guard value is Bool else {
            errors.append(CheckError(
                path: [],
                message: "'\(field)' must be a boolean value"
            ))
            return false
        }
        
    case "int":
        guard let numValue = value as? NSNumber, numValue.isInt else {
            errors.append(CheckError(
                path: [],
                message: "'\(field)' must be an integer value"
            ))
            return false
        }
        
    case "num":
        guard let _ = value as? NSNumber else {
            errors.append(CheckError(
                path: [],
                message: "'\(field)' must be a number value"
            ))
            return false
        }
        
    case "date":
        guard value is Date else {
            errors.append(CheckError(
                path: [],
                message: "'\(field)' must be a date value"
            ))
            return false
        }
        
    case "string":
        guard let _ = value as? String else {
            errors.append(CheckError(
                path: [],
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
            errors.append(CheckError(
                path: [],
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
                if !validate(field, value ?? NSNull(), validator.raw, validator.required ?? NSNull(), &errors) {
                    return false
                }
            } else {
                // This should never happen...
                errors.append(CheckError(
                    path: [],
                    message: "Unsupported validation method for '\(field)': \(method)"
                ))
                return false
            }
        }
    }
    
    return true
}
