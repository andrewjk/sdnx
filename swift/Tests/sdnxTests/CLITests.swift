import Testing
@testable import sdnx
import Foundation

// Test CLI functionality
@Test func cliSuccessWithSchema() throws {
    // Create temporary test files
    let fm = FileManager.default
    let tmpDir = fm.temporaryDirectory.appendingPathComponent("sdnx-cli-test-\(UUID().uuidString)")
    try? fm.createDirectory(atPath: tmpDir.path, withIntermediateDirectories: true, attributes: nil)
    
    defer {
        try? fm.removeItem(atPath: tmpDir.path)
    }
    
    // Create schema file
    let schemaPath = tmpDir.appendingPathComponent("schema.sdnx").path
    let schema = "{ name: string, age: int }"
    try schema.write(toFile: schemaPath, atomically: true, encoding: .utf8)
    
    // Create data file
    let dataPath = tmpDir.appendingPathComponent("data.sdn").path
    let data = "@schema(\"./schema.sdnx\")\n{ name: \"Alice\", age: 30 }"
    try data.write(toFile: dataPath, atomically: true, encoding: .utf8)
    
    // Test read functionality
    let result = try read(dataPath)
    
    switch result {
    case .success(let success):
        #expect(success.data["name"] as? String == "Alice")
        #expect(success.data["age"] as? Int == 30)
    case .failure:
        #expect(Bool(false), "Expected success but got failure")
    }
}

@Test func cliFailureWithInvalidData() throws {
    // Create temporary test files
    let fm = FileManager.default
    let tmpDir = fm.temporaryDirectory.appendingPathComponent("sdnx-cli-test-\(UUID().uuidString)")
    try? fm.createDirectory(atPath: tmpDir.path, withIntermediateDirectories: true, attributes: nil)
    
    defer {
        try? fm.removeItem(atPath: tmpDir.path)
    }
    
    // Create schema file
    let schemaPath = tmpDir.appendingPathComponent("schema.sdnx").path
    let schema = "{ name: string, age: int }"
    try schema.write(toFile: schemaPath, atomically: true, encoding: .utf8)
    
    // Create data file with invalid data
    let dataPath = tmpDir.appendingPathComponent("data.sdn").path
    let data = "@schema(\"./schema.sdnx\")\n{ name: \"Alice\", age: \"not a number\" }"
    try data.write(toFile: dataPath, atomically: true, encoding: .utf8)
    
    // Test read functionality - should fail validation
    let result = try read(dataPath)
    
    switch result {
    case .success:
        #expect(Bool(false), "Expected failure but got success")
    case .failure(let failure):
        #expect(!failure.checkErrors.isEmpty)
    }
}

@Test func cliFailureWithParseError() throws {
    // Create temporary test files
    let fm = FileManager.default
    let tmpDir = fm.temporaryDirectory.appendingPathComponent("sdnx-cli-test-\(UUID().uuidString)")
    try? fm.createDirectory(atPath: tmpDir.path, withIntermediateDirectories: true, attributes: nil)
    
    defer {
        try? fm.removeItem(atPath: tmpDir.path)
    }
    
    // Create schema file
    let schemaPath = tmpDir.appendingPathComponent("schema.sdnx").path
    let schema = "{ name: string, age: int }"
    try schema.write(toFile: schemaPath, atomically: true, encoding: .utf8)
    
    // Create data file with parse error (missing value)
    let dataPath = tmpDir.appendingPathComponent("data.sdn").path
    let data = "@schema(\"./schema.sdnx\")\n{ name: \"Alice\", age: }"
    try data.write(toFile: dataPath, atomically: true, encoding: .utf8)
    
    // Test read functionality - should fail parsing
    let result = try read(dataPath)
    
    switch result {
    case .success:
        #expect(Bool(false), "Expected failure but got success")
    case .failure(let failure):
        #expect(!failure.schemaErrors.isEmpty)
    }
}

@Test func cliWithExplicitSchemaPath() throws {
    // Create temporary test files
    let fm = FileManager.default
    let tmpDir = fm.temporaryDirectory.appendingPathComponent("sdnx-cli-test-\(UUID().uuidString)")
    try? fm.createDirectory(atPath: tmpDir.path, withIntermediateDirectories: true, attributes: nil)
    
    defer {
        try? fm.removeItem(atPath: tmpDir.path)
    }
    
    // Create schema file
    let schemaPath = tmpDir.appendingPathComponent("schema.sdnx").path
    let schema = "{ name: string }"
    try schema.write(toFile: schemaPath, atomically: true, encoding: .utf8)
    
    // Create data file without @schema directive
    let dataPath = tmpDir.appendingPathComponent("data.sdn").path
    let data = "{ name: \"Bob\" }"
    try data.write(toFile: dataPath, atomically: true, encoding: .utf8)
    
    // Test read functionality with explicit schema path
    let result = try read(dataPath, schema: schemaPath)
    
    switch result {
    case .success(let success):
        #expect(success.data["name"] as? String == "Bob")
    case .failure:
        #expect(Bool(false), "Expected success but got failure")
    }
}
