const std = @import("std");

fn Day07(length: usize) type {
    return struct {
        const Self = @This();

        const operand_capacity = 12;

        test_values: [length]u64 = undefined,
        operands: [length][operand_capacity]u16 = undefined,
        lengths: [length]u8 = undefined,

        fn init(input: []const u8) !Self {
            var result = Self{};

            var i: usize = 0;
            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                var inner_lexer = std.mem.tokenizeScalar(u8, line, ' ');

                const left = inner_lexer.next().?;
                result.test_values[i] = try std.fmt.parseInt(u64, left[0..(left.len - 1)], 10);

                var j: u8 = 0;
                while (inner_lexer.next()) |number| : (j += 1) {
                    result.operands[i][j] = try std.fmt.parseInt(u16, number, 10);
                }
                result.lengths[i] = j;
            }

            return result;
        }

        fn part1(self: Self) u64 {
            const operators = [_]Operator{ .add, .mul };
            const n = operators.len;
            var permutations: [(std.math.pow(u64, n, operand_capacity) - 1) / (n - 1)]u64 = undefined;

            var result: u64 = 0;
            for (self.test_values, self.operands, self.lengths) |test_value, operands, len| {
                if (is_valid_equation(&permutations, test_value, operands[0..len], &operators)) {
                    result += test_value;
                }
            }
            return result;
        }

        fn part2(self: Self) u64 {
            const operators = [_]Operator{ .add, .mul, .cat };
            const n = operators.len;
            var permutations: [(std.math.pow(u64, n, operand_capacity) - 1) / (n - 1)]u64 = undefined;

            var result: u64 = 0;
            for (self.test_values, self.operands, self.lengths) |test_value, operands, len| {
                if (is_valid_equation(&permutations, test_value, operands[0..len], &operators)) {
                    result += test_value;
                }
            }
            return result;
        }

        fn is_valid_equation(
            permutations: []u64,
            test_value: u64,
            operands: []const u16,
            comptime operators: []const Operator,
        ) bool {
            permutations[0] = operands[0];

            var left: usize = 0;
            var right: usize = 1;
            for (operands[1..]) |operand| {
                const permutations_length = right;
                while (left < permutations_length) : (left += 1) {
                    for (operators) |operator| {
                        const applied = operator.apply(permutations[left], operand);

                        if (applied == test_value) return true;

                        // Skip numbers larger than the test value.
                        if (applied > test_value) continue;

                        permutations[right] = applied;
                        right += 1;
                    }
                }
            }

            return false;
        }
    };
}

const Operator = enum {
    add,
    mul,
    cat,

    fn apply(operator: Operator, x: u64, y: u64) u64 {
        return switch (operator) {
            .add => x + y,
            .mul => x * y,
            .cat => x * std.math.pow(u64, 10, std.math.log10(y) + 1) + y,
        };
    }
};

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
