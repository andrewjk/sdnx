import Foundation

public struct ObjectSchema: SchemaValue {
    public let type: String = "object"
    public var description: String?
    public var validators: [String: ValidatorInfo]?
    public let inner: Schema
    
    public init(inner: Schema, description: String? = nil, validators: [String: ValidatorInfo]? = nil) {
        self.inner = inner
        self.description = description
        self.validators = validators
    }
}
