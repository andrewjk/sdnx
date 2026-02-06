import Testing
@testable import sdnx
import Foundation
import Collections

@Suite("Read tests") struct ReadTests {
    // Test helpers
    private var tmpDir: String {
        return FileManager.default.temporaryDirectory.appendingPathComponent("sdnx-read-test-\(Date().timeIntervalSince1970)").path
    }

    struct TestFile {
        var name: String
        var content: String
    }
    
    private func setupTestFiles(_ files: [TestFile]) -> [String] {
        let fm = FileManager.default
        let baseDir = tmpDir
        
        try? fm.createDirectory(atPath: baseDir, withIntermediateDirectories: true, attributes: nil)
        
        var paths: [String] = []
        for f in files {
            let filePath = (baseDir as NSString).appendingPathComponent(f.name)
            let dir = (filePath as NSString).deletingLastPathComponent
            
            if !fm.fileExists(atPath: dir) {
                try? fm.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
            }
            
            try? f.content.write(toFile: filePath, atomically: true, encoding: .utf8)
            paths.append(filePath)
        }
        
        return paths
    }

    private func cleanupTestFiles() {
        let fm = FileManager.default
        let baseDir = tmpDir
        try? fm.removeItem(atPath: baseDir)
    }

    // MARK: - Tests

    @Test func readSuccessfulWithSchemaDirective() throws {
        defer { cleanupTestFiles() }
        
        let schema = "{ name: string, age: int }"
        let data = "@schema(\"./schema.sdnx\")\n{ name: \"Alice\", age: 30 }"
        
        let paths = setupTestFiles([
            TestFile(name: "schema.sdnx", content: schema),
            TestFile(name: "data.sdn", content: data),
        ])
        
        let result = try read(paths[1])
        
        switch result {
        case .success(let success):
            #expect(success.data["name"] as? String == "Alice")
            #expect(success.data["age"] as? Int == 30)
        case .failure:
            #expect(Bool(false), "Expected success but got failure")
        }
    }
    
    @Test func readSuccessfulWithExplicitSchemaPath() throws {
        defer { cleanupTestFiles() }
        
        let schema = "{ name: string, age: int }"
        let data = "{ name: \"Bob\", age: 25 }"
        
        let paths = setupTestFiles([
            TestFile(name: "schema.sdnx", content: schema),
            TestFile(name: "data.sdn", content: data),
        ])
        
        let result = try read(paths[1], schema: paths[0])
        
        switch result {
        case .success(let success):
            #expect(success.data["name"] as? String == "Bob")
            #expect(success.data["age"] as? Int == 25)
        case .failure:
            #expect(Bool(false), "Expected success but got failure")
        }
    }
    
    @Test func readSuccessfulWithSchemaObject() throws {
        defer { cleanupTestFiles() }
        
        let schemaInput = "{ name: string, age: int }"
        let schemaResult = parseSchema(schemaInput)
        
        let schema: Schema
        switch schemaResult {
        case .success(let success):
            schema = success.data
        case .failure:
            #expect(Bool(false), "Schema parsing failed")
            return
        }
        
        let data = "{ name: \"Charlie\", age: 35 }"
        let paths = setupTestFiles([TestFile(name: "data.sdn", content: data)])
        
        let result = try read(paths[0], schema: schema)
        
        switch result {
        case .success(let success):
            #expect(success.data["name"] as? String == "Charlie")
            #expect(success.data["age"] as? Int == 35)
        case .failure:
            #expect(Bool(false), "Expected success but got failure")
        }
    }
    
    @Test func readFailsWithDataParseErrors() throws {
        defer { cleanupTestFiles() }
        
        let schema = "{ name: string, age: int }"
        let data = "@schema(\"./schema.sdnx\")\n{ name: \"Alice\", age: }"
        
        let paths = setupTestFiles([
            TestFile(name: "schema.sdnx", content: schema),
            TestFile(name: "data.sdn", content: data),
        ])
        
        let result = try read(paths[1])
        
        switch result {
        case .success:
            #expect(Bool(false), "Expected failure but got success")
        case .failure(let failure):
            #expect(!failure.dataErrors.isEmpty)
        }
    }
    
    @Test func readFailsWithSchemaParseErrors() throws {
        defer { cleanupTestFiles() }
        
        let schema = "{ name: string, age: }"
        let data = "@schema(\"./schema.sdnx\")\n{ name: \"Alice\", age: 30 }"
        
        let paths = setupTestFiles([
            TestFile(name: "schema.sdnx", content: schema),
            TestFile(name: "data.sdn", content: data),
        ])
        
        let result = try read(paths[1])
        
        switch result {
        case .success:
            #expect(Bool(false), "Expected failure but got success")
        case .failure(let failure):
            #expect(!failure.schemaErrors.isEmpty)
        }
    }
    
    @Test func readFailsWithValidationErrors() throws {
        defer { cleanupTestFiles() }
        
        let schema = "{ name: string, age: int min(18) }"
        let data = "@schema(\"./schema.sdnx\")\n{ name: \"Alice\", age: 15 }"
        
        let paths = setupTestFiles([
            TestFile(name: "schema.sdnx", content: schema),
            TestFile(name: "data.sdn", content: data),
        ])
        
        let result = try read(paths[1])
        
        switch result {
        case .success:
            #expect(Bool(false), "Expected failure but got success")
        case .failure(let failure):
            #expect(failure.schemaErrors.isEmpty)
            #expect(failure.dataErrors.isEmpty)
            #expect(!failure.checkErrors.isEmpty)
            if let firstError = failure.checkErrors.first {
                #expect(firstError.message.contains("least") || firstError.message.contains("18"))
            }
        }
    }
    
    @Test func readThrowsErrorWhenFileNotFound() {
        #expect {
            try read("/nonexistent/path/to/file.sdn")
        } throws: { error in
            if let readError = error as? ReadError {
                return readError.message.contains("File not found")
            }
            return false
        }
    }
    
    @Test func readThrowsErrorWhenSchemaDirectiveMissingAndSchemaNotProvided() throws {
        defer { cleanupTestFiles() }
        
        let data = "{ name: \"Alice\", age: 30 }"
        let paths = setupTestFiles([TestFile(name: "data.sdn", content: data)])
        
        #expect {
            try read(paths[0])
        } throws: { error in
            if let readError = error as? ReadError {
                return readError.message.contains("Schema required")
            }
            return false
        }
    }
    
    @Test func readResolvesRelativeSchemaPathCorrectly() throws {
        defer { cleanupTestFiles() }
        
        let schema = "{ name: string }"
        let data = "@schema(\"./schema.sdnx\")\n{ name: \"Alice\" }"
        
        let paths = setupTestFiles([
            TestFile(name: "schema.sdnx", content: schema),
            TestFile(name: "data.sdn", content: data),
        ])
        
        let result = try read(paths[1])
        
        switch result {
        case .success(let success):
            #expect(success.data["name"] as? String == "Alice")
        case .failure:
            #expect(Bool(false), "Expected success but got failure")
        }
    }
    
    @Test func readHandlesNestedSchemaPath() throws {
        defer { cleanupTestFiles() }
        
        let schema = "{ name: string }"
        let data = "@schema(\"./schemas/schema.sdnx\")\n{ name: \"Alice\" }"
        
        let paths = setupTestFiles([
            TestFile(name: "schemas/schema.sdnx", content: schema),
            TestFile(name: "data.sdn", content: data),
        ])
        
        let result = try read(paths[1])
        
        switch result {
        case .success(let success):
            #expect(success.data["name"] as? String == "Alice")
        case .failure:
            #expect(Bool(false), "Expected success but got failure")
        }
    }
    
    @Test func readHandlesComplexNestedData() throws {
        defer { cleanupTestFiles() }
        
        let schema = """
    {
        name: string,
        age: int,
        address: { street: string, city: string },
        tags: [string]
    }
    """
        
        let data = """
    @schema("./schema.sdnx")
    {
        name: "Alice",
        age: 30,
        address: { street: "123 Main St", city: "NYC" },
        tags: ["developer", "engineer"]
    }
    """
        
        let paths = setupTestFiles([
            TestFile(name: "schema.sdnx", content: schema),
            TestFile(name: "data.sdn", content: data),
        ])
        
        let result = try read(paths[1])
        
        switch result {
        case .success(let success):
            #expect(success.data["name"] as? String == "Alice")
            #expect(success.data["age"] as? Int == 30)
            
            if let address = success.data["address"] as? OrderedDictionary<String, Any> {
                #expect(address["street"] as? String == "123 Main St")
                #expect(address["city"] as? String == "NYC")
            } else {
                #expect(Bool(false), "address should be a dictionary")
            }
            
            if let tags = success.data["tags"] as? [String] {
                #expect(tags.count == 2)
                #expect(tags[0] == "developer")
                #expect(tags[1] == "engineer")
            } else {
                #expect(Bool(false), "tags should be an array of strings")
            }
        case .failure:
            #expect(Bool(false), "Expected success but got failure")
        }
    }
    
    @Test func readIncludesLineAndCharInfoInParseErrors() throws {
        defer { cleanupTestFiles() }
        
        let schema = "{ name: string }"
        let data = """
    @schema("./schema.sdnx")
    { name: "Alice",
    age: invalid
    }
    """
        
        let paths = setupTestFiles([
            TestFile(name: "schema.sdnx", content: schema),
            TestFile(name: "data.sdn", content: data),
        ])
        
        let result = try read(paths[1])
        
        switch result {
        case .success:
            #expect(Bool(false), "Expected failure but got success")
        case .failure(let failure):
            #expect(!failure.dataErrors.isEmpty)
            let errors = failure.dataErrors
            if let error = errors.first {
                #expect(!error.line.isEmpty)
                #expect(error.char >= 0)
                #expect(error.index >= 0)
                #expect(error.length > 0)
                #expect(!error.message.isEmpty)
            }
        }
    }
    
    @Test func readHandlesEmptyDataFile() throws {
        defer { cleanupTestFiles() }
        
        let schema = "{ name: string }"
        let data = "@schema(\"./schema.sdnx\")\n{}"
        
        let paths = setupTestFiles([
            TestFile(name: "schema.sdnx", content: schema),
            TestFile(name: "data.sdn", content: data),
        ])
        
        let result = try read(paths[1])
        
        switch result {
        case .success:
            #expect(Bool(false), "Expected failure but got success")
        case .failure(let failure):
            #expect(!failure.checkErrors.isEmpty)
        }
    }
    
    @Test func readHandlesSchemaWithUnionTypes() throws {
        defer { cleanupTestFiles() }
        
        let schema = "{ value: int | string }"
        let data = "@schema(\"./schema.sdnx\")\n{ value: 42 }"
        
        let paths = setupTestFiles([
            TestFile(name: "schema.sdnx", content: schema),
            TestFile(name: "data.sdn", content: data),
        ])
        
        let result = try read(paths[1])
        
        switch result {
        case .success(let success):
            #expect(success.data["value"] as? Int == 42)
        case .failure:
            #expect(Bool(false), "Expected success but got failure")
        }
    }
    
    @Test func readHandlesSchemaWithArrayOfObjects() throws {
        defer { cleanupTestFiles() }
        
        let schema = "{ users: [{ name: string, age: int }] }"
        let data = """
    @schema("./schema.sdnx")
    {
        users: [
            { name: "Alice", age: 30 },
            { name: "Bob", age: 25 }
        ]
    }
    """
        
        let paths = setupTestFiles([
            TestFile(name: "schema.sdnx", content: schema),
            TestFile(name: "data.sdn", content: data),
        ])
        
        let result = try read(paths[1])
        
        switch result {
        case .success(let success):
            if let users = success.data["users"] as? [OrderedDictionary<String, Any>] {
                #expect(users.count == 2)
                #expect(users[0]["name"] as? String == "Alice")
                #expect(users[0]["age"] as? Int == 30)
                #expect(users[1]["name"] as? String == "Bob")
                #expect(users[1]["age"] as? Int == 25)
            } else {
                #expect(Bool(false), "users should be an array of dictionaries")
            }
        case .failure:
            #expect(Bool(false), "Expected success but got failure")
        }
    }
}
