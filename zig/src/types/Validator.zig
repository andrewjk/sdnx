/// Validator represents a field validator with raw value and required flag
pub const Validator = struct {
    raw: []const u8,
    required: bool,
};
