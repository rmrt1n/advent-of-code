const std = @import("std");

fn Day12(length: usize) type {
    return struct {
        const Self = @This();

        const map_size = length + 2; // Add borders
        const stack_capacity = 1024;

        // Borders are 26 because the minimum is the next character after 'Z' - 'A' (25).
        garden: [map_size][map_size]u8 = .{.{26} ** map_size} ** map_size,

        fn init(input: []const u8) Self {
            var result = Self{};

            var i: usize = 1;
            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                @memcpy(result.garden[i][1..(length + 1)], line);
            }

            return result;
        }

        fn part1(self: Self) u64 {
            // Copy by value because we still need the original map for part two.
            var copy = self;
            var result: u64 = 0;
            var stack: [stack_capacity][2]i16 = undefined;

            for (copy.garden[1..(map_size - 1)], 1..) |row, i| {
                for (row[1..(map_size - 1)], 1..) |plant, j| {
                    if (plant < 'A') continue;

                    var area: u64 = 0;
                    var perimeter: u64 = 0;

                    stack[0] = .{ @intCast(i), @intCast(j) };

                    var stack_length: usize = 1;
                    while (stack_length > 0) {
                        stack_length -= 1;

                        const position = stack[stack_length];
                        const tile = copy.get_tile_at(position);

                        if (tile == plant - 'A') continue;
                        if (tile != plant) {
                            perimeter += 1;
                            continue;
                        }

                        copy.set_tile_at(position, plant - 'A');
                        area += 1;

                        for ([_]Direction{ .up, .right, .down, .left }) |direction| {
                            stack[stack_length] = position + direction.vector();
                            stack_length += 1;
                        }
                    }

                    result += area * perimeter;
                }
            }

            return result;
        }

        fn part2(self: *Self) u64 {
            var result: u64 = 0;
            var stack: [stack_capacity]struct { position: [2]i16, direction: Direction } = undefined;

            for (self.garden[1..(map_size - 1)], 1..) |row, i| {
                for (row[1..(map_size - 1)], 1..) |plant, j| {
                    if (plant < 'A') continue;

                    var area: u64 = 0;
                    var sides: u64 = 0;

                    stack[0] = .{ .position = .{ @intCast(i), @intCast(j) }, .direction = .up };

                    var stack_length: usize = 1;
                    while (stack_length > 0) {
                        stack_length -= 1;

                        const current = stack[stack_length];
                        const tile = self.get_tile_at(current.position);

                        if (tile == plant - 'A') continue;
                        if (tile != plant) {
                            const turn1 = current.position + current.direction.rotate().vector();
                            const turn2 = turn1 - current.direction.vector();
                            const top_right = self.get_tile_at(turn1);
                            const right = self.get_tile_at(turn2);

                            if ((top_right == plant or top_right == plant - 'A') or
                                (right != plant and right != plant - 'A'))
                            {
                                sides += 1;
                            }
                            continue;
                        }

                        self.set_tile_at(current.position, tile - 'A');
                        area += 1;

                        for ([_]Direction{ .up, .right, .down, .left }) |direction| {
                            stack[stack_length] = .{
                                .position = current.position + direction.vector(),
                                .direction = direction,
                            };
                            stack_length += 1;
                        }
                    }
                    result += area * sides;
                }
            }
            return result;
        }

        fn get_tile_at(self: Self, position: [2]i16) u8 {
            return self.garden[@intCast(position[0])][@intCast(position[1])];
        }

        fn set_tile_at(self: *Self, position: [2]i16, tile: u8) void {
            self.garden[@intCast(position[0])][@intCast(position[1])] = tile;
        }
    };
}

const Direction = enum {
    up,
    right,
    down,
    left,

    fn vector(direction: Direction) @Vector(2, i8) {
        const directions = [_][2]i8{ .{ -1, 0 }, .{ 0, 1 }, .{ 1, 0 }, .{ 0, -1 } };
        return directions[@intFromEnum(direction)];
    }

    fn rotate(direction: Direction) Direction {
        return @enumFromInt((@as(u8, @intFromEnum(direction)) + 1) % 4);
    }
};

pub const title = "Day 12: Garden Groups";

pub fn run(_: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    const input = @embedFile("./data/day12.txt");
    var puzzle = Day12(140).init(input);
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
    \\AAAA
    \\BBCD
    \\BBCC
    \\EEEC
;

test "day 12 part 1 sample 1" {
    const puzzle = Day12(4).init(sample_input);
    const result = puzzle.part1();
    try std.testing.expectEqual(140, result);
}

test "day 12 part 2 sample 1" {
    const puzzle = Day12(4).init(sample_input);
    const result = puzzle.part2();
    try std.testing.expectEqual(80, result);
}

const sample_input2 =
    \\RRRRIICCFF
    \\RRRRIICCCF
    \\VVRRRCCFFF
    \\VVRCCCJFFF
    \\VVVVCJJCFE
    \\VVIVCCJJEE
    \\VVIIICJJEE
    \\MIIIIIJJEE
    \\MIIISIJEEE
    \\MMMISSJEEE
;

test "day 12 part 1 sample 2" {
    const puzzle = Day12(10).init(sample_input2);
    const result = puzzle.part1();
    try std.testing.expectEqual(1930, result);
}

test "day 12 part 2 sample 2" {
    const puzzle = Day12(10).init(sample_input2);
    const result = puzzle.part2();
    try std.testing.expectEqual(1206, result);
}
