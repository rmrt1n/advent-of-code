const std = @import("std");

const directions = [_]@Vector(2, i8){ .{ -1, 0 }, .{ 0, 1 }, .{ 1, 0 }, .{ 0, -1 } };

fn Day18(length: usize) type {
    return struct {
        bytes: [length][2]usize = undefined,
        allocator: std.mem.Allocator,

        const Self = @This();

        fn init(input: []const u8, allocator: std.mem.Allocator) !Self {
            var result = Self{ .allocator = allocator };

            var i: usize = 0;
            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                var inner_lexer = std.mem.tokenizeScalar(u8, line, ',');
                const y = try std.fmt.parseInt(usize, inner_lexer.next().?, 10);
                const x = try std.fmt.parseInt(usize, inner_lexer.next().?, 10);
                result.bytes[i] = .{ x, y };
            }

            return result;
        }

        fn part1(self: Self, comptime map_size: usize, n_bytes: usize) !u64 {
            var map: [map_size + 2][map_size + 2]u8 = undefined;

            @memset(map[1..(map_size + 1)], .{'#'} ++ (.{'.'} ** map_size) ++ .{'#'});
            @memset(&map[0], '#');
            @memset(&map[map_size + 1], '#');

            for (0..n_bytes) |i| {
                const coordinate = self.bytes[i] + @Vector(2, usize){ 1, 1 };
                map[coordinate[0]][coordinate[1]] = '#';
            }

            var result: u64 = std.math.maxInt(u64);

            var queue = std.ArrayList(Point).init(self.allocator);
            defer queue.deinit();

            try queue.append(.{ .pos = .{ 1, 1 }, .steps = 0 });

            const end = [_]i16{ map_size, map_size };
            while (queue.items.len > 0) {
                const current = queue.pop().?;
                if (std.mem.eql(i16, &current.pos, &end)) {
                    if (current.steps < result) result = current.steps;
                    continue;
                }

                if (map[@intCast(current.pos[0])][@intCast(current.pos[1])] == 'X') continue;

                map[@intCast(current.pos[0])][@intCast(current.pos[1])] = 'X';

                for (directions) |direction| {
                    const next = current.pos + direction;
                    if (map[@intCast(next[0])][@intCast(next[1])] == '#') continue;
                    try queue.append(.{ .pos = next, .steps = current.steps + 1 });
                }
            }

            return result;
        }

        const Point = struct {
            pos: [2]i16,
            steps: u32,
        };

        fn part2(self: Self, comptime map_size: usize, n_bytes: usize) ![2]u64 {
            var left = n_bytes;
            var right = self.bytes.len;

            while (left < right) {
                const mid = left + (right - left) / 2;
                const result = try self.part1(map_size, mid);
                if (result == std.math.maxInt(u64)) {
                    right = mid;
                } else {
                    left = mid + 1;
                }
            }

            // No need to handle edge cases here as we're guaranteed a solution.

            return .{ self.bytes[left - 1][1], self.bytes[left - 1][0] };
        }
    };
}

pub const title = "Day 18: RAM Run";

pub fn run(allocator: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    const input = @embedFile("./data/day18.txt");
    const puzzle = try Day18(3450).init(input, allocator);
    const time0 = timer.read();

    const result1 = try puzzle.part1(71, 1024);
    const time1 = timer.read();

    const result2 = try puzzle.part2(71, 1025);
    const time2 = timer.read();

    if (is_run) {
        std.debug.print("Part 1: {d}\nPart 2: {d},{d}\n", .{ result1, result2[0], result2[1] });
    }

    return .{ time0, time1, time2 };
}

const sample_input =
    \\5,4
    \\4,2
    \\4,5
    \\3,0
    \\2,1
    \\6,3
    \\2,4
    \\1,5
    \\0,6
    \\3,3
    \\2,6
    \\5,1
    \\1,2
    \\5,5
    \\2,5
    \\6,5
    \\1,4
    \\0,4
    \\6,4
    \\1,1
    \\6,1
    \\1,0
    \\0,5
    \\1,6
    \\2,0
;

test "day 18 part 1 sample 1" {
    const puzzle = try Day18(25).init(sample_input, std.testing.allocator);
    const result = try puzzle.part1(7, 12);
    try std.testing.expectEqual(22, result);
}

test "day 18 part 2 sample 1" {
    const puzzle = try Day18(25).init(sample_input, std.testing.allocator);
    const result = try puzzle.part2(7, 13);
    try std.testing.expectEqual(.{ 6, 1 }, result);
}
