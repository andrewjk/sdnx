import Foundation

public struct ReadError: Error {
    public let message: String
    public let index: Int
    public let length: Int
    public let line: String
    public let char: Int
    
    public init(message: String, index: Int, length: Int, line: String, char: Int) {
        self.message = message
        self.index = index
        self.length = length
        self.line = line
        self.char = char
    }
}
