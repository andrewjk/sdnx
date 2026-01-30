import Foundation

public struct CheckError {
    public let path: [String]
    public let message: String
    
    public init(path: [String], message: String) {
        self.path = path
        self.message = message
    }
}
