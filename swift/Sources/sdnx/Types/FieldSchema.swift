import Foundation

public struct FieldSchema: SchemaValue {
    public let type: String
    public var description: String?
    public var validators: [String: ValidatorInfo]?
    
    public init(type: String, description: String? = nil, validators: [String: ValidatorInfo]? = nil) {
        self.type = type
        self.description = description
        self.validators = validators
    }
}
