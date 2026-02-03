import Foundation
@testable import sdnx
import Collections

func unwrapParseResult(_ result: ParseResult) throws -> OrderedDictionary<String, Any> {
    switch result {
    case .success(let success):
        return success.data
    case .failure(let failure):
        struct TestError: Error {
            let errors: [ParseError]
        }
        throw TestError(errors: failure.errors)
    }
}

func unwrapParseSchemaResult(_ result: ParseSchemaResult) throws -> Schema {
    switch result {
    case .success(let success):
        return success.data
    case .failure(let failure):
        struct TestError: Error {
            let errors: [ParseError]
        }
        throw TestError(errors: failure.errors)
    }
}
