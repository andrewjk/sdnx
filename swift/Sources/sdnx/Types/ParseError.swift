import Foundation

public struct ParseError {
    public let message: String
    public let index: Int
    public let length: Int
    
    public init(message: String, index: Int, length: Int) {
        self.message = message
        self.index = index
        self.length = length
    }
}
