const std = @import("std");

fn Day08(length: usize) type {
    return struct {
        antennas: std.AutoHashMap(u8, std.ArrayList([2]u8)) = undefined,
        allocator: std.mem.Allocator,

        const Self = @This();

        fn init(input: []const u8, allocator: std.mem.Allocator) !Self {
            var result = Self{ .allocator = allocator };
            result.antennas = std.AutoHashMap(u8, std.ArrayList([2]u8)).init(allocator);

            var i: usize = 0;
            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                for (line, 0..) |c, j| {
                    if (c == '.') continue;
                    const entry = try result.antennas.getOrPutValue(
                        c,
                        std.ArrayList([2]u8).init(allocator),
                    );
                    try entry.value_ptr.append(.{ @intCast(i), @intCast(j) });
                }
            }

            return result;
        }

        fn deinit(self: *Self) void {
            var iterator = self.antennas.valueIterator();
            while (iterator.next()) |value| value.deinit();
            self.antennas.deinit();
        }

        fn part1(self: Self) !u64 {
            var antinodes = std.AutoHashMap([2]u8, void).init(self.allocator);
            defer antinodes.deinit();

            var iterator = self.antennas.iterator();
            while (iterator.next()) |entry| {
                const antennas = entry.value_ptr.*.items;
                for (antennas[0..(antennas.len - 1)], 0..) |antenna_a, i| {
                    for (antennas[(i + 1)..antennas.len]) |antenna_b| {
                        if (antinode_of(antenna_a, antenna_b)) |antinode| {
                            try antinodes.put(antinode, {});
                        }
                        if (antinode_of(antenna_b, antenna_a)) |antinode| {
                            try antinodes.put(antinode, {});
                        }
                    }
                }
            }
            return antinodes.count();
        }

        fn part2(self: Self) !u64 {
            var antinodes = std.AutoHashMap([2]u8, void).init(self.allocator);
            defer antinodes.deinit();

            var iterator = self.antennas.iterator();
            while (iterator.next()) |entry| {
                const antennas = entry.value_ptr.*.items;
                for (antennas[0..(antennas.len - 1)], 0..) |antenna_a, i| {
                    try antinodes.put(antenna_a, {});

                    for (antennas[(i + 1)..antennas.len]) |antenna_b| {
                        try antinodes.put(antenna_b, {});

                        var current_a = antenna_a;
                        var current_b = antenna_b;
                        while (antinode_of(current_a, current_b)) |antinode| {
                            try antinodes.put(antinode, {});
                            current_a = current_b;
                            current_b = antinode;
                        }
                        current_a = antenna_b;
                        current_b = antenna_a;
                        while (antinode_of(current_a, current_b)) |antinode| {
                            try antinodes.put(antinode, {});
                            current_a = current_b;
                            current_b = antinode;
                        }
                    }
                }
            }
            return antinodes.count();
        }

        fn antinode_of(a: [2]u8, b: [2]u8) ?[2]u8 {
            const x = @as(i16, b[0] * 2) - a[0];
            const y = @as(i16, b[1] * 2) - a[1];
            if (x < 0 or y < 0 or x >= length or y >= length) return null;
            return .{ @intCast(x), @intCast(y) };
        }
    };
}

pub const title = "Day 08: Resonant Collinearity";

pub fn run(allocator: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    const input = @embedFile("./data/day08.txt");
    var puzzle = try Day08(50).init(input, allocator);
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
    \\............
    \\........0...
    \\.....0......
    \\.......0....
    \\....0.......
    \\......A.....
    \\............
    \\............
    \\........A...
    \\.........A..
    \\............
    \\............
;

test "day 08 part 1 sample 1" {
    var puzzle = try Day08(12).init(sample_input, std.testing.allocator);
    defer puzzle.deinit();
    const result = try puzzle.part1();
    try std.testing.expectEqual(14, result);
}

test "day 08 part 2 sample 1" {
    var puzzle = try Day08(12).init(sample_input, std.testing.allocator);
    defer puzzle.deinit();
    const result = try puzzle.part2();
    try std.testing.expectEqual(34, result);
}
