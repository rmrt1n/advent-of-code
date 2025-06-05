const std = @import("std");

fn Day01(comptime length: usize) type {
    return struct {
        left: [length]u32 = undefined,
        right: [length]u32 = undefined,

        const Self = @This();

        fn init(input: []const u8) !Self {
            var result = Self{};

            var i: usize = 0;
            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                var inner_lexer = std.mem.tokenizeScalar(u8, line, ' ');
                result.left[i] = try std.fmt.parseInt(u32, inner_lexer.next().?, 10);
                result.right[i] = try std.fmt.parseInt(u32, inner_lexer.next().?, 10);
            }

            return result;
        }

        fn part1(self: Self) u64 {
            var sorted = self;
            std.mem.sort(u32, &sorted.left, {}, std.sort.asc(u32));
            std.mem.sort(u32, &sorted.right, {}, std.sort.asc(u32));

            var result: u64 = 0;
            for (sorted.left, sorted.right) |x, y| {
                result += @abs(@as(i64, x) - y);
            }
            return result;
        }

        fn part2(self: Self) u64 {
            var frequencies = [_]u8{0} ** 100_000;
            for (self.right) |id| frequencies[id] += 1;

            var result: u64 = 0;
            for (self.left) |id| {
                result += id * frequencies[id];
            }
            return result;
        }
    };
}

pub const title = "Day 01: Historian Hysteria";

pub fn run(_: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    const input = @embedFile("./data/day01.txt");
    var puzzle = try Day01(1000).init(input);
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
    \\3   4
    \\4   3
    \\2   5
    \\1   3
    \\3   9
    \\3   3
;

test "day 01 part 1 sample 1" {
    var puzzle = try Day01(6).init(sample_input);
    const result = puzzle.part1();
    try std.testing.expectEqual(11, result);
}

test "day 01 part 2 sample 1" {
    const puzzle = try Day01(6).init(sample_input);
    const result = puzzle.part2();
    try std.testing.expectEqual(31, result);
}
