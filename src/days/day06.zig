const std = @import("std");

const Direction = enum {
    up,
    right,
    down,
    left,

    fn vector(direction: Direction) @Vector(2, i8) {
        const directions = [_]@Vector(2, i8){ .{ -1, 0 }, .{ 0, 1 }, .{ 1, 0 }, .{ 0, -1 } };
        return directions[@intFromEnum(direction)];
    }

    fn rotate(direction: Direction) Direction {
        return @enumFromInt((@as(u8, @intFromEnum(direction)) + 1) % 4);
    }

    // This'll return:
    // .up    => 1000
    // .right => 0100
    // .down  => 0010
    // .left  => 0001
    fn mask(direction: Direction) u4 {
        return @as(u4, 1) << @intFromEnum(direction);
    }
};

// Pseudo-enum because enums can't be mutated (in part two).
const obstacle: u8 = 0;
const path: u8 = 1;
const visited: u8 = 2;
const exit: u8 = 3;

fn Day06(comptime length: usize) type {
    return struct {
        map: [length + 2][length + 2]u8 = .{.{exit} ** (length + 2)} ** (length + 2),
        position: @Vector(2, i16) = undefined,
        direction: Direction = .up,

        const Self = @This();

        fn init(input: []const u8) Self {
            var result = Self{};

            var i: usize = 1;
            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                for (line, 1..) |tile, j| {
                    switch (tile) {
                        '#' => result.map[i][j] = obstacle,
                        '.' => result.map[i][j] = path,
                        '^' => {
                            result.map[i][j] = path;
                            result.position = .{ @intCast(i), @intCast(j) };
                        },
                        else => unreachable,
                    }
                }
            }

            return result;
        }

        fn part1(self: Self) u64 {
            var result: u64 = 0;
            var simulation = self; // This is a copy by value
            while (simulation.get_tile() != exit) {
                switch (simulation.get_tile()) {
                    obstacle => {
                        simulation.position -= simulation.direction.vector();
                        simulation.direction = simulation.direction.rotate();
                    },
                    path => {
                        simulation.set_tile(visited);
                        result += 1;
                    },
                    visited => {},
                    else => unreachable,
                }
                simulation.position += simulation.direction.vector();
            }
            return result;
        }

        fn part2(self: Self) u64 {
            var result: u64 = 0;
            var simulation = self;
            while (simulation.get_tile() != exit) {
                switch (simulation.get_tile()) {
                    obstacle => {
                        simulation.position -= simulation.direction.vector();
                        simulation.direction = simulation.direction.rotate();
                    },
                    path => {
                        var time_loop = simulation;
                        time_loop.set_tile(obstacle);

                        // For some reason incrementing `time_loop.position` with a `while (): ()`
                        // causes a 2x slowdown.
                        while (time_loop.get_tile() != exit) {
                            const current = time_loop.get_tile();
                            if (current == obstacle) {
                                time_loop.position -= time_loop.direction.vector();
                                time_loop.direction = time_loop.direction.rotate();
                            } else {
                                const mask = time_loop.direction.mask();
                                if (current >> 4 & mask == mask) {
                                    result += 1;
                                    break;
                                }
                                time_loop.set_tile(current | @as(u8, mask) << 4);
                                time_loop.position += time_loop.direction.vector();
                            }
                        }
                        simulation.set_tile(visited);
                    },
                    visited => {},
                    else => unreachable,
                }
                simulation.position += simulation.direction.vector();
            }
            return result;
        }

        fn get_tile(self: Self) u8 {
            return self.map[@intCast(self.position[0])][@intCast(self.position[1])];
        }

        fn set_tile(self: *Self, tile: u8) void {
            self.map[@intCast(self.position[0])][@intCast(self.position[1])] = tile;
        }
    };
}

pub const title = "Day 06: Guard Gallivant";

pub fn run(_: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    const input = @embedFile("./data/day06.txt");
    const puzzle = Day06(130).init(input);
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
    \\....#.....
    \\.........#
    \\..........
    \\..#.......
    \\.......#..
    \\..........
    \\.#..^.....
    \\........#.
    \\#.........
    \\......#...
;

test "day 06 part 1 sample 1" {
    const puzzle = Day06(10).init(sample_input);
    const result = puzzle.part1();
    try std.testing.expectEqual(41, result);
}

test "day 06 part 2 sample 1" {
    const puzzle = Day06(10).init(sample_input);
    const result = puzzle.part2();
    try std.testing.expectEqual(6, result);
}
