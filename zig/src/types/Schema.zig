const std = @import("std");

const SchemaValue = @import("./SchemaValue.zig").SchemaValue;

/// Schema is a map of field names to schema values
pub const Schema = std.StringArrayHashMap(SchemaValue);
