import Foundation

public struct ParseFailure {
    public let ok = false
    public let errors: [ParseError]
    
    public init(errors: [ParseError]) {
        self.errors = errors
    }
}
