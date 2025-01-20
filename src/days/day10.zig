const std = @import("std");

const directions = [_]@Vector(2, u1){ .{ 1, 0 }, .{ 0, 1 } };

fn Day10(length: usize) type {
    return struct {
        map: [length + 2][length + 2]u8 = .{.{10} ** (length + 2)} ** (length + 2),
        starts: std.ArrayList([2]u8) = undefined,
        allocator: std.mem.Allocator,

        const Self = @This();

        fn init(input: []const u8, allocator: std.mem.Allocator) !Self {
            var result = Self{ .allocator = allocator };

            result.starts = std.ArrayList([2]u8).init(allocator);

            var i: usize = 1;
            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                for (line, 1..) |c, j| {
                    const height = c - '0';
                    if (height == 0) try result.starts.append(.{ @intCast(i), @intCast(j) });
                    result.map[i][j] = height;
                }
            }

            return result;
        }

        fn deinit(self: Self) void {
            self.starts.deinit();
        }

        const StackItem = struct { position: [2]u8, previous: i8 };

        // Iterative solution is a 14x speed increase than recursive.
        fn part1(self: Self) !u64 {
            var result: u64 = 0;
            for (self.starts.items) |point| {
                var stack: [30]StackItem = undefined;
                stack[0] = .{ .position = point, .previous = -1 };

                var trail_ends = std.AutoHashMap([2]u8, void).init(self.allocator);
                defer trail_ends.deinit();

                var stack_length: usize = 1;
                while (stack_length > 0) {
                    stack_length -= 1;
                    const position = stack[stack_length].position;
                    const previous = stack[stack_length].previous;

                    const current: i8 = @intCast(self.map[position[0]][position[1]]);

                    if (current == 10 or current - previous != 1) continue;

                    if (current == 9) {
                        try trail_ends.put(position, {});
                        continue;
                    }

                    for (directions) |direction| {
                        stack[stack_length] = .{
                            .position = position + direction,
                            .previous = previous + 1,
                        };
                        stack[stack_length + 1] = .{
                            .position = position - direction,
                            .previous = previous + 1,
                        };
                        stack_length += 2;
                    }
                }
                result += trail_ends.count();
            }
            return result;
        }

        fn part2(self: Self) !u64 {
            var result: u32 = 0;
            for (self.starts.items) |point| {
                // 3x faster than using an ArrayList.
                var stack: [30]StackItem = undefined;
                stack[0] = .{ .position = point, .previous = -1 };

                var stack_length: usize = 1;
                while (stack_length > 0) {
                    stack_length -= 1;
                    const position = stack[stack_length].position;
                    const previous = stack[stack_length].previous;

                    const current: i8 = @intCast(self.map[position[0]][position[1]]);

                    if (current == 10 or current - previous != 1) continue;

                    if (current == 9) {
                        result += 1;
                        continue;
                    }

                    for (directions) |direction| {
                        stack[stack_length] = .{
                            .position = position + direction,
                            .previous = previous + 1,
                        };
                        stack[stack_length + 1] = .{
                            .position = position - direction,
                            .previous = previous + 1,
                        };
                        stack_length += 2;
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

    const result2 = try puzzle.part2();
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
    const result = try puzzle.part2();
    try std.testing.expectEqual(81, result);
}
