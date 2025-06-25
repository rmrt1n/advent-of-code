const std = @import("std");

fn Day03() type {
    return struct {
        const Self = @This();

        memory: []const u8,

        fn init(input: []const u8) Self {
            return Self{ .memory = input };
        }

        // All the input slicing has been manually bound checked by looking at the input file, so
        // cases like the input ending in `mul` isn't possible.
        fn part1(self: Self) u64 {
            var result: u64 = 0;

            var i: usize = 0;
            while (i < self.memory[0..].len) : (i += 1) {
                if (self.memory[i] == 'm') {
                    if (std.mem.eql(u8, self.memory[i..(i + 4)], "mul(")) {
                        i += 4;

                        var x: u64 = 0;
                        while (self.memory[i] >= '0' and self.memory[i] <= '9') : (i += 1) {
                            x = x * 10 + self.memory[i] - '0';
                        }

                        if (self.memory[i] != ',') continue;
                        i += 1;

                        var y: u64 = 0;
                        while (self.memory[i] >= '0' and self.memory[i] <= '9') : (i += 1) {
                            y = y * 10 + self.memory[i] - '0';
                        }

                        if (self.memory[i] != ')') continue;

                        result += x * y;
                    }
                }
            }

            return result;
        }

        fn part2(self: Self) u64 {
            var result: u64 = 0;
            var mul_enabled = true;

            var i: usize = 0;
            while (i < self.memory[0..].len) : (i += 1) {
                if (self.memory[i] == 'd') {
                    if (std.mem.eql(u8, self.memory[i..(i + 4)], "do()")) {
                        mul_enabled = true;
                        i += 4;
                    }

                    if (std.mem.eql(u8, self.memory[i..(i + 7)], "don't()")) {
                        mul_enabled = false;
                        i += 7;
                    }
                }

                if (mul_enabled and self.memory[i] == 'm') {
                    if (std.mem.eql(u8, self.memory[i..(i + 4)], "mul(")) {
                        i += 4;

                        var x: u64 = 0;
                        while (self.memory[i] >= '0' and self.memory[i] <= '9') : (i += 1) {
                            x = x * 10 + self.memory[i] - '0';
                        }

                        if (self.memory[i] != ',') continue;
                        i += 1;

                        var y: u64 = 0;
                        while (self.memory[i] >= '0' and self.memory[i] <= '9') : (i += 1) {
                            y = y * 10 + self.memory[i] - '0';
                        }

                        if (self.memory[i] != ')') continue;

                        result += x * y;
                    }
                }
            }

            return result;
        }
    };
}

pub const title = "Day 03: Mull it Over";

pub fn run(_: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    const input = @embedFile("./data/day03.txt");
    const puzzle = Day03().init(input);
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

const sample_input = "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))";

test "day 03 part 1 sample 1" {
    const puzzle = Day03().init(sample_input);
    const result = puzzle.part1();
    try std.testing.expectEqual(161, result);
}

const sample_input2 = "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))";

test "day 03 part 2 sample 2" {
    const puzzle = Day03().init(sample_input2);
    const result = puzzle.part2();
    try std.testing.expectEqual(48, result);
}
