//! By convention, root.zig is the root source file when making a package.

/// Re-export parse module
pub const parse_mod = @import("parse.zig");

/// Re-export parseSchema module
pub const parseSchema_mod = @import("parseSchema.zig");

/// Re-export check module
pub const check_mod = @import("check.zig");

/// Re-export parse function
pub const parse = parse_mod.parse;

/// Re-export parseSchema function
pub const parseSchema = parseSchema_mod.parseSchema;

/// Re-export check function
pub const check = check_mod.check;
