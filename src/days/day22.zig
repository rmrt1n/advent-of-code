const std = @import("std");

fn Day22(length: usize) type {
    return struct {
        numbers: [length]u64 = undefined,

        const Self = @This();

        fn init(data: []const u8) !Self {
            var result = Self{};

            var i: usize = 0;
            var lexer = std.mem.tokenizeScalar(u8, data, '\n');
            while (lexer.next()) |line| : (i += 1) {
                result.numbers[i] = try std.fmt.parseInt(u64, line, 10);
            }

            return result;
        }

        fn part1(self: Self) u64 {
            var result: u64 = 0;

            for (self.numbers) |secret_number| {
                var next_secret_number = secret_number;
                for (0..2000) |_| {
                    next_secret_number = next(next_secret_number);
                }
                result += next_secret_number;
            }

            return result;
        }

        fn part2(self: Self) u64 {
            var sequences = [_]u32{0} ** std.math.pow(u32, 19, 4);
            var seen_sequences: [std.math.pow(u32, 19, 4)]u16 = undefined;

            for (self.numbers, 0..) |secret_number, i| {
                var prices: [2001]u8 = undefined;
                prices[0] = @intCast(secret_number % 10);
                var next_secret_number = secret_number;
                for (1..2001) |j| {
                    next_secret_number = next(next_secret_number);
                    prices[j] = @intCast(next_secret_number % 10);
                }

                var j: usize = 1;
                while (j < 2001 - 3) : (j += 1) {
                    var key: u32 = 0;
                    for (0..4) |k| {
                        const diff = @as(i16, prices[j + k]) - prices[j + k - 1];
                        key = key * 18 + @as(u8, @intCast(diff + 9));
                    }

                    // Saves around 15ms by not zeroing out the array.
                    if (seen_sequences[key] == i) continue;
                    seen_sequences[key] = @intCast(i);

                    sequences[key] += prices[j + 3];
                }
            }

            return std.mem.max(u32, &sequences);
        }

        fn next(secret_number: u64) u64 {
            var result = secret_number;
            result ^= (result * 64) % 16777216;
            result ^= (result / 32) % 16777216;
            result ^= (result * 2048) % 16777216;
            return result;
        }
    };
}

pub const title = "Day 22: Monkey Market";

pub fn run(_: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    const input = @embedFile("./data/day22.txt");
    const puzzle = try Day22(1787).init(input);
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
    \\1
    \\10
    \\100
    \\2024
;

test "day 22 part 1 sample 1" {
    const puzzle = try Day22(4).init(sample_input);
    const result = puzzle.part1();
    try std.testing.expectEqual(37327623, result);
}

const sample_input2 =
    \\1
    \\2
    \\3
    \\2024
;

test "day 22 part 2 sample 2" {
    const puzzle = try Day22(4).init(sample_input2);
    const result = puzzle.part2();
    try std.testing.expectEqual(23, result);
}

// https://www.reddit.com/r/adventofcode/comments/1hjz1w4/2024_day_22_part_2_a_couple_of_diagnostic_test/
const sample_input3 =
    \\2021
    \\5017
    \\19751
;

test "day 22 part 2 sample 3" {
    const puzzle = try Day22(3).init(sample_input3);
    const result = puzzle.part2();
    try std.testing.expectEqual(27, result);
}

const sample_input4 =
    \\5053
    \\10083
    \\11263
;

test "day 22 part 2 sample 4" {
    const puzzle = try Day22(3).init(sample_input4);
    const result = puzzle.part2();
    try std.testing.expectEqual(27, result);
}
