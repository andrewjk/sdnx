# AGENTS.md

## Overview

This repository contains implementations of Structured Data Notation (SDN) in multiple languages:
- TypeScript (web/) - Primary implementation
- Zig (zig/) - Alternative implementation

## Build, Lint, and Test Commands

### TypeScript/Node.js (web/)

```bash
cd web

# Type check and lint
pnpm check

# Run all tests
pnpm test

# Run specific test
pnpm test -- --run path/to/test.spec.ts

# Build
pnpm build

# Format
pnpm format
```

### Zig (zig/)

```bash
cd zig
zig build

# Run all tests
zig build test -Denable_cache=off

# Run single test
zig test path/to/test.zig
```

## Code Style Guidelines

### TypeScript/Node.js

#### Import Ordering
- Imports from parent directories first: `../`
- Imports from current directory second: `./`
- Use `@trivago/prettier-plugin-sort-imports` plugin
- Sort specifiers within each import group
- Example: `../pkg` comes before `./local-module`

#### Naming Conventions
- **Functions**: camelCase, PascalCase for exports
- **Types**: PascalCase (interfaces, types, enums)
- **Variables**: camelCase
- **Constants**: UPPER_SNAKE_CASE
- **Private members**: underscore prefix (e.g., `_privateMethod`)

#### Code Formatting
- Use tabs for indentation (not spaces)
- Maximum line width: 100 characters
- Always use trailing commas for arrays/objects
- Single quotes for strings (prefer `any` over `any`)

#### Type System
- Enable all strict TypeScript checks
- Use `erasableSyntaxOnly: true` for compiler-only features
- `noUnusedLocals` and `noUnusedParameters` enforced
- `strictNullChecks` enabled
- Use `isolatedDeclarations: true` for better type checking

#### Error Handling
- Always check for errors when using async/await or typed operations
- Use try/catch blocks for error handling
- Type annotations for function parameters and return types
- Export public API functions explicitly

#### Documentation
- Use JSDoc comments for exported functions: `/** ... */`
- Describe parameters and return values
- Use clear, descriptive docstrings

### Zig

#### Naming Conventions
- **Functions**: camelCase
- **Types**: PascalCase
- **Constants**: UPPER_SNAKE_CASE
- **Private functions**: underscore prefix
- **Test functions**: quoted strings (e.g., `test "simple test"`)

#### Error Handling
- Zig uses result state error handling with `anyerror!` return types
- Always use `try` keyword to propagate errors
- Explicitly handle `anyerror` in tests with `std.testing.expect`
- Use `defer` for cleanup operations

#### Module Organization
- `root.zig`: Package root, exports public functions, contains package-level tests
- `main.zig`: CLI entry point, contains executable tests
- Imports use `@import("module_name")` syntax
- Use `b.addModule()` and `b.addExecutable()` in build.zig for organization

#### Code Formatting
- 4-space indentation
- Consistent spacing around operators
- No trailing whitespace
- Blank lines between functions

#### Testing
- Tests defined with `test` keyword
- Test files in separate directories
- Use `std.testing.fuzz` for fuzz testing when appropriate
- Each test should be self-contained

## Project Structure

```
sdnx/
├── web/               # TypeScript implementation
│   ├── src/           # Source code
│   ├── test/          # Test files
│   ├── package.json   # Dependencies and scripts
│   ├── tsconfig.json  # TypeScript config
│   └── .prettierrc    # Prettier config
├── zig/              # Zig implementation
│   ├── src/           # Source code
│   ├── build.zig     # Zig build system
│   └── build.zig.zon # Zig package manifest
├── SPEC.md           # Specification for SDN format
└── README.md         # Project overview
```

## Development Workflow

1. Make changes to source files
2. Run `pnpm check` or `zig build test` to verify changes
3. Run `pnpm format` to ensure code formatting consistency
4. Add tests for new functionality
5. Update documentation in SPEC.md if format specifications change

## Important Notes

- Uses pnpm as package manager (check pnpm-lock.yaml)
- TypeScript: strict mode with erasable syntax only, isolated declarations
- Zig: uses result state error handling, fuzz testing support
- Both implementations must conform to SPEC.md
