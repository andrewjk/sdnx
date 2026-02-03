import Foundation

public struct ParseSuccess<T> {
    public let ok = true
    public let data: T
    
    public init(data: T) {
        self.data = data
    }
}
