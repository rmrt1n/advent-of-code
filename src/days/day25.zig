const std = @import("std");

fn Day25() type {
    return struct {
        const Self = @This();

        locks: std.ArrayList(@Vector(5, u8)) = undefined,
        keys: std.ArrayList(@Vector(5, u8)) = undefined,

        fn init(input: []const u8, allocator: std.mem.Allocator) !Self {
            var result = Self{};

            result.locks = std.ArrayList(@Vector(5, u8)).init(allocator);
            result.keys = std.ArrayList(@Vector(5, u8)).init(allocator);

            var lexer = std.mem.tokenizeSequence(u8, input, "\n\n");
            while (lexer.next()) |key_or_lock| {
                var inner_lexer = std.mem.tokenizeScalar(u8, key_or_lock, '\n');

                const first_line = inner_lexer.next().?;
                var list = if (first_line[0] == '#') &result.locks else &result.keys;

                var heights: [5]u8 = .{0} ** 5;
                for (0..5) |_| {
                    for (inner_lexer.next().?, 0..) |pin, i| {
                        heights[i] += @intFromBool(pin == '#');
                    }
                }
                try list.append(heights);
            }

            return result;
        }

        fn deinit(self: Self) void {
            self.locks.deinit();
            self.keys.deinit();
        }

        fn part1(self: Self) u64 {
            var result: u64 = 0;
            for (self.locks.items) |lock| {
                for (self.keys.items) |key| {
                    const fitted = lock + key > @as(@Vector(5, u8), @splat(5));
                    const is_overlap = @reduce(.Or, fitted);
                    result += @intFromBool(!is_overlap);
                }
            }
            return result;
        }

        fn part2(_: Self) u64 {
            return 50;
        }
    };
}

pub const title = "Day 25: Code Chronicle";

pub fn run(allocator: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    const input = @embedFile("./data/day25.txt");
    const puzzle = try Day25().init(input, allocator);
    const time0 = timer.read();

    const result1 = puzzle.part1();
    defer puzzle.deinit();
    const time1 = timer.read();

    const result2 = puzzle.part2();
    const time2 = timer.read();

    if (is_run) {
        std.debug.print("Part 1: {d}\nPart 2: {d}\n", .{ result1, result2 });
    }

    return .{ time0, time1, time2 };
}

const sample_input =
    \\#####
    \\.####
    \\.####
    \\.####
    \\.#.#.
    \\.#...
    \\.....
    \\
    \\#####
    \\##.##
    \\.#.##
    \\...##
    \\...#.
    \\...#.
    \\.....
    \\
    \\.....
    \\#....
    \\#....
    \\#...#
    \\#.#.#
    \\#.###
    \\#####
    \\
    \\.....
    \\.....
    \\#.#..
    \\###..
    \\###.#
    \\###.#
    \\#####
    \\
    \\.....
    \\.....
    \\.....
    \\#....
    \\#.#..
    \\#.#.#
    \\#####
;

test "day 25 part 1 sample 1" {
    const puzzle = try Day25().init(sample_input, std.testing.allocator);
    defer puzzle.deinit();
    const result = puzzle.part1();
    try std.testing.expectEqual(3, result);
}
