import Foundation
import Collections

public enum ReadResult {
    case success(ReadSuccess)
    case failure(ReadFailure)
}

public struct ReadSuccess {
    public let ok = true
    public let data: OrderedDictionary<String, Any>
    
    public init(data: OrderedDictionary<String, Any>) {
        self.data = data
    }
}

public struct ReadFailure {
    public let ok = false
    public let schemaErrors: [ReadError]
    public let dataErrors: [ReadError]
    public let checkErrors: [CheckError]
    
    public init(schemaErrors: [ReadError], dataErrors: [ReadError], checkErrors: [CheckError]) {
        self.schemaErrors = schemaErrors
        self.dataErrors = dataErrors
        self.checkErrors = checkErrors
    }
}
