import Foundation

public struct CheckStatus {
    public var path: [String]
    public var errors: [CheckError]
    public var defs: [String: Schema]

    public init(path: [String], errors: [CheckError], defs: [String: Schema] = [:]) {
        self.path = path
        self.errors = errors
        self.defs = defs
    }
}
