const std = @import("std");

fn Day18(length: usize) type {
    return struct {
        const Self = @This();

        const directions: [2]@Vector(2, u1) = .{ .{ 1, 0 }, .{ 0, 1 } };

        bytes: [length][2]u8 = undefined,

        fn init(input: []const u8) !Self {
            var result = Self{};

            var i: usize = 0;
            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                var inner_lexer = std.mem.tokenizeScalar(u8, line, ',');
                const y = try std.fmt.parseInt(usize, inner_lexer.next().?, 10);
                const x = try std.fmt.parseInt(usize, inner_lexer.next().?, 10);
                result.bytes[i] = .{ @intCast(x), @intCast(y) };
            }

            return result;
        }

        fn part1(self: Self, comptime map_size: usize, n_bytes: usize) u64 {
            var map: [map_size + 2][map_size + 2]u8 = .{.{'#'} ** (map_size + 2)} ** (map_size + 2);

            @memset(map[1..(map_size + 1)], .{'#'} ++ (.{'.'} ** map_size) ++ .{'#'});
            for (self.bytes[0..n_bytes]) |byte| {
                map[byte[0] + 1][byte[1] + 1] = '#';
            }

            const queue_capacity = 8192;
            var queue: [queue_capacity]struct { position: [2]u8, steps: u32 } = undefined;

            queue[0] = .{ .position = .{ 1, 1 }, .steps = 0 };

            var result: u64 = std.math.maxInt(u64);

            var left: usize = 0;
            var right: usize = 1;
            while (left < right) : (left += 1) {
                const current = queue[left];

                if (std.mem.eql(u8, &current.position, &.{ map_size, map_size })) {
                    if (current.steps < result) result = current.steps;
                    continue;
                }

                // Check again here because the queue can contain duplicate tiles. It's possibel to
                // pop a visited tile that was just marked in the previous iteration.
                if (map[current.position[0]][current.position[1]] == 'X') continue;

                map[current.position[0]][current.position[1]] = 'X';

                for (directions) |direction| {
                    var next = current.position + direction;
                    if (map[next[0]][next[1]] != '#' and map[next[0]][next[1]] != 'X') {
                        queue[right] = .{ .position = next, .steps = current.steps + 1 };
                        right += 1;
                    }

                    next = current.position - direction;
                    if (map[next[0]][next[1]] != '#' and map[next[0]][next[1]] != 'X') {
                        queue[right] = .{ .position = next, .steps = current.steps + 1 };
                        right += 1;
                    }
                }
            }

            return result;
        }

        fn part2(self: Self, comptime map_size: usize, start: usize) [2]u64 {
            var left = start;
            var right = self.bytes.len;

            while (left < right) {
                const mid = left + (right - left) / 2;
                const result = self.part1(map_size, mid);
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

pub fn run(_: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    const input = @embedFile("./data/day18.txt");
    const puzzle = try Day18(3450).init(input);
    const time0 = timer.read();

    const result1 = puzzle.part1(71, 1024);
    const time1 = timer.read();

    const result2 = puzzle.part2(71, 1025);
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
    const puzzle = try Day18(25).init(sample_input);
    const result = puzzle.part1(7, 12);
    try std.testing.expectEqual(22, result);
}

test "day 18 part 2 sample 1" {
    const puzzle = try Day18(25).init(sample_input);
    const result = puzzle.part2(7, 13);
    try std.testing.expectEqual(.{ 6, 1 }, result);
}
