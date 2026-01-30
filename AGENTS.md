# AGENTS.md

## Overview

This repository contains implementations of Structured Data Notation (SDN) in multiple languages:
- **TypeScript** (web/) - Primary implementation
- **Zig** (zig/) - Alternative implementation  
- **Swift** (swift/) - Alternative implementation

## Build, Lint, and Test Commands

### TypeScript/Node.js (web/)

```bash
cd web

# Type check and lint
pnpm check

# Run all tests
pnpm test

# Run specific test file
pnpm test -- --run test/parse.spec.ts

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
├── SPEC.md               # SDN format specification
└── README.md             # Project overview
```

## Development Workflow

1. Make changes to source files
2. Run lint/check: `pnpm check` (TypeScript) or `zig build` (Zig)
3. Run tests: `pnpm test` or `zig build test`
4. Format code: `pnpm format`
5. Add tests for new functionality
6. Update SPEC.md if format specifications change

## Important Notes

- Uses pnpm as package manager (see pnpm-lock.yaml)
- TypeScript: strict mode, tabs for indentation, 100 char line width
- Zig: result state error handling, tests in separate test/ directory
- Swift: standard Swift package structure
- Both implementations must conform to SPEC.md
- VSCode settings include Zig test filter configuration
