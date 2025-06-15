const std = @import("std");

const directions = [_]@Vector(2, i8){ .{ -1, 0 }, .{ 0, 1 }, .{ 1, 0 }, .{ 0, -1 } };

const path: u32 = std.math.maxInt(u32);
const obstacle: u32 = path - 1;

fn Day20(comptime length: usize) type {
    return struct {
        map: [length][length]u32 = undefined,
        start: [2]i16 = undefined,
        end: [2]i16 = undefined,

        const Self = @This();

        fn init(data: []const u8) Self {
            var result = Self{};

            var i: usize = 0;
            var lexer = std.mem.tokenizeScalar(u8, data, '\n');
            while (lexer.next()) |line| : (i += 1) {
                for (line, 0..) |c, j| {
                    switch (c) {
                        '.' => result.map[i][j] = path,
                        '#' => result.map[i][j] = obstacle,
                        'S' => result.start = .{ @intCast(i), @intCast(j) },
                        'E' => {
                            result.end = .{ @intCast(i), @intCast(j) };
                            result.map[i][j] = path;
                        },
                        else => unreachable,
                    }
                }
            }

            return result;
        }

        fn part1(self: *Self) u64 {
            return self.count_cheats(2, 100);
        }

        fn part2(self: *Self) u64 {
            return self.count_cheats(20, 100);
        }

        fn count_cheats(self: *Self, cheat_duration: i32, min_duration: u32) u32 {
            // My path length is around 9500, so allocate enough space for it.
            var race_track: [10_000][2]i32 = undefined;

            // Get the race path.
            var i: u32 = 0;
            while (!std.mem.eql(i16, &self.start, &self.end)) : (i += 1) {
                for (directions) |direction| {
                    const next = self.start + direction;
                    if (self.map[@intCast(next[0])][@intCast(next[1])] == path) {
                        race_track[i] = .{ self.start[0], self.start[1] };
                        self.map[@intCast(self.start[0])][@intCast(self.start[1])] = i;
                        self.start = next;
                        break;
                    }
                }
            }
            race_track[i] = .{ self.end[0], self.end[1] };
            self.map[@intCast(self.end[0])][@intCast(self.end[1])] = i;

            var frequencies = [_]u32{0} ** 10_000;
            for (race_track, 0..) |tile, seconds| {
                var x = @max(tile[0] - cheat_duration, 0);
                while (x < @min(tile[0] + cheat_duration + 1, length)) : (x += 1) {
                    var y = @max(tile[1] - cheat_duration, 0);
                    while (y < @min(tile[1] + cheat_duration + 1, length)) : (y += 1) {
                        const manhattan_distance = @abs(x - tile[0]) + @abs(y - tile[1]);
                        if (manhattan_distance > cheat_duration) continue;

                        if (self.map[@intCast(x)][@intCast(y)] != obstacle) {
                            const peek_seconds = self.map[@intCast(x)][@intCast(y)];

                            // No use cheating here...
                            if (peek_seconds <= seconds + manhattan_distance) continue;

                            const seconds_saved = peek_seconds - seconds - manhattan_distance;
                            frequencies[seconds_saved] += 1;
                        }
                    }
                }
            }

            var result: u32 = 0;
            for (frequencies[min_duration..]) |count| result += count;
            return result;
        }
    };
}

pub const title = "Day 20: Race Condition";

pub fn run(_: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    const input = @embedFile("./data/day20.txt");
    var data_part1 = Day20(141).init(input);
    var data_part2 = Day20(141).init(input);
    const time0 = timer.read();

    const result1 = data_part1.part1();
    const time1 = timer.read();

    const result2 = data_part2.part2();
    const time2 = timer.read();

    if (is_run) {
        std.debug.print("Part 1: {d}\nPart 2: {d}\n", .{ result1, result2 });
    }

    return .{ time0, time1, time2 };
}

const sample_input =
    \\###############
    \\#...#...#.....#
    \\#.#.#.#.#.###.#
    \\#S#...#.#.#...#
    \\#######.#.#.###
    \\#######.#.#...#
    \\#######.#.###.#
    \\###..E#...#...#
    \\###.#######.###
    \\#...###...#...#
    \\#.#####.#.###.#
    \\#.#...#.#.#...#
    \\#.#.#.#.#.#.###
    \\#...#...#...###
    \\###############
;

test "day 1 part 1" {
    var x = Day20(15).init(sample_input, std.testing.allocator);
    const result = x.count_cheats(2, 0);
    try std.testing.expectEqual(44, result);
}

test "day 2 part 2" {
    var x = Day20(15).init(sample_input, std.testing.allocator);
    const result = x.count_cheats(20, 50);
    try std.testing.expectEqual(285, result);
}
