import Foundation

public struct ArraySchema: SchemaValue {
    public let type: String = "array"
    public var description: String?
    public var validators: [String: ValidatorInfo]?
    public let inner: SchemaValue
    
    public init(inner: SchemaValue, description: String? = nil, validators: [String: ValidatorInfo]? = nil) {
        self.inner = inner
        self.description = description
        self.validators = validators
    }
}
