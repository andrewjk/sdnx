import Foundation

public struct CheckStatus {
    public var path: [String]
    public var errors: [CheckError]

    public init(path: [String], errors: [CheckError]) {
        self.path = path
        self.errors = errors
    }
}
