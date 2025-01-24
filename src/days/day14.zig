const std = @import("std");

fn Day14(length: usize) type {
    return struct {
        robot_positions: [length][2]i32 = undefined,
        robot_velocities: [length][2]i32 = undefined,
        map_size: [2]u8,

        const Self = @This();

        fn init(input: []const u8, map_size: [2]u8) !Self {
            var result = Self{ .map_size = map_size };

            var i: usize = 0;
            var lexer = std.mem.tokenizeAny(u8, input, "\n ");
            while (lexer.next()) |line| : (i += 1) {
                var inner_lexer = std.mem.tokenizeScalar(u8, line[2..], ',');
                result.robot_positions[i][0] = try std.fmt.parseInt(i32, inner_lexer.next().?, 10);
                result.robot_positions[i][1] = try std.fmt.parseInt(i32, inner_lexer.next().?, 10);

                inner_lexer = std.mem.tokenizeScalar(u8, lexer.next().?[2..], ',');
                result.robot_velocities[i][0] = try std.fmt.parseInt(i32, inner_lexer.next().?, 10);
                result.robot_velocities[i][1] = try std.fmt.parseInt(i32, inner_lexer.next().?, 10);
            }

            return result;
        }

        fn part1(self: Self, seconds: usize) u64 {
            var counts: @Vector(4, u64) = @splat(0);
            const mid_point = .{ self.map_size[0] / 2, self.map_size[1] / 2 };
            for (self.robot_positions, self.robot_velocities) |position, velocity| {
                const i_seconds: i32 = @intCast(seconds);
                const destination = .{
                    @mod((position[0] + velocity[0] * i_seconds), self.map_size[0]),
                    @mod((position[1] + velocity[1] * i_seconds), self.map_size[1]),
                };
                counts += [_]u1{
                    @intFromBool(destination[0] < mid_point[0] and destination[1] < mid_point[1]),
                    @intFromBool(destination[0] < mid_point[0] and destination[1] > mid_point[1]),
                    @intFromBool(destination[0] > mid_point[0] and destination[1] < mid_point[1]),
                    @intFromBool(destination[0] > mid_point[0] and destination[1] > mid_point[1]),
                };
            }
            var result: u64 = 1;
            for (0..4) |i| result *= counts[i];
            return result;
        }

        fn part2(self: Self) u64 {
            var result: u64 = 0;
            var safety_factor_min: u64 = std.math.maxInt(u64);
            for (0..(self.map_size[0] * self.map_size[1])) |seconds| {
                const safety_factor = self.part1(seconds);
                if (safety_factor < safety_factor_min) {
                    safety_factor_min = safety_factor;
                    result = seconds;
                }
            }
            return result;
        }
    };
}

pub const title = "Day 14: Restroom Redoubt";

pub fn run(_: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    const input = @embedFile("./data/day14.txt");
    const puzzle = try Day14(500).init(input, .{ 101, 103 });
    const time0 = timer.read();

    const result1 = puzzle.part1(100);
    const time1 = timer.read();

    const result2 = puzzle.part2();
    const time2 = timer.read();

    if (is_run) {
        std.debug.print("Part 1: {d}\nPart 2: {d}\n", .{ result1, result2 });
    }

    return .{ time0, time1, time2 };
}

const sample_input =
    \\p=0,4 v=3,-3
    \\p=6,3 v=-1,-3
    \\p=10,3 v=-1,2
    \\p=2,0 v=2,-1
    \\p=0,0 v=1,3
    \\p=3,0 v=-2,-2
    \\p=7,6 v=-1,-3
    \\p=3,0 v=-1,-2
    \\p=9,3 v=2,3
    \\p=7,3 v=-1,2
    \\p=2,4 v=2,-3
    \\p=9,5 v=-3,-3
;

test "day 14 part 1 sample 1" {
    const puzzle = try Day14(12).init(sample_input, .{ 11, 7 });
    const result = puzzle.part1(100);
    try std.testing.expectEqual(12, result);
}
