const std = @import("std");
const sdn = @import("sdn");
const parseSchema = sdn.parseSchema_mod;
const check = sdn.check;
const parse = sdn.parse;

// Read SPEC.md at compile time
const spec_file = @embedFile("SPEC.md");

test "spec examples" {
    // TODO: Not sure why we can't read files in tests
    //const file_path = "../../SPEC.md";
    //const spec_file = try std.fs.cwd().readFileAlloc(std.testing.allocator, file_path, .unlimited);
    //defer spec_file.deinit();

    var lines = std.mem.splitScalar(u8, spec_file, '\n');
    var i: usize = 0;
    var num: usize = 0;

    var ok = true;
    var test_results = std.ArrayList(u8).empty;
    defer test_results.deinit(std.testing.allocator);

    while (lines.next()) |line| {
        if (std.mem.startsWith(u8, line, "```````````````````````````````` example")) {
            num += 1;

            var example_text = std.ArrayList(u8).empty;
            defer example_text.deinit(std.testing.allocator);

            var lines_iter = std.mem.splitScalar(u8, spec_file[i + line.len ..], '\n');
            while (lines_iter.next()) |ex_line| {
                if (std.mem.startsWith(u8, ex_line, "````````````````````````````````")) {
                    break;
                }
                for (ex_line) |c| {
                    try example_text.append(std.testing.allocator, c);
                }
                try example_text.append(std.testing.allocator, '\n');
            }

            const full_example = example_text.items;
            var parts = std.mem.splitSequence(u8, full_example, "\n.\n");

            const schema_raw = parts.next() orelse "";
            const input_raw = parts.next() orelse "";
            const expected_raw = parts.rest();

            const schema_trimmed = std.mem.replaceOwned(u8, std.testing.allocator, schema_raw, "→", "\t") catch unreachable;
            defer std.testing.allocator.free(schema_trimmed);
            const input_trimmed = std.mem.replaceOwned(u8, std.testing.allocator, input_raw, "→", "\t") catch unreachable;
            defer std.testing.allocator.free(input_trimmed);
            const expected_trimmed = std.mem.trim(u8, expected_raw, &std.ascii.whitespace);

            const schema_str = std.mem.trim(u8, schema_trimmed, &std.ascii.whitespace);
            const input_str = std.mem.trim(u8, input_trimmed, &std.ascii.whitespace);
            const expected_str = std.mem.replaceOwned(u8, std.testing.allocator, expected_trimmed, "→", "\t") catch unreachable;
            defer std.testing.allocator.free(expected_str);

            var schema_result = parseSchema.parseSchema(std.testing.allocator, schema_str) catch {
                if (expected_str.len > 0) {} else {
                    ok = false;
                    std.debug.print("Spec test {d} failed parse schema: {s}\n", .{ num, input_str });
                }
                i += line.len + 1;
                continue;
            };
            defer schema_result.deinit();

            const input_data = parse(std.testing.allocator, input_str) catch {
                if (expected_str.len > 0) {} else {
                    ok = false;
                    std.debug.print("Spec test {d} failed parse: {s}\n", .{ num, input_str });
                }
                i += line.len + 1;
                continue;
            };
            defer input_data.deinit(std.testing.allocator);

            var check_result = check(std.testing.allocator, &input_data, &schema_result.schema) catch {
                if (expected_str.len > 0) {} else {
                    ok = false;
                    std.debug.print("Spec test {d} failed check: {s}\n", .{ num, input_str });
                }
                i += line.len + 1;
                continue;
            };
            defer check_result.deinit(std.testing.allocator);

            var test_ok = true;

            switch (check_result) {
                .ok => {
                    if (expected_str.len == 0 or std.mem.eql(u8, expected_str, "OK")) {} else {
                        ok = false;
                        test_ok = false;
                    }
                },
                .err_list => {
                    if (expected_str.len == 0 or std.mem.eql(u8, expected_str, "OK")) {
                        ok = false;
                        test_ok = false;
                    }
                },
            }

            if (test_ok == true) {
                //std.debug.print("Spec test {d} passed: {s}\n", .{ num, input_str });
            } else {
                std.debug.print("Spec test {d} failed\nSchema: '{s}'\nInput: '{s}'\nExpected: '{s}'\n\n", .{ num, schema_str, input_str, expected_str });
            }
        }
        i += line.len + 1;
    }

    try std.testing.expect(ok);
}
