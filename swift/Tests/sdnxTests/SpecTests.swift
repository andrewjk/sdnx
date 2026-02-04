import Testing
@testable import sdnx
import Foundation

@Suite("SPEC tests") struct SpecTests {
    static let ONLY_TEST: Int? = nil

    @Test func runSpecExamples() throws {
        let specPath = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().appendingPathComponent("SPEC.md")
        let specContent = try String(contentsOf: specPath, encoding: .utf8)
        let lines = specContent.components(separatedBy: .newlines)

        struct TestCase {
            let schema: String
            let input: String
            let expected: String
            let header: String
            let lineNumber: Int
        }

        var testCases: [TestCase] = []
        var i = 0

        while i < lines.count {
            if lines[i].hasPrefix("```````````````````````````````` example") {
                var exampleLines: [String] = []
                let startLine = i + 1
                var j = i + 1
                while j < lines.count && !lines[j].hasPrefix("````````````````````````````````") {
                    exampleLines.append(lines[j])
                    j += 1
                }

                let joined = exampleLines.joined(separator: "\n")
                    .replacingOccurrences(of: "→", with: "\t")
                let parts = joined.components(separatedBy: ".\n").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

                let schema = parts.count > 0 ? parts[0] : ""
                let input = parts.count > 1 ? parts[1] : ""
                var expected = parts.count > 2 ? parts[2] : ""

                if expected.isEmpty {
                    expected = "OK"
                }

                let inputPreview = input.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                let header = "spec example \(testCases.count + 1), line \(startLine + 1): '\(inputPreview)'"

                testCases.append(TestCase(
                    schema: schema,
                    input: input,
                    expected: expected,
                    header: header,
                    lineNumber: startLine + 1
                ))

                i = j
            } else {
                i += 1
            }
        }

        var failures: [String] = []

        for (_, testCase) in testCases.enumerated() {
            if let onlyTest = Self.ONLY_TEST, !testCase.header.contains("Example \(onlyTest),") {
                continue
            }

            var result = "OK"

            let parseSchemaResult = parseSchema(testCase.schema)
            switch parseSchemaResult {
            case .success(let schemaSuccess):
                let schema = schemaSuccess.data
                let parseInputResult = parse(testCase.input)
                switch parseInputResult {
                case .success(let inputSuccess):
                    let input = inputSuccess.data
                    let checkResult = check(input, schema: schema)
                    switch checkResult {
                    case .success:
                        if testCase.expected != "OK" {
                            result = stringify(input)
                        }
                    case .failure(let failure):
                        let errorMessage = failure.errors.map { $0.message }.joined(separator: "")
                        result = "Error: \(errorMessage)"
                    }
                case .failure(let failure):
                    let errorMessage = failure.errors.map { $0.message }.joined(separator: "")
                    result = "Error: \(errorMessage)"
                }
            case .failure(let failure):
                let errorMessage = failure.errors.map { $0.message }.joined(separator: "")
                result = "Error: \(errorMessage)"
            }

            if result != testCase.expected {
                failures.append("""
                \(testCase.header)

                Expected:
                \(testCase.expected)

                Got:
                \(result)

                Schema:
                \(testCase.schema)

                Input:
                \(testCase.input)
                """)
            }
        }

        #expect(failures.isEmpty, "\(failures.count) spec test(s) failed:\n\n\(failures.joined(separator: "\n\n---\n\n"))")
    }
}
