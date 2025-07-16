const std = @import("std");

fn Day19(n_patterns: usize, n_designs: usize) type {
    return struct {
        const Self = @This();

        patterns: [n_patterns][]const u8 = undefined,
        designs: [n_designs][]const u8 = undefined,

        fn init(data: []const u8) Self {
            var result = Self{};
            var lexer = std.mem.tokenizeScalar(u8, data, '\n');

            var i: usize = 0;
            var pattern_lexer = std.mem.tokenizeAny(u8, lexer.next().?, ", ");
            while (pattern_lexer.next()) |pattern| : (i += 1) {
                result.patterns[i] = pattern;
            }

            i = 0;
            while (lexer.next()) |design| : (i += 1) {
                result.designs[i] = design;
            }

            return result;
        }

        fn part1(self: Self) u64 {
            var result: u64 = 0;
            for (self.designs) |design| {
                result += @intFromBool(self.count_permutations(design) > 0);
            }
            return result;
        }

        fn part2(self: Self) u64 {
            var result: u64 = 0;
            for (self.designs) |design| {
                result += self.count_permutations(design);
            }
            return result;
        }

        fn count_permutations(self: Self, design: []const u8) u64 {
            // Should fit empty string (0-length) -> longest string (60 in my input).
            const longest_string = 60 + 1;
            var permutations = [_]u64{0} ** longest_string;

            permutations[0] = 1;

            for (1..(design.len + 1)) |i| {
                for (self.patterns) |pattern| {
                    if (pattern.len > i) continue;
                    if (std.mem.eql(u8, pattern, design[(i - pattern.len)..i])) {
                        permutations[i] += permutations[i - pattern.len];
                    }
                }
            }

            return permutations[design.len];
        }
    };
}

pub const title = "Day 19: Linen Layout";

pub fn run(_: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    const input = @embedFile("./data/day19.txt");
    const puzzle = Day19(447, 400).init(input);
    const time0 = timer.read();

    const result1 = puzzle.part1();
    const time1 = timer.read();

    const result2 = puzzle.part2();
    const time2 = timer.read();

    if (is_run) {
        std.debug.print("Part 1: {d}\nPart 2: {d}\n", .{ result1, result2 });
    }

    return .{ time0, time1, time2 };
}

const sample_input =
    \\r, wr, b, g, bwu, rb, gb, br
    \\
    \\brwrr
    \\bggr
    \\gbbr
    \\rrbgbr
    \\ubwu
    \\bwurrg
    \\brgr
    \\bbrgwb
;

test "day 19 part 1" {
    const puzzle = Day19(8, 8).init(sample_input, std.testing.allocator);
    const result = puzzle.part1();
    try std.testing.expectEqual(6, result);
}

test "day 19 part 2" {
    const puzzle = Day19(8, 8).init(sample_input, std.testing.allocator);
    const result = try puzzle.part2();
    try std.testing.expectEqual(16, result);
}

const sample_input2 =
    \\b, bb, bbb, bbbb, bbbbb, bbbbbb, ru, ur, rr, uu, r
    \\
    \\bbbbbbbbbbbbbbbbbbbbbbbbrrru
    \\bbbbbbbbbbbbbbbbbbbbbbbbrruu
    \\bbbbbbbbbbbbbbbbbbbbbbbbruur
    \\bbbbbbbbbbbbbbbbbbbbbbbbrurr
;

test "day 19 part 2 2" {
    const puzzle = Day19(11, 4).init(sample_input2, std.testing.allocator);
    const result = try puzzle.part2();
    try std.testing.expectEqual(64644552, result);
}

const sample_input3 =
    \\b, bb, bbb
    \\
    \\bbbb
;

test "day 19 part 2 3" {
    const puzzle = Day19(3, 1).init(sample_input3, std.testing.allocator);
    const result = try puzzle.part2();
    try std.testing.expectEqual(7, result);
}

const sample_input4 =
    \\r, w, b, u, bb
    \\
    \\brbbrubbbuw
;

test "day 19 part 2 4" {
    const puzzle = Day19(5, 1).init(sample_input4, std.testing.allocator);
    const result = try puzzle.part2();
    try std.testing.expectEqual(6, result);
}
