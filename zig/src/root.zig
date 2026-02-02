//! By convention, root.zig is the root source file when making a package.

/// Re-export parse module
pub const parse_mod = @import("parse.zig");

/// Re-export parseSchema module
pub const parseSchema_mod = @import("parseSchema.zig");

/// Re-export check module
pub const check_mod = @import("check.zig");

/// Re-export read module
pub const read_mod = @import("read.zig");

/// Re-export parse function
pub const parse = parse_mod.parse;

/// Re-export parseSchema function
pub const parseSchema = parseSchema_mod.parseSchema;

/// Re-export SchemaParseResult type
pub const SchemaParseResult = parseSchema_mod.SchemaParseResult;

/// Re-export check function
pub const check = check_mod.check;

/// Re-export stringify module
pub const stringify_mod = @import("stringify.zig");

/// Re-export stringify function
pub const stringify = stringify_mod.stringify;

/// Re-export stringify Options type
pub const StringifyOptions = stringify_mod.Options;

/// Re-export read function
pub const read = read_mod.read;

/// Re-export locate function
pub const locate = read_mod.locate;

/// Re-export ReadResult type
pub const ReadResult = read_mod.ReadResult;

/// Re-export ReadErrorInfo type
pub const ReadErrorInfo = read_mod.ReadErrorInfo;

/// Re-export ReadError
pub const ReadError = read_mod.ReadError;

/// Re-export Value type
pub const Value = @import("./types/Value.zig").Value;

/// Re-export Schema type
pub const Schema = @import("./types/Schema.zig").Schema;

/// Re-export ValidationError type
pub const ValidationError = @import("check.zig").ValidationError;
