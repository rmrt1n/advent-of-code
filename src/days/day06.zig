const std = @import("std");

fn Day06(comptime length: usize) type {
    return struct {
        const Self = @This();

        const map_size = length + 2; // Add borders

        map: [map_size][map_size]Tile = .{.{Tile.init(.exit)} ** map_size} ** map_size,
        position: @Vector(2, i16) = undefined,
        direction: Direction = .up,

        fn init(input: []const u8) Self {
            var result = Self{};

            var i: usize = 1;
            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                for (line, 1..) |tile, j| {
                    switch (tile) {
                        '#' => result.map[i][j] = Tile.init(.obstacle),
                        '.' => result.map[i][j] = Tile.init(.path),
                        '^' => {
                            result.map[i][j] = Tile.init(.path);
                            result.position = .{ @intCast(i), @intCast(j) };
                        },
                        else => unreachable,
                    }
                }
            }

            return result;
        }

        fn part1(self: Self) u64 {
            // Copy by value because we still need the original map for part two.
            var simulation = self;
            var result: u64 = 0;

            while (true) {
                switch (simulation.get_tile().type) {
                    .obstacle => {
                        simulation.position -= simulation.direction.vector();
                        simulation.direction = simulation.direction.rotate();
                    },
                    .path => {
                        simulation.set_tile(Tile.init(.visited));
                        result += 1;
                    },
                    .visited => {},
                    .exit => break,
                }
                simulation.position += simulation.direction.vector();
            }

            return result;
        }

        fn part2(self: *Self) u64 {
            var result: u64 = 0;

            self.position += self.direction.vector();

            while (true) {
                switch (self.get_tile().type) {
                    .obstacle => {
                        self.position -= self.direction.vector();
                        self.direction = self.direction.rotate();
                    },
                    .path => {
                        var simulation = self.*;

                        simulation.set_tile(Tile.init(.obstacle));

                        while (true) {
                            const inner_tile = simulation.get_tile();
                            switch (inner_tile.type) {
                                .exit => break,
                                .obstacle => {
                                    simulation.position -= simulation.direction.vector();
                                    simulation.direction = simulation.direction.rotate();
                                },
                                else => {
                                    if (inner_tile.has_visited(simulation.direction)) {
                                        result += 1;
                                        break;
                                    }

                                    simulation.set_tile(inner_tile.visit(simulation.direction));
                                    simulation.position += simulation.direction.vector();
                                },
                            }
                        }
                        self.set_tile(Tile.init(.visited));
                    },
                    .visited => {},
                    .exit => break,
                }
                self.position += self.direction.vector();
            }

            return result;
        }

        fn get_tile(self: Self) Tile {
            return self.map[@intCast(self.position[0])][@intCast(self.position[1])];
        }

        fn set_tile(self: *Self, tile: Tile) void {
            self.map[@intCast(self.position[0])][@intCast(self.position[1])] = tile;
        }
    };
}

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

    // This returns:
    // .up    => 1000
    // .right => 0100
    // .down  => 0010
    // .left  => 0001
    fn mask(direction: Direction) u4 {
        return @as(u4, 1) << @intFromEnum(direction);
    }
};

const Tile = packed struct(u8) {
    const TileType = enum(u4) { obstacle, path, visited, exit };

    up: u1 = 0,
    right: u1 = 0,
    down: u1 = 0,
    left: u1 = 0,
    type: TileType,

    fn init(tile_type: TileType) Tile {
        return Tile{ .type = tile_type };
    }

    fn visit(tile: Tile, direction: Direction) Tile {
        const int_tile = std.mem.nativeToBig(u8, @bitCast(tile));
        const mask = direction.mask();

        var result = @as(Tile, @bitCast(int_tile | mask));
        result.type = .visited;
        return result;
    }

    fn has_visited(tile: Tile, direction: Direction) bool {
        const int_tile = std.mem.nativeToBig(u8, @bitCast(tile));
        const mask = direction.mask();
        const bits = int_tile & 0xff; // Get only the direction bits
        return bits & mask == mask;
    }
};

pub const title = "Day 06: Guard Gallivant";

pub fn run(_: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    const input = @embedFile("./data/day06.txt");
    var puzzle = Day06(130).init(input);
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
    var puzzle = Day06(10).init(sample_input);
    const result = puzzle.part2();
    try std.testing.expectEqual(6, result);
}
