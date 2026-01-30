import Foundation

public struct CheckFailure {
    public let ok = false
    public let errors: [CheckError]
}
