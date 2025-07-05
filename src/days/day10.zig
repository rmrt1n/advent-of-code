const std = @import("std");

fn Day10(length: usize) type {
    return struct {
        const Self = @This();

        const map_size = length + 2; // Add borders
        const directions = [_]@Vector(2, u1){ .{ 1, 0 }, .{ 0, 1 } };
        const stack_capacity = 544;

        map: [map_size][map_size]u8 = .{.{10} ** map_size} ** map_size,
        trail_heads: std.ArrayList([2]u8) = undefined,
        allocator: std.mem.Allocator,

        fn init(input: []const u8, allocator: std.mem.Allocator) !Self {
            var result = Self{ .allocator = allocator };

            result.trail_heads = std.ArrayList([2]u8).init(allocator);

            var i: usize = 1;
            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                for (line, 1..) |c, j| {
                    const height = c - '0';
                    if (height == 0) try result.trail_heads.append(.{ @intCast(i), @intCast(j) });
                    result.map[i][j] = height;
                }
            }

            return result;
        }

        fn deinit(self: Self) void {
            self.trail_heads.deinit();
        }

        // Iterative solution is much faster than recursive.
        fn part1(self: Self) !u64 {
            var result: u64 = 0;
            var stack: [stack_capacity][2]u8 = undefined;

            var trail_ends = std.AutoHashMap([2]u8, void).init(self.allocator);
            defer trail_ends.deinit();

            for (self.trail_heads.items) |trail_head| {
                stack[0] = trail_head;
                trail_ends.clearRetainingCapacity();

                var stack_length: usize = 1;
                while (stack_length > 0) {
                    stack_length -= 1;

                    const position = stack[stack_length];
                    const tile = self.map[position[0]][position[1]];

                    // Duplicating the code here results in much faster runtime vs using 4 i8
                    // direction vectors. I'm not completely sure why, but I'll take this extra
                    // code verbosity for the increased performance.
                    for (directions) |direction| {
                        const forwards = position + direction;
                        var next_tile = self.map[forwards[0]][forwards[1]];
                        if (next_tile != 10 and next_tile - tile == 1) {
                            if (next_tile == 9) {
                                try trail_ends.put(forwards, {});
                            } else {
                                stack[stack_length] = forwards;
                                stack_length += 1;
                            }
                        }

                        const backwards = position - direction;
                        next_tile = self.map[backwards[0]][backwards[1]];
                        if (next_tile != 10 and next_tile - tile == 1) {
                            if (next_tile == 9) {
                                try trail_ends.put(backwards, {});
                            } else {
                                stack[stack_length] = backwards;
                                stack_length += 1;
                            }
                        }
                    }
                }

                result += trail_ends.count();
            }

            return result;
        }

        fn part2(self: Self) u64 {
            var result: u32 = 0;
            var stack: [stack_capacity][2]u8 = undefined;

            for (self.trail_heads.items) |trail_head| {
                stack[0] = trail_head;

                var stack_length: usize = 1;
                while (stack_length > 0) {
                    stack_length -= 1;

                    const position = stack[stack_length];
                    const tile = self.map[position[0]][position[1]];

                    for (directions) |direction| {
                        const forwards = position + direction;
                        var next_tile = self.map[forwards[0]][forwards[1]];
                        if (next_tile != 10 and next_tile - tile == 1) {
                            if (next_tile == 9) {
                                result += 1;
                            } else {
                                stack[stack_length] = forwards;
                                stack_length += 1;
                            }
                        }

                        const backwards = position - direction;
                        next_tile = self.map[backwards[0]][backwards[1]];
                        if (next_tile != 10 and next_tile - tile == 1) {
                            if (next_tile == 9) {
                                result += 1;
                            } else {
                                stack[stack_length] = backwards;
                                stack_length += 1;
                            }
                        }
                    }
                }
            }

            return result;
        }
    };
}

pub const title = "Day 10: Hoof It";

pub fn run(allocator: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    const input = @embedFile("./data/day10.txt");
    const puzzle = try Day10(55).init(input, allocator);
    defer puzzle.deinit();
    const time0 = timer.read();

    const result1 = try puzzle.part1();
    const time1 = timer.read();

    const result2 = puzzle.part2();
    const time2 = timer.read();

    if (is_run) {
        std.debug.print("Part 1: {d}\nPart 2: {d}\n", .{ result1, result2 });
    }

    return .{ time0, time1, time2 };
}

const sample_input =
    \\89010123
    \\78121874
    \\87430965
    \\96549874
    \\45678903
    \\32019012
    \\01329801
    \\10456732
;

test "day 10 part 1 sample 1" {
    const puzzle = try Day10(8).init(sample_input, std.testing.allocator);
    defer puzzle.deinit();
    const result = try puzzle.part1();
    try std.testing.expectEqual(36, result);
}

test "day 10 part 2 sample 1" {
    const puzzle = try Day10(8).init(sample_input, std.testing.allocator);
    defer puzzle.deinit();
    const result = puzzle.part2();
    try std.testing.expectEqual(81, result);
}
