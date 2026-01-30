import Foundation

public struct AnySchema: SchemaValue {
    public let type: String
    public var description: String?
    public var validators: [String: ValidatorInfo]?
    public let inner: SchemaValue
    
    public init(pattern: String, inner: SchemaValue, description: String? = nil, validators: [String: ValidatorInfo]? = nil) {
        self.type = pattern
        self.inner = inner
        self.description = description
        self.validators = validators
    }
}
