const std = @import("std");

fn Day02(comptime length: usize) type {
    return struct {
        reports: [length][10]u8 = undefined,

        const Self = @This();

        fn init(input: []const u8) !Self {
            var result = Self{};

            var i: usize = 0;
            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                var j: usize = 1;
                var inner_lexer = std.mem.tokenizeScalar(u8, line, ' ');
                while (inner_lexer.next()) |number| : (j += 1) {
                    result.reports[i][j] = try std.fmt.parseInt(u8, number, 10);
                }
                result.reports[i][0] = @intCast(j - 1);
            }

            return result;
        }

        fn part1(self: Self) u64 {
            var result: u64 = 0;
            for (self.reports) |report| {
                result += @intFromBool(is_valid_report(&report));
            }
            return result;
        }

        fn part2(self: Self) u64 {
            var result: u64 = 0;
            for (self.reports) |report| {
                if (is_valid_report(&report)) {
                    result += 1;
                    continue;
                }
                for (1..(report[0] + 1)) |i| {
                    var dampened = report;
                    dampened[0] -= 1;
                    @memcpy(dampened[i..9], report[(i + 1)..]);

                    if (is_valid_report(&dampened)) {
                        result += 1;
                        break;
                    }
                }
            }
            return result;
        }

        fn is_valid_report(report: []const u8) bool {
            const is_increasing = report[1] < report[2];
            for (1..(report[0])) |i| {
                const larger = if (is_increasing) report[i + 1] else report[i];
                const lesser = if (is_increasing) report[i] else report[i + 1];

                const diff = @as(i16, larger) - lesser;
                if (diff < 1 or diff > 3) return false;
            }
            return true;
        }
    };
}

pub const title = "Day 02: Red-Nosed Reports";

pub fn run(_: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    const input = @embedFile("./data/day02.txt");
    const puzzle = try Day02(1000).init(input);
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
    \\7 6 4 2 1
    \\1 2 7 8 9
    \\9 7 6 2 1
    \\1 3 2 4 5
    \\8 6 4 4 1
    \\1 3 6 7 9
;

test "day 02 part 1 sample 1" {
    const puzzle = try Day02(6).init(sample_input);
    const result = puzzle.part1();
    try std.testing.expectEqual(2, result);
}

test "day 02 part 2 sample 1" {
    const puzzle = try Day02(6).init(sample_input);
    const result = puzzle.part2();
    try std.testing.expectEqual(4, result);
}
