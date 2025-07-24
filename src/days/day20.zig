const std = @import("std");

fn Day20(comptime length: usize) type {
    return struct {
        const Self = @This();

        const directions = [_]@Vector(2, i8){ .{ -1, 0 }, .{ 0, 1 }, .{ 1, 0 }, .{ 0, -1 } };
        const path: u32 = std.math.maxInt(u32);

        map: [length][length]u32 = undefined,
        start: [2]i16 = undefined,
        end: [2]i16 = undefined,

        fn init(data: []const u8) Self {
            var result = Self{};

            var i: usize = 0;
            var lexer = std.mem.tokenizeScalar(u8, data, '\n');
            while (lexer.next()) |line| : (i += 1) {
                for (line, 0..) |c, j| {
                    switch (c) {
                        '#' => result.map[i][j] = '#',
                        '.' => result.map[i][j] = path,
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

        fn count_cheats(self: *Self, cheat_duration: i32, min_time_saved: u32) u64 {
            const track_capacity = 10_000;
            var race_track: [track_capacity][2]i32 = undefined;

            var i: u32 = 0;
            while (!std.mem.eql(i16, &self.start, &self.end)) : (i += 1) {
                for (directions) |direction| {
                    const next = self.start + direction;
                    if (self.get_tile_at(next) == path) {
                        race_track[i] = .{ self.start[0], self.start[1] };
                        self.set_tile_at(self.start, i);
                        self.start = next;
                        break;
                    }
                }
            }
            race_track[i] = .{ self.end[0], self.end[1] };
            self.set_tile_at(self.end, i);

            var result: u64 = 0;
            for (race_track[0..(i + 1)], 0..) |tile, pico_seconds| {
                const tile_x, const tile_y = tile;
                const x_min: usize = @intCast(@max(tile_x - cheat_duration, 0));
                const x_max: usize = @intCast(@min(tile_x + cheat_duration + 1, length));
                const y_min: usize = @intCast(@max(tile_y - cheat_duration, 0));
                const y_max: usize = @intCast(@min(tile_y + cheat_duration + 1, length));

                for (x_min..x_max) |x| {
                    for (y_min..y_max) |y| {
                        const abs_x = @abs(@as(i32, @intCast(x)) - tile_x);
                        const abs_y = @abs(@as(i32, @intCast(y)) - tile_y);

                        const manhattan_distance = abs_x + abs_y;
                        if (manhattan_distance > cheat_duration) continue;

                        const end_tile = self.get_tile_at(.{ @intCast(x), @intCast(y) });
                        if (end_tile != '#') {
                            const peek_time = end_tile;

                            // No use cheating here...
                            if (peek_time <= pico_seconds + manhattan_distance) continue;

                            const time_saved = peek_time - pico_seconds - manhattan_distance;
                            result += @intFromBool(time_saved >= min_time_saved);
                        }
                    }
                }
            }
            return result;
        }

        fn get_tile_at(self: Self, position: [2]i16) u32 {
            return self.map[@intCast(position[0])][@intCast(position[1])];
        }

        fn set_tile_at(self: *Self, position: [2]i16, tile: u32) void {
            self.map[@intCast(position[0])][@intCast(position[1])] = tile;
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
    var x = Day20(15).init(sample_input);
    const result = x.count_cheats(2, 0);
    try std.testing.expectEqual(44, result);
}

test "day 2 part 2" {
    var x = Day20(15).init(sample_input);
    const result = x.count_cheats(20, 50);
    try std.testing.expectEqual(285, result);
}
