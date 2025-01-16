const std = @import("std");

const Operator = enum {
    add,
    mul,
    cat,

    fn apply(operator: Operator, x: u64, y: u64) u64 {
        return switch (operator) {
            .add => x + y,
            .mul => x * y,
            // This is roughly 1.5x faster than using a while loop.
            .cat => x * std.math.pow(u64, 10, std.math.log10(y) + 1) + y,
        };
    }
};

fn Day07(length: usize) type {
    return struct {
        results: [length]u64 = undefined,
        operands: [length][16]u16 = .{.{0} ** 16} ** length,

        const Self = @This();

        fn init(input: []const u8) !Self {
            var result = Self{};

            var i: usize = 0;
            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                var inner_lexer = std.mem.tokenizeScalar(u8, line, ' ');

                const left = inner_lexer.next().?;
                result.results[i] = try std.fmt.parseInt(u64, left[0..(left.len - 1)], 10);

                var j: usize = 1;
                while (inner_lexer.next()) |number| : (j += 1) {
                    result.operands[i][j] = try std.fmt.parseInt(u16, number, 10);
                }
                result.operands[i][0] = @intCast(j - 1);
            }

            return result;
        }

        fn part1(self: Self) u64 {
            var result: u64 = 0;
            for (self.results, 0..) |answer, i| {
                const operators = [_]Operator{ .add, .mul };
                if (is_valid_equation(answer, &self.operands[i], &operators)) {
                    result += answer;
                }
            }
            return result;
        }

        fn part2(self: Self) u64 {
            var result: u64 = 0;
            for (self.results, 0..) |answer, i| {
                const operators = [_]Operator{ .add, .mul, .cat };
                if (is_valid_equation(answer, &self.operands[i], &operators)) {
                    result += answer;
                }
            }
            return result;
        }

        fn is_valid_equation(
            result: u64,
            operands: []const u16,
            comptime operators: []const Operator,
        ) bool {
            // This is around 18x faster than using ArrayLists as a queue.
            // Prefer [N]u8 over [_]u8 ** N because the former is faster, more than 4x faster.
            const n = operators.len;
            var permutations: [(std.math.pow(u64, n, 12) - 1) / (n - 1)]u64 = undefined;
            permutations[0] = operands[1];

            var left: usize = 0;
            var right: usize = 1;
            for (operands[2..(operands[0] + 1)]) |operand| {
                const old_right = right;
                while (left < old_right) : (left += 1) {
                    for (operators) |operator| {
                        const applied = operator.apply(permutations[left], operand);

                        if (applied == result) return true;

                        // Don't include numbers larger than the result, it is a waste of
                        // computation. Adding this line results in a roughly 1.3x speedup.
                        if (applied > result) continue;

                        permutations[right] = applied;
                        right += 1;
                    }
                }
            }

            return false;
        }
    };
}

pub const title = "Day 07: Bridge Repair";

pub fn run(_: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    const input = @embedFile("./data/day07.txt");
    const puzzle = try Day07(850).init(input);
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
    \\190: 10 19
    \\3267: 81 40 27
    \\83: 17 5
    \\156: 15 6
    \\7290: 6 8 6 15
    \\161011: 16 10 13
    \\192: 17 8 14
    \\21037: 9 7 18 13
    \\292: 11 6 16 20
;

test "day 07 part 1 sample 1" {
    const puzzle = try Day07(9).init(sample_input);
    const result = puzzle.part1();
    try std.testing.expectEqual(3749, result);
}

test "day 07 part 2 sample 1" {
    const puzzle = try Day07(9).init(sample_input);
    const result = puzzle.part2();
    try std.testing.expectEqual(11387, result);
}
