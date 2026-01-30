import Foundation

public struct ValidatorInfo {
    public let raw: String
    public let required: Any?
    
    public init(raw: String, required: Any? = nil) {
        self.raw = raw
        self.required = required
    }
}
