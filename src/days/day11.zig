const std = @import("std");

fn Day11(length: usize) type {
    return struct {
        stones: [length]u32 = undefined,
        allocator: std.mem.Allocator,

        const Self = @This();

        fn init(input: []const u8, allocator: std.mem.Allocator) !Self {
            var result = Self{ .allocator = allocator };

            var i: usize = 0;
            var lexer = std.mem.tokenizeScalar(u8, std.mem.trim(u8, input, "\n"), ' ');
            while (lexer.next()) |line| : (i += 1) {
                result.stones[i] = try std.fmt.parseInt(u32, line, 10);
            }

            return result;
        }

        fn part1(self: Self) !u64 {
            return try self.count_stones(25);
        }

        fn part2(self: Self) !u64 {
            return try self.count_stones(75);
        }

        fn count_stones(self: Self, n_blinks: u8) !u64 {
            var frequencies = std.AutoHashMap(u64, u64).init(self.allocator);
            defer frequencies.deinit();

            for (self.stones) |stone| try frequencies.put(stone, 1);

            for (0..n_blinks) |_| {
                var new_frequencies = std.AutoHashMap(u64, u64).init(self.allocator);
                var iterator = frequencies.iterator();
                while (iterator.next()) |entry| {
                    const stone = entry.key_ptr.*;
                    const count = entry.value_ptr.*;

                    if (stone == 0) {
                        const value = try new_frequencies.getOrPutValue(1, 0);
                        value.value_ptr.* += count;
                        continue;
                    }

                    const n = std.math.log10(stone) + 1;
                    if (n % 2 == 1) {
                        const value = try new_frequencies.getOrPutValue(stone * 2024, 0);
                        value.value_ptr.* += count;
                        continue;
                    }

                    const ten_power_n = std.math.pow(u64, 10, n / 2);
                    const left_value = try new_frequencies.getOrPutValue(stone / ten_power_n, 0);
                    left_value.value_ptr.* += count;
                    const right_value = try new_frequencies.getOrPutValue(stone % ten_power_n, 0);
                    right_value.value_ptr.* += count;
                }
                frequencies.deinit();
                frequencies = new_frequencies;
            }

            var result: u64 = 0;
            var iterator = frequencies.valueIterator();
            while (iterator.next()) |value| {
                result += value.*;
            }
            return result;
        }
    };
}

pub const title = "Day 11: Plutonian Pebbles";

pub fn run(allocator: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    const input = @embedFile("./data/day11.txt");
    const puzzle = try Day11(8).init(input, allocator);
    const time0 = timer.read();

    const result1 = try puzzle.part1();
    const time1 = timer.read();

    const result2 = try puzzle.part2();
    const time2 = timer.read();

    if (is_run) {
        std.debug.print("Part 1: {d}\nPart 2: {d}\n", .{ result1, result2 });
    }

    return .{ time0, time1, time2 };
}

const sample_input = "125 17";

test "day 11 part 1 sample 1" {
    const puzzle = try Day11(2).init(sample_input, std.testing.allocator);
    const result = try puzzle.part1();
    try std.testing.expectEqual(55312, result);
}

test "day 11 part 2 sample 1" {
    const puzzle = try Day11(2).init(sample_input, std.testing.allocator);
    const result = try puzzle.part2();
    try std.testing.expectEqual(65601038650482, result);
}
