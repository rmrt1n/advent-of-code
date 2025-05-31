const std = @import("std");

const Direction = enum {
    up,
    right,
    down,
    left,

    fn vector(direction: Direction) @Vector(2, i8) {
        const directions = [_][2]i8{ .{ -1, 0 }, .{ 0, 1 }, .{ 1, 0 }, .{ 0, -1 } };
        return directions[@intFromEnum(direction)];
    }

    pub fn opposite(direction: Direction) Direction {
        return @enumFromInt((@as(u8, @intFromEnum(direction)) + 2) % 4);
    }
};

fn Day15(length: usize) type {
    return struct {
        simulation1: SimulationPart1(length) = SimulationPart1(length){},
        simulation2: SimulationPart2(length) = SimulationPart2(length){},
        instructions: std.ArrayList(Direction) = undefined,
        allocator: std.mem.Allocator,

        const Self = @This();

        fn init(input: []const u8, allocator: std.mem.Allocator) !Self {
            var result = Self{ .allocator = allocator };
            // Using an array here doesn't speed up parsing a lot, so keep it here for simplicity.
            result.instructions = std.ArrayList(Direction).init(allocator);

            var i: usize = 0;
            var lexer = std.mem.splitScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                if (line.len == 0) break;
                for (line, 0..) |c, j| {
                    result.simulation1.base.map[i][j] = c;
                    const wide_tile = switch (c) {
                        '#' => "##",
                        'O' => "[]",
                        '.', '@' => "..",
                        else => unreachable,
                    };
                    @memcpy(result.simulation2.base.map[i][(2 * j)..(2 * j + 2)], wide_tile);
                    if (c == '@') {
                        result.simulation1.base.map[i][j] = '.';
                        result.simulation1.base.position = .{ @intCast(i), @intCast(j) };
                        result.simulation2.base.position = .{ @intCast(i), @intCast(j * 2) };
                    }
                }
            }

            while (lexer.next()) |line| {
                if (line.len == 0) break;
                for (line) |c| {
                    const dir = switch (c) {
                        '<' => Direction.left,
                        '>' => Direction.right,
                        '^' => Direction.up,
                        'v' => Direction.down,
                        else => unreachable,
                    };
                    try result.instructions.append(dir);
                }
            }

            return result;
        }

        fn deinit(self: Self) void {
            self.instructions.deinit();
        }

        fn part1(self: Self) u64 {
            var simulation = self.simulation1;
            for (self.instructions.items) |direction| {
                simulation.move(direction);
            }
            return simulation.base.get_sum('O');
        }

        fn part2(self: Self) u64 {
            var simulation = self.simulation2;
            for (self.instructions.items) |direction| {
                switch (direction) {
                    .left, .right => simulation.move_horizontal(direction),
                    .up, .down => simulation.move_vertical(direction),
                }
            }
            return simulation.base.get_sum('[');
        }
    };
}

fn SimulationPart1(comptime length: usize) type {
    return struct {
        base: Simulation(length, length) = Simulation(length, length){},

        const Self = @This();

        fn move(self: *Self, direction: Direction) void {
            var simulation = &self.base;
            const original_position = simulation.position;
            simulation.position += direction.vector();
            switch (simulation.get_tile()) {
                '#' => simulation.position -= direction.vector(),
                '.' => {},
                'O' => {
                    var distance: usize = 0;
                    var tile = simulation.get_tile();
                    while (tile == 'O') : (tile = simulation.get_tile()) {
                        distance += 1;
                        simulation.position += direction.vector();
                    }

                    if (tile == '#') {
                        simulation.position = original_position;
                        return;
                    }

                    for (0..distance) |_| {
                        simulation.set_tile(simulation.peek_tile(direction.opposite()));
                        simulation.position -= direction.vector();
                    }
                    simulation.set_tile('.');
                },
                else => unreachable,
            }
        }
    };
}

fn SimulationPart2(comptime length: usize) type {
    return struct {
        base: Simulation(length, length * 2) = Simulation(length, length * 2){},

        const Self = @This();

        fn move_horizontal(self: *Self, direction: Direction) void {
            var simulation = &self.base;
            const original_position = simulation.position;
            simulation.position += direction.vector();
            switch (simulation.get_tile()) {
                '#' => simulation.position -= direction.vector(),
                '.' => {},
                '[', ']' => {
                    var distance: usize = 0;
                    var tile = simulation.get_tile();
                    while (tile == '[' or tile == ']') : (tile = simulation.get_tile()) {
                        distance += 1;
                        simulation.position += direction.vector();
                    }

                    if (tile == '#') {
                        simulation.position = original_position;
                        return;
                    }

                    for (0..distance) |_| {
                        simulation.set_tile(simulation.peek_tile(direction.opposite()));
                        simulation.position -= direction.vector();
                    }
                    simulation.set_tile('.');
                },
                else => unreachable,
            }
        }

        fn move_vertical(self: *Self, direction: Direction) void {
            var simulation = &self.base;
            const original_position = simulation.position;
            simulation.position += direction.vector();
            switch (simulation.get_tile()) {
                '[', ']' => {
                    var queue: [30][2]i16 = undefined;
                    if (simulation.get_tile() == '[') {
                        queue[0] = simulation.position;
                        queue[1] = simulation.position + Direction.right.vector();
                    } else {
                        queue[0] = simulation.position + Direction.left.vector();
                        queue[1] = simulation.position;
                    }

                    var left: usize = 0;
                    var right: usize = 2;
                    while (left < right) : (left += 1) {
                        simulation.position = queue[left];
                        switch (simulation.peek_tile(direction)) {
                            '[' => {
                                const next = simulation.position + direction.vector();
                                queue[right] = next;
                                queue[right + 1] = next + Direction.right.vector();
                                right += 2;
                            },
                            ']' => {
                                const next = simulation.position + direction.vector();
                                if (!std.meta.eql(queue[right - 1], next)) {
                                    queue[right] = next + Direction.left.vector();
                                    queue[right + 1] = next;
                                    right += 2;
                                }
                            },
                            '#' => {
                                simulation.position = original_position;
                                return;
                            },
                            '.' => continue,
                            else => unreachable,
                        }
                    }
                    for (0..right) |i| {
                        simulation.position = queue[right - 1 - i] + direction.vector();
                        simulation.set_tile(simulation.peek_tile(direction.opposite()));
                        simulation.position -= direction.vector();
                        simulation.set_tile('.');
                    }
                    simulation.position = original_position + direction.vector();
                },
                // Other cases just handle like you would in a horizontal movement.
                '#', '.' => {
                    simulation.position -= direction.vector();
                    self.move_horizontal(direction);
                },
                else => unreachable,
            }
        }
    };
}

fn Simulation(comptime rows: usize, comptime columns: usize) type {
    return struct {
        map: [rows][columns]u8 = undefined,
        position: @Vector(2, i16) = undefined,

        const Self = @This();

        fn peek_tile(self: Self, direction: Direction) u8 {
            const next = self.position + direction.vector();
            return self.map[@intCast(next[0])][@intCast(next[1])];
        }

        fn get_tile(self: Self) u8 {
            return self.map[@intCast(self.position[0])][@intCast(self.position[1])];
        }

        fn set_tile(self: *Self, tile: u8) void {
            self.map[@intCast(self.position[0])][@intCast(self.position[1])] = tile;
        }

        fn get_sum(self: Self, box_character: u8) u64 {
            var result: u64 = 0;
            for (self.map, 0..) |line, i| {
                for (line, 0..) |c, j| {
                    if (c == box_character) result += @intCast(i * 100 + j);
                }
            }
            return result;
        }

        fn print(self: Self) void {
            for (self.map, 0..) |line, i| {
                for (line, 0..) |c, j| {
                    if (self.position[0] == i and self.position[1] == j) {
                        std.debug.print("@", .{});
                    } else {
                        std.debug.print("{c}", .{c});
                    }
                }
                std.debug.print("\n", .{});
            }
        }
    };
}

pub const title = "Day 15: Warehouse Woes";

pub fn run(allocator: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    const input = @embedFile("./data/day15.txt");
    const puzzle = try Day15(50).init(input, allocator);
    defer puzzle.deinit();
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
    \\########
    \\#..O.O.#
    \\##@.O..#
    \\#...O..#
    \\#.#.O..#
    \\#...O..#
    \\#......#
    \\########
    \\
    \\<<^^>>>v
    \\v<v>>v<<
;

test "day 15 part 1 sample 1" {
    const puzzle = try Day15(8).init(sample_input, std.testing.allocator);
    defer puzzle.deinit();
    const result = puzzle.part1();
    try std.testing.expectEqual(2028, result);
}

test "day 15 part 2 sample 1" {
    const puzzle = try Day15(8).init(sample_input, std.testing.allocator);
    defer puzzle.deinit();
    const result = puzzle.part2();
    try std.testing.expectEqual(1751, result);
}

const sample_input2 =
    \\##########
    \\#..O..O.O#
    \\#......O.#
    \\#.OO..O.O#
    \\#..O@..O.#
    \\#O#..O...#
    \\#O..O..O.#
    \\#.OO.O.OO#
    \\#....O...#
    \\##########
    \\
    \\<vv>^<v^>v>^vv^v>v<>v^v<v<^vv<<<^><<><>>v<vvv<>^v^>^<<<><<v<<<v^vv^v>^
    \\vvv<<^>^v^^><<>>><>^<<><^vv^^<>vvv<>><^^v>^>vv<>v<<<<v<^v>^<^^>>>^<v<v
    \\><>vv>v^v^<>><>>>><^^>vv>v<^^^>>v^v^<^^>v^^>v^<^v>v<>>v^v^<v>v^^<^^vv<
    \\<<v<^>>^^^^>>>v^<>vvv^><v<<<>^^^vv^<vvv>^>v<^^^^v<>^>vvvv><>>v^<<^^^^^
    \\^><^><>>><>^^<<^^v>>><^<v>^<vv>>v>>>^v><>^v><<<<v>>v<v<v>vvv>^<><<>^><
    \\^>><>^v<><^vvv<^^<><v<<<<<><^v<<<><<<^^<v<^^^><^>>^<v^><<<^>>^v<v^v<v^
    \\>^>>^v>vv>^<<^v<>><<><<v<<v><>v<^vv<<<>^^v^>^^>>><<^v>>v^v><^^>>^<>vv^
    \\<><^^>^^^<><vvvvv^v<v<<>^v<v>v<<^><<><<><<<^^<<<^<<>><<><^^^>^^<>^>v<>
    \\^^>vv<^v^v<vv>^<><v<^v>^^^>>>^^vvv^>vvv<>>>^<^>>>>>^<<^v>^vvv<>^<><<v>
    \\v^^>>><<^^<>>^v^<v^vv<>v^<<>^<^v^v><^<<<><<^<v><v<>vv>>v><v^<vv<>v^<<^
;

test "day 15 part 1 sample 2" {
    const puzzle = try Day15(10).init(sample_input2, std.testing.allocator);
    defer puzzle.deinit();
    const result = puzzle.part1();
    try std.testing.expectEqual(10092, result);
}

test "day 15 part 2 sample 2" {
    const puzzle = try Day15(10).init(sample_input2, std.testing.allocator);
    defer puzzle.deinit();
    const result = puzzle.part2();
    try std.testing.expectEqual(9021, result);
}
