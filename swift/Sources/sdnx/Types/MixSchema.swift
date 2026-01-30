import Foundation

public struct MixSchema: SchemaValue {
    public let type: String = "mix"
    public var description: String?
    public var validators: [String: ValidatorInfo]?
    public var inner: [Schema]
    
    public init(inner: [Schema], description: String? = nil, validators: [String: ValidatorInfo]? = nil) {
        self.inner = inner
        self.description = description
        self.validators = validators
    }
}
