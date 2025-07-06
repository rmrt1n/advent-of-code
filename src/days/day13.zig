const std = @import("std");

fn Day13(length: usize) type {
    return struct {
        const Self = @This();

        buttons_a: [length][2]u8 = undefined,
        buttons_b: [length][2]u8 = undefined,
        prizes: [length][2]i64 = undefined,

        fn init(input: []const u8) !Self {
            var result = Self{};

            var i: usize = 0;
            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                result.buttons_a[i][0] = try std.fmt.parseInt(u8, line[12..14], 10);
                result.buttons_a[i][1] = try std.fmt.parseInt(u8, line[18..], 10);

                var new_line = lexer.next().?;
                result.buttons_b[i][0] = try std.fmt.parseInt(u8, new_line[12..14], 10);
                result.buttons_b[i][1] = try std.fmt.parseInt(u8, new_line[18..], 10);

                new_line = lexer.next().?;
                var inner_lexer = std.mem.tokenizeScalar(u8, new_line, ' ');
                _ = inner_lexer.next().?; // Skip 'Prize: '

                new_line = inner_lexer.next().?;
                result.prizes[i][0] = try std.fmt.parseInt(i64, new_line[2 .. new_line.len - 1], 10);

                new_line = inner_lexer.next().?;
                result.prizes[i][1] = try std.fmt.parseInt(i64, new_line[2..new_line.len], 10);
            }

            return result;
        }

        fn part1(self: Self) u64 {
            var result: usize = 0;
            for (self.buttons_a, self.buttons_b, self.prizes) |button_a, button_b, prize| {
                const tokens_a = count_tokens(button_a, button_b, prize);
                const tokens_b = count_tokens(button_b, button_a, prize);
                if (tokens_a == null or tokens_b == null) continue;
                result += tokens_a.? * 3 + tokens_b.?;
            }
            return result;
        }

        fn part2(self: Self) u64 {
            var result: u64 = 0;
            for (self.buttons_a, self.buttons_b, self.prizes) |button_a, button_b, old_prize| {
                const prize = .{ old_prize[0] + 10_000_000_000_000, old_prize[1] + 10_000_000_000_000 };
                const tokens_a = count_tokens(button_a, button_b, prize);
                const tokens_b = count_tokens(button_b, button_a, prize);
                if (tokens_a == null or tokens_b == null) continue;
                result += tokens_a.? * 3 + tokens_b.?;
            }
            return result;
        }

        fn count_tokens(a: [2]u8, b: [2]u8, p: [2]i64) ?u64 {
            const numerator = @abs(p[0] * b[1] - p[1] * b[0]);
            const denumerator = @abs(@as(i32, a[0]) * b[1] - @as(i32, a[1]) * b[0]);
            return if (numerator % denumerator != 0) null else numerator / denumerator;
        }
    };
}

pub const title = "Day 13: Claw Contraption";

pub fn run(_: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    const input = @embedFile("./data/day13.txt");
    const puzzle = try Day13(320).init(input);
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
    \\Button A: X+94, Y+34
    \\Button B: X+22, Y+67
    \\Prize: X=8400, Y=5400
    \\
    \\Button A: X+26, Y+66
    \\Button B: X+67, Y+21
    \\Prize: X=12748, Y=12176
    \\
    \\Button A: X+17, Y+86
    \\Button B: X+84, Y+37
    \\Prize: X=7870, Y=6450
    \\
    \\Button A: X+69, Y+23
    \\Button B: X+27, Y+71
    \\Prize: X=18641, Y=10279
;

test "day 13 part 1 sample 1" {
    const puzzle = try Day13(4).init(sample_input);
    const result = puzzle.part1();
    try std.testing.expectEqual(480, result);
}

test "day 13 part 2 sample 1" {
    const puzzle = try Day13(4).init(sample_input);
    const result = puzzle.part2();
    try std.testing.expectEqual(875318608908, result);
}
