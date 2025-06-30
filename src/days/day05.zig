const std = @import("std");

fn Day05(length: usize) type {
    return struct {
        const Self = @This();

        const rule_capacity = 100;
        const update_capacity = 23;

        rules: [rule_capacity][rule_capacity]bool = .{.{false} ** rule_capacity} ** rule_capacity,
        updates: [length][update_capacity]u8 = undefined,
        lengths: [length]u8 = undefined,

        fn init(input: []const u8) !Self {
            var result = Self{};

            var lexer = std.mem.splitScalar(u8, input, '\n');
            while (lexer.next()) |line| {
                if (line.len == 0) break; // Last newline

                const before = try std.fmt.parseInt(u8, line[0..2], 10);
                const after = try std.fmt.parseInt(u8, line[3..], 10);
                result.rules[before][after] = true;
            }

            var i: usize = 0;
            while (lexer.next()) |line| : (i += 1) {
                if (line.len == 0) break; // Last newline

                var j: u8 = 0;
                var inner_lexer = std.mem.tokenizeScalar(u8, line, ',');
                while (inner_lexer.next()) |number| : (j += 1) {
                    result.updates[i][j] = try std.fmt.parseInt(u8, number, 10);
                }
                result.lengths[i] = j;
            }

            return result;
        }

        fn part1(self: Self) u64 {
            var result: u64 = 0;
            for (self.updates, self.lengths) |update, len| {
                if (std.sort.isSorted(u8, update[0..len], &self, sort_topological)) {
                    result += update[len / 2];
                }
            }
            return result;
        }

        fn part2(self: Self) u64 {
            var result: u64 = 0;
            for (self.updates, self.lengths) |update, len| {
                if (!std.sort.isSorted(u8, update[0..len], &self, sort_topological)) {
                    var mutable = update;
                    std.mem.sort(u8, mutable[0..len], &self, sort_topological);
                    result += mutable[len / 2];
                }
            }
            return result;
        }

        fn sort_topological(self: *const Self, a: u8, b: u8) bool {
            return self.rules[a][b];
        }
    };
}

pub const title = "Day 05: Print Queue";

pub fn run(_: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    const input = @embedFile("./data/day05.txt");
    const puzzle = try Day05(182).init(input);
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
    \\47|53
    \\97|13
    \\97|61
    \\97|47
    \\75|29
    \\61|13
    \\75|53
    \\29|13
    \\97|29
    \\53|29
    \\61|53
    \\97|53
    \\61|29
    \\47|13
    \\75|47
    \\97|75
    \\47|61
    \\75|61
    \\47|29
    \\75|13
    \\53|13
    \\
    \\75,47,61,53,29
    \\97,61,53,29,13
    \\75,29,13
    \\75,97,47,61,53
    \\61,13,29
    \\97,13,75,29,47
;

test "day 05 part 1 sample 1" {
    const puzzle = try Day05(6).init(sample_input);
    const result = puzzle.part1();
    try std.testing.expectEqual(143, result);
}

test "day 05 part 2 sample 1" {
    const puzzle = try Day05(6).init(sample_input);
    const result = puzzle.part2();
    try std.testing.expectEqual(123, result);
}
