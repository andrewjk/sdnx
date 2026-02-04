import Foundation

public struct RefSchema: SchemaValue {
    public let type: String = "ref"
    public var description: String?
    public var validators: [String: ValidatorInfo]?
    public let inner: String

    public init(inner: String) {
        self.inner = inner
    }
}
