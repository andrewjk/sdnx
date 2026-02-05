# AGENTS.md

## Overview

This repository contains implementations of Structured Data Notation (SDN) in multiple languages:
- **TypeScript** (web/) - Primary implementation
- **Zig** (zig/) - Alternative implementation
- **Swift** (swift/) - Alternative implementation
- **C#** (dotnet/) - Alternative implementation

## Build, Lint, and Test Commands

### TypeScript/Node.js (web/)

```bash
cd web

# Type check and lint
pnpm check

# Run all tests
pnpm test

# Run specific test file
pnpm test -- --run test/parse.test.ts

# Run specific test by name
pnpm test -- --run -t "test name"

# Build
pnpm build

# Format code
pnpm format
```

### Zig (zig/)

```bash
cd zig

# Build
zig build

# Run all tests
zig build test

# Run specific test (from test/ directory)
cd test && zig test parse.test.zig

# Run test with filter (VSCode integration)
zig build test -Dtest-filter="test name"
```

### Swift (swift/)

```bash
cd swift

# Build
swift build

# Run all tests
swift test

# Run specific test
swift test --filter testName
```

### C# (dotnet/)

```bash
cd dotnet

# Build
dotnet build

# Run all tests
dotnet test

# Run tests for specific project
dotnet test Sdnx.Tests/Sdnx.Tests.csproj

# Run specific test class (filter by full name)
dotnet test --filter "FullyQualifiedName~ReadTests"

# Run specific test method
dotnet test --filter "FullyQualifiedName~Read_SuccessfulWithSchemaDirective"

# Build specific project
dotnet build Sdnx.Core/Sdnx.Core.csproj

# Run tests without rebuild
dotnet test --no-build
```

## Code Style Guidelines

### TypeScript/Node.js

#### Import Ordering
- Parent directory imports first: `../`
- Current directory imports second: `./`
- Uses `@trivago/prettier-plugin-sort-imports`
- Sorts specifiers within each import group

#### Naming Conventions
- **Functions**: camelCase, PascalCase for exports
- **Types**: PascalCase (interfaces, types, enums)
- **Variables**: camelCase
- **Constants**: UPPER_SNAKE_CASE
- **Private members**: underscore prefix (e.g., `_privateMethod`)

#### Code Formatting
- Use tabs for indentation
- Maximum line width: 100 characters
- Always use trailing commas for arrays/objects
- Single quotes for strings

#### Type System
- Enable all strict TypeScript checks
- Use `erasableSyntaxOnly: true`
- `noUnusedLocals` and `noUnusedParameters` enforced
- `strictNullChecks` enabled
- Use `isolatedDeclarations: true`

#### Error Handling
- Always check for errors when using async/await
- Use try/catch blocks for error handling
- Type annotations for function parameters and return types
- Export public API functions explicitly

#### Documentation
- Use JSDoc comments for exported functions: `/** ... */`
- Describe parameters and return values

### Zig

#### Naming Conventions
- **Functions**: camelCase
- **Types**: PascalCase
- **Constants**: UPPER_SNAKE_CASE
- **Private functions**: underscore prefix
- **Test functions**: quoted strings (e.g., `test "simple test"`)

#### Error Handling
- Use result state error handling with `anyerror!` return types
- Always use `try` keyword to propagate errors
- Explicitly handle `anyerror` in tests with `std.testing.expect`
- Use `defer` for cleanup operations

#### Module Organization
- `root.zig`: Package root, exports public functions
- `main.zig`: CLI entry point
- Imports use `@import("module_name")` syntax
- Test files in `test/` directory, not `src/`

#### Code Formatting
- 4-space indentation
- Consistent spacing around operators
- No trailing whitespace
- Blank lines between functions

### Swift

#### Naming Conventions
- **Types**: PascalCase
- **Functions**: camelCase
- **Constants**: camelCase with descriptive names
- **Private members**: private keyword

#### Code Formatting
- 4-space indentation
- Opening braces on same line
- No trailing whitespace

### C# (dotnet/)

#### Naming Conventions
- **Types**: PascalCase (classes, structs, enums)
- **Methods/Functions**: PascalCase
- **Properties**: PascalCase
- **Parameters**: camelCase
- **Local variables**: camelCase
- **Private methods**: camelCase (private modifier)
- **Constants**: PascalCase or UPPER_SNAKE_CASE
- **Namespaces**: PascalCase (Sdnx, Sdnx.Types, Sdnx.Tests)

#### Code Formatting
- Use tabs for indentation (consistent with TypeScript)
- 4-space equivalent visual indentation
- Maximum line width: ~100 characters (consistent with TypeScript)
- Opening braces on same line
- Use trailing commas for array/object initializers

#### Type System
- Target framework: .NET 10.0 (latest)
- Implicit usings enabled: `enable`
- Nullable reference types enabled: `enable`
- Latest language version: `latest`
- Use `object?` for nullable types
- Use generic `ParseResult<T>` for operation results

#### Error Handling
- Use try/catch for exception handling
- Check result.Ok status for operation results
- Use ParseResult<T> pattern: `Ok` bool, `Data` T, `Errors` List
- Use Assert.ThrowsException<T> for expected exceptions
- Use Assert.IsTrue/False with descriptive messages

#### Testing (MSTest)
- Test classes marked with `[TestClass]`
- Test methods marked with `[TestMethod]`
- Setup/cleanup with `[TestInitialize]`/`[TestCleanup]`
- Parallel execution at method level: `[assembly: Parallelize(Scope = ExecutionScope.MethodLevel)]`
- Use `Assert.AreEqual`, `Assert.IsTrue`, `Assert.IsNotNull` for assertions
- Use pattern matching: `if (result is ReadSuccess success)`

#### Namespace Organization
- Main namespace: `Sdnx.Core`
- Types namespace: `Sdnx.Core`
- Test namespace: `Sdnx.Tests`
- Separate library project (Sdnx.Core/Sdnx.Core.csproj) and test project (Sdnx.Tests/Sdnx.Tests.csproj)

#### Module Organization
- Static classes for utilities: `Utils`, `Stringify`, `ConvertValue`
- Parser classes: `ParseData`, `ParseSchema`, `ReadData`, `CheckData`
- Type classes in Types/ subdirectory
- Test files in Sdnx.Tests/ project
- Solution file: Sdnx.sln

## Project Structure

```
sdnx/
├── web/                    # TypeScript implementation
│   ├── src/               # Source code
│   ├── test/              # Test files
│   ├── package.json       # Dependencies and scripts
│   ├── tsconfig.json      # TypeScript config
│   └── .prettierrc        # Prettier config with import sorting
├── zig/                   # Zig implementation
│   ├── src/              # Source code (no test files here)
│   ├── test/             # Test files (moved from src/)
│   ├── build.zig         # Zig build system
│   └── build.zig.zon     # Zig package manifest
├── swift/                 # Swift implementation
│   ├── Sources/          # Source code
│   ├── Tests/            # Test files
│   └── Package.swift     # Swift package manifest
├── dotnet/                # C# implementation
│   ├── Sdnx.Core/         # Library project
│   │   ├── Types/        # Type definitions
│   │   └── *.cs         # Source files
│   ├── Sdnx.Tests/       # Test project
│   │   └── *.cs         # Test files
│   └── Sdnx.sln          # Solution file
├── SPEC.md               # SDN format specification
└── README.md             # Project overview
```

## Development Workflow

1. Make changes to source files
2. Run lint/check: `pnpm check` (TypeScript), `zig build` (Zig), `swift build` (Swift), or `dotnet build` (C#)
3. Run tests: `pnpm test`, `zig build test`, `swift test`, or `dotnet test`
4. Format code: `pnpm format` (TypeScript)
5. Add tests for new functionality
6. Update SPEC.md if format specifications change

## Important Notes

- Uses pnpm as package manager (see pnpm-lock.yaml)
- TypeScript: strict mode, tabs for indentation, 100 char line width
- Zig: result state error handling, tests in separate test/ directory
- Swift: standard Swift package structure
- C#: MSTest framework, nullable reference types enabled, implicit usings
- All implementations must conform to SPEC.md
- VSCode settings include Zig test filter configuration
- C# tests use parallel execution at method level
