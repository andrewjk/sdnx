import Foundation

public protocol SchemaValue {
    var type: String { get }
    var description: String? { get set }
    var validators: [String: ValidatorInfo]? { get set }
}
