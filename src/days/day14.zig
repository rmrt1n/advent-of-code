const std = @import("std");

fn Day14(length: usize) type {
    return struct {
        const Self = @This();

        positions: [length]@Vector(2, i32) = undefined,
        velocities: [length]@Vector(2, i32) = undefined,
        map_size: @Vector(2, u16),

        fn init(input: []const u8, map_size: [2]u16) !Self {
            var result = Self{ .map_size = map_size };

            var i: usize = 0;
            var lexer = std.mem.tokenizeAny(u8, input, "\n ");
            while (lexer.next()) |line| : (i += 1) {
                var inner_lexer = std.mem.tokenizeScalar(u8, line[2..], ',');
                result.positions[i][0] = try std.fmt.parseInt(i32, inner_lexer.next().?, 10);
                result.positions[i][1] = try std.fmt.parseInt(i32, inner_lexer.next().?, 10);

                inner_lexer = std.mem.tokenizeScalar(u8, lexer.next().?[2..], ',');
                result.velocities[i][0] = try std.fmt.parseInt(i32, inner_lexer.next().?, 10);
                result.velocities[i][1] = try std.fmt.parseInt(i32, inner_lexer.next().?, 10);
            }

            return result;
        }

        fn part1(self: Self, seconds: i32) u64 {
            const seconds_vector: @Vector(2, i32) = @splat(seconds);
            const mid_point = self.map_size / [_]u8{ 2, 2 };

            var counts: @Vector(4, u64) = @splat(0);
            for (self.positions, self.velocities) |position, velocity| {
                const destination = @mod(position + velocity * seconds_vector, self.map_size);
                const offset_x, const offset_y = destination - mid_point;

                counts += @intFromBool(@Vector(4, bool){
                    offset_x < 0 and offset_y < 0,
                    offset_x < 0 and offset_y > 0,
                    offset_x > 0 and offset_y < 0,
                    offset_x > 0 and offset_y > 0,
                });
            }
            return @reduce(.Mul, counts);
        }

        fn part2(self: Self) u64 {
            var result: u64 = 0;
            var safety_factor_min: u64 = std.math.maxInt(u64);

            for (0..(self.map_size[0] * self.map_size[1])) |seconds| {
                const safety_factor = self.part1(@intCast(seconds));
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
