import Foundation

public struct DefSchema: SchemaValue {
    public let type: String = "def"
    public var description: String?
    public var validators: [String: ValidatorInfo]?
    public let name: String
    public let inner: Schema
    
    public init(name: String, inner: Schema) {
        self.name = name
        self.inner = inner
    }
}
