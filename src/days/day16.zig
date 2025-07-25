const std = @import("std");

fn Day16(length: usize) type {
    return struct {
        const Self = @This();

        map: [length][length]u8 = undefined,
        start: [2]i16 = undefined,
        end: [2]i16 = undefined,
        allocator: std.mem.Allocator,

        fn init(input: []const u8, allocator: std.mem.Allocator) Self {
            var result = Self{ .allocator = allocator };

            var i: usize = 0;
            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                for (line, 0..) |tile, j| {
                    switch (tile) {
                        '#', '.' => result.map[i][j] = tile,
                        'S' => {
                            result.map[i][j] = '.';
                            result.start = .{ @intCast(i), @intCast(j) };
                        },
                        'E' => {
                            result.map[i][j] = tile;
                            result.end = .{ @intCast(i), @intCast(j) };
                        },
                        else => unreachable,
                    }
                }
            }

            return result;
        }

        fn part1(self: Self) !u64 {
            var simulation = self;
            var visited = VisitedSet(length){};

            var queue = std.PriorityQueue(Step1, void, Step1.compare).init(self.allocator, {});
            defer queue.deinit();

            try queue.add(Step1{
                .position = simulation.start,
                .direction = .right,
                .score = 0,
            });

            return while (queue.count() > 0) {
                const step = queue.remove();

                const tile = simulation.get_tile_at(step.position);
                if (tile == 'E') break step.score;

                visited.set(step.position, step.direction, step.score);

                // The more we skip adding to the queue, the less allocations we do.
                for ([_]Direction{ .up, .right, .down, .left }) |direction| {
                    if (direction == step.direction.opposite()) continue;

                    const next = step.position + direction.vector();
                    if (simulation.get_tile_at(next) == '#') continue;

                    const increment: u32 = if (direction == step.direction) 1 else 1001;
                    const next_score = step.score + increment;

                    if (visited.get(next, direction) < next_score) continue;

                    try queue.add(Step1{
                        .position = next,
                        .direction = direction,
                        .score = next_score,
                    });
                }
            } else unreachable;
        }

        fn part2(self: Self) !u64 {
            var simulation = self;
            var visited = VisitedSet(length){};

            var queue = std.PriorityQueue(Step2, void, Step2.compare).init(self.allocator, {});
            defer queue.deinit();

            var first_step = Step2{
                .position = simulation.start,
                .direction = .right,
                .score = 0,
                .path = std.ArrayList([2]i16).init(self.allocator),
            };
            try first_step.path.append(self.start);
            try queue.add(first_step);

            var best_score: ?u64 = null;
            var result_set = std.AutoHashMap([2]i16, void).init(self.allocator);
            defer result_set.deinit();

            while (queue.count() > 0) {
                const step = queue.remove();
                defer step.path.deinit();

                const tile = simulation.get_tile_at(step.position);
                if (tile == 'E') {
                    if (best_score == null) {
                        best_score = step.score; // This is guaranteed to be the best score.
                    }
                    if (step.score == best_score) {
                        // Add all tiles that lead to the best score.
                        for (step.path.items) |item| try result_set.put(item, {});
                    }
                    continue;
                }

                visited.set(step.position, step.direction, step.score);

                // The more we skip adding to the queue, the less allocations we do.
                for ([_]Direction{ .up, .right, .down, .left }) |direction| {
                    if (direction == step.direction.opposite()) continue;

                    const next = step.position + direction.vector();
                    if (simulation.get_tile_at(next) == '#') continue;

                    const increment: u32 = if (direction == step.direction) 1 else 1001;
                    const next_score = step.score + increment;

                    if (visited.get(next, direction) < next_score) continue;

                    var new_step = Step2{
                        .position = next,
                        .direction = direction,
                        .score = next_score,
                        .path = try step.path.clone(),
                    };
                    try new_step.path.append(next);
                    try queue.add(new_step);
                }
            }

            return result_set.count();
        }

        fn get_tile_at(self: Self, position: [2]i16) u8 {
            return self.map[@intCast(position[0])][@intCast(position[1])];
        }
    };
}

fn VisitedSet(comptime length: usize) type {
    return struct {
        const Self = @This();

        map: [length][length][4]u32 = .{.{.{std.math.maxInt(u32)} ** 4} ** length} ** length,

        fn get(self: Self, position: [2]i16, direction: Direction) u32 {
            return self.map[@intCast(position[0])][@intCast(position[1])][@intFromEnum(direction)];
        }

        fn set(self: *Self, position: [2]i16, direction: Direction, score: u32) void {
            self.map[@intCast(position[0])][@intCast(position[1])][@intFromEnum(direction)] = score;
        }
    };
}

const Step1 = struct {
    position: [2]i16,
    direction: Direction,
    score: u32,

    fn compare(_: void, a: Step1, b: Step1) std.math.Order {
        return std.math.order(a.score, b.score);
    }
};

const Step2 = struct {
    position: [2]i16,
    direction: Direction,
    score: u32,
    path: std.ArrayList([2]i16),

    fn compare(_: void, a: Step2, b: Step2) std.math.Order {
        return std.math.order(a.score, b.score);
    }
};

const Direction = enum {
    up,
    right,
    down,
    left,

    fn vector(direction: Direction) @Vector(2, i8) {
        const directions = [_]@Vector(2, i8){ .{ -1, 0 }, .{ 0, 1 }, .{ 1, 0 }, .{ 0, -1 } };
        return directions[@intFromEnum(direction)];
    }

    fn opposite(direction: Direction) Direction {
        return @enumFromInt((@as(u8, @intFromEnum(direction)) + 2) % 4);
    }
};

pub const title = "Day 16: Reindeer Maze";

pub fn run(allocator: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    const input = @embedFile("./data/day16.txt");
    const puzzle = Day16(141).init(input, allocator);
    const time0 = timer.read();

    const result1 = try puzzle.part1();
    const time1 = timer.read();

    const result2 = try puzzle.part2();
    const time2 = timer.read();

    if (is_run) {
        std.debug.print("Part 1: {d}\nPart 2: {d}\n", .{ result1, result2 });
    }

    return .{ time0, time1, time2 };
}

const sample_input =
    \\###############
    \\#.......#....E#
    \\#.#.###.#.###.#
    \\#.....#.#...#.#
    \\#.###.#####.#.#
    \\#.#.#.......#.#
    \\#.#.#####.###.#
    \\#...........#.#
    \\###.#.#####.#.#
    \\#...#.....#.#.#
    \\#.#.#.###.#.#.#
    \\#.....#...#.#.#
    \\#.###.#.#.#.#.#
    \\#S..#.....#...#
    \\###############
;

test "day 16 part 1 sample 1" {
    const puzzle = Day16(15).init(sample_input, std.testing.allocator);
    const result = puzzle.part1();
    try std.testing.expectEqual(7036, result);
}

test "day 16 part 2 sample 1" {
    const puzzle = Day16(15).init(sample_input, std.testing.allocator);
    const result = puzzle.part2();
    try std.testing.expectEqual(45, result);
}

const sample_input2 =
    \\#################
    \\#...#...#...#..E#
    \\#.#.#.#.#.#.#.#.#
    \\#.#.#.#...#...#.#
    \\#.#.#.#.###.#.#.#
    \\#...#.#.#.....#.#
    \\#.#.#.#.#.#####.#
    \\#.#...#.#.#.....#
    \\#.#.#####.#.###.#
    \\#.#.#.......#...#
    \\#.#.###.#####.###
    \\#.#.#...#.....#.#
    \\#.#.#.#####.###.#
    \\#.#.#.........#.#
    \\#.#.#.#########.#
    \\#S#.............#
    \\#################
;

test "day 16 part 1 sample 2" {
    const puzzle = Day16(17).init(sample_input2, std.testing.allocator);
    const result = puzzle.part1();
    try std.testing.expectEqual(11048, result);
}

test "day 16 part 2 sample 2" {
    const puzzle = Day16(17).init(sample_input2, std.testing.allocator);
    const result = puzzle.part2();
    try std.testing.expectEqual(64, result);
}
