const std = @import("std");

fn Day21() type {
    return struct {
        const Self = @This();

        numbers: [5]u16 = undefined,
        codes: [5][5]Keypad = .{.{.accept} ** 5} ** 5,
        allocator: std.mem.Allocator,

        fn init(input: []const u8, allocator: std.mem.Allocator) !Self {
            var result = Self{ .allocator = allocator };

            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            for (0..5) |i| {
                const line = lexer.next().?;
                for (line[0..(line.len - 1)], 1..) |c, j| {
                    result.codes[i][j] = @enumFromInt(c - '0');
                }
                result.numbers[i] = try std.fmt.parseInt(u16, line[0..3], 10);
            }

            return result;
        }

        fn part1(self: Self) !u64 {
            var result: u64 = 0;
            for (self.codes, self.numbers) |code, number| {
                const length = try self.get_sequence_length_for_depth(&code, 2);
                result += length * number;
            }
            return result;
        }

        fn part2(self: Self) !u64 {
            var result: u64 = 0;
            for (self.codes, self.numbers) |code, number| {
                const length = try self.get_sequence_length_for_depth(&code, 25);
                result += length * number;
            }
            return result;
        }

        fn get_sequence_length_for_depth(self: Self, code: []const Keypad, depth: u8) !u64 {
            var frequencies: [2]std.StringHashMap(u64) = undefined;
            for (0..2) |i| frequencies[i] = std.StringHashMap(u64).init(self.allocator);
            defer for (0..2) |i| frequencies[i].deinit();

            var id: usize = 0;
            var window = std.mem.window(Keypad, code, 2, 1);
            while (window.next()) |pair| {
                const instruction = &instructions[@intFromEnum(pair[0])][@intFromEnum(pair[1])];
                const best_moves = instruction[1..(@intFromEnum(instruction[0]) + 1)];
                const entry = try frequencies[id].getOrPutValue(@ptrCast(best_moves), 0);
                entry.value_ptr.* += 1;
            }

            for (0..depth) |_| {
                var old_frequencies = &frequencies[id % 2];
                var new_frequencies = &frequencies[(id + 1) % 2];
                id += 1;

                defer old_frequencies.clearRetainingCapacity();

                var iterator = old_frequencies.iterator();
                while (iterator.next()) |entry| {
                    const key = entry.key_ptr.*;
                    const value = entry.value_ptr.*;

                    var inner_window = std.mem.window(u8, key, 2, 1);
                    while (inner_window.next()) |pair| {
                        const instruction = &instructions[pair[0]][pair[1]];
                        const best_moves = instruction[1..(@intFromEnum(instruction[0]) + 1)];
                        const new_entry = try new_frequencies.getOrPutValue(@ptrCast(best_moves), 0);
                        new_entry.value_ptr.* += value;
                    }
                }
            }

            var result: u64 = 0;
            var it = frequencies[id % 2].iterator();
            while (it.next()) |e| {
                result += (e.key_ptr.*.len - 1) * e.value_ptr.*;
            }
            return result;
        }
    };
}

const Keypad = enum(u8) { n0, n1, n2, n3, n4, n5, n6, n7, n8, n9, accept, left, up, down, right };

pub const title = "Day 21: Keypad Conundrum";

pub fn run(allocator: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    const input = @embedFile("./data/day21.txt");
    const puzzle = try Day21().init(input, allocator);
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
    \\029A
    \\980A
    \\179A
    \\456A
    \\379A
;

test "day 21 part 1 sample 1" {
    const puzzle = try Day21().init(sample_input, std.testing.allocator);
    const result = try puzzle.part1();
    try std.testing.expectEqual(126384, result);
}

test "day 21 part 2 sample 1" {
    const puzzle = try Day21().init(sample_input, std.testing.allocator);
    const result = try puzzle.part2();
    try std.testing.expectEqual(154115708116294, result);
}

const moves_capacity = 8;
const instructions: [15][15][moves_capacity]Keypad = .{
    .{
        .{ .n2, .accept, .accept, .n0, .n0, .n0, .n0, .n0 }, // 0->0 (A)
        .{ .n4, .accept, .up, .left, .accept, .n0, .n0, .n0 }, // 0->1 (^<A)
        .{ .n3, .accept, .up, .accept, .n0, .n0, .n0, .n0 }, // 0->2 (^A)
        .{ .n4, .accept, .up, .right, .accept, .n0, .n0, .n0 }, // 0->3 (^>A)
        .{ .n5, .accept, .up, .up, .left, .accept, .n0, .n0 }, // 0->4 (^^<A)
        .{ .n4, .accept, .up, .up, .accept, .n0, .n0, .n0 }, // 0->5 (^^A)
        .{ .n5, .accept, .up, .up, .right, .accept, .n0, .n0 }, // 0->6 (^^>A)
        .{ .n6, .accept, .up, .up, .up, .left, .accept, .n0 }, // 0->7 (^^^<A)
        .{ .n5, .accept, .up, .up, .up, .accept, .n0, .n0 }, // 0->8 (^^^A)
        .{ .n6, .accept, .up, .up, .up, .right, .accept, .n0 }, // 0->9 (^^^>A)
        .{ .n3, .accept, .right, .accept, .n0, .n0, .n0, .n0 }, // 0->accept (>A)
        undefined, // 0->left (unused)
        undefined, // 0->up (unused)
        undefined, // 0->down (unused)
        undefined, // 0->right (unused)
    },
    .{
        .{ .n4, .accept, .right, .down, .accept, .n0, .n0, .n0 }, // 1->0 (>vA)
        .{ .n2, .accept, .accept, .n0, .n0, .n0, .n0, .n0 }, // 1->1 (A)
        .{ .n3, .accept, .right, .accept, .n0, .n0, .n0, .n0 }, // 1->2 (>A)
        .{ .n4, .accept, .right, .right, .accept, .n0, .n0, .n0 }, // 1->3 (>>A)
        .{ .n3, .accept, .up, .accept, .n0, .n0, .n0, .n0 }, // 1->4 (^A)
        .{ .n4, .accept, .up, .right, .accept, .n0, .n0, .n0 }, // 1->5 (^>A)
        .{ .n5, .accept, .up, .right, .right, .accept, .n0, .n0 }, // 1->6 (^>>A)
        .{ .n4, .accept, .up, .up, .accept, .n0, .n0, .n0 }, // 1->7 (^^A)
        .{ .n5, .accept, .up, .up, .right, .accept, .n0, .n0 }, // 1->8 (^^>A)
        .{ .n6, .accept, .up, .up, .right, .right, .accept, .n0 }, // 1->9 (^^>>A)
        .{ .n5, .accept, .right, .right, .down, .accept, .n0, .n0 }, // 1->accept (>>vA)
        undefined, // 1->left (unused)
        undefined, // 1->up (unused)
        undefined, // 1->down (unused)
        undefined, // 1->right (unused)
    },
    .{
        .{ .n3, .accept, .down, .accept, .n0, .n0, .n0, .n0 }, // 2->0 (vA)
        .{ .n3, .accept, .left, .accept, .n0, .n0, .n0, .n0 }, // 2->1 (<A)
        .{ .n2, .accept, .accept, .n0, .n0, .n0, .n0, .n0 }, // 2->2 (A)
        .{ .n3, .accept, .right, .accept, .n0, .n0, .n0, .n0 }, // 2->3 (>A)
        .{ .n4, .accept, .left, .up, .accept, .n0, .n0, .n0 }, // 2->4 (<^A)
        .{ .n3, .accept, .up, .accept, .n0, .n0, .n0, .n0 }, // 2->5 (^A)
        .{ .n4, .accept, .up, .right, .accept, .n0, .n0, .n0 }, // 2->6 (^>A)
        .{ .n5, .accept, .left, .up, .up, .accept, .n0, .n0 }, // 2->7 (<^^A)
        .{ .n4, .accept, .up, .up, .accept, .n0, .n0, .n0 }, // 2->8 (^^A)
        .{ .n5, .accept, .up, .up, .right, .accept, .n0, .n0 }, // 2->9 (^^>A)
        .{ .n4, .accept, .down, .right, .accept, .n0, .n0, .n0 }, // 2->accept (v>A)
        undefined, // 2->left (unused)
        undefined, // 2->up (unused)
        undefined, // 2->down (unused)
        undefined, // 2->right (unused)
    },
    .{
        .{ .n4, .accept, .left, .down, .accept, .n0, .n0, .n0 }, // 3->0 (<vA)
        .{ .n4, .accept, .left, .left, .accept, .n0, .n0, .n0 }, // 3->1 (<<A)
        .{ .n3, .accept, .left, .accept, .n0, .n0, .n0, .n0 }, // 3->2 (<A)
        .{ .n2, .accept, .accept, .n0, .n0, .n0, .n0, .n0 }, // 3->3 (A)
        .{ .n5, .accept, .left, .left, .up, .accept, .n0, .n0 }, // 3->4 (<<^A)
        .{ .n4, .accept, .left, .up, .accept, .n0, .n0, .n0 }, // 3->5 (<^A)
        .{ .n3, .accept, .up, .accept, .n0, .n0, .n0, .n0 }, // 3->6 (^A)
        .{ .n6, .accept, .left, .left, .up, .up, .accept, .n0 }, // 3->7 (<<^^A)
        .{ .n5, .accept, .left, .up, .up, .accept, .n0, .n0 }, // 3->8 (<^^A)
        .{ .n4, .accept, .up, .up, .accept, .n0, .n0, .n0 }, // 3->9 (^^A)
        .{ .n3, .accept, .down, .accept, .n0, .n0, .n0, .n0 }, // 3->accept (vA)
        undefined, // 3->left (unused)
        undefined, // 3->up (unused)
        undefined, // 3->down (unused)
        undefined, // 3->right (unused)
    },
    .{
        .{ .n5, .accept, .right, .down, .down, .accept, .n0, .n0 }, // 4->0 (>vvA)
        .{ .n3, .accept, .down, .accept, .n0, .n0, .n0, .n0 }, // 4->1 (vA)
        .{ .n4, .accept, .down, .right, .accept, .n0, .n0, .n0 }, // 4->2 (v>A)
        .{ .n5, .accept, .down, .right, .right, .accept, .n0, .n0 }, // 4->3 (v>>A)
        .{ .n2, .accept, .accept, .n0, .n0, .n0, .n0, .n0 }, // 4->4 (A)
        .{ .n3, .accept, .right, .accept, .n0, .n0, .n0, .n0 }, // 4->5 (>A)
        .{ .n4, .accept, .right, .right, .accept, .n0, .n0, .n0 }, // 4->6 (>>A)
        .{ .n3, .accept, .up, .accept, .n0, .n0, .n0, .n0 }, // 4->7 (^A)
        .{ .n4, .accept, .up, .right, .accept, .n0, .n0, .n0 }, // 4->8 (^>A)
        .{ .n5, .accept, .up, .right, .right, .accept, .n0, .n0 }, // 4->9 (^>>A)
        .{ .n6, .accept, .right, .right, .down, .down, .accept, .n0 }, // 4->accept (>>vvA)
        undefined, // 4->left (unused)
        undefined, // 4->up (unused)
        undefined, // 4->down (unused)
        undefined, // 4->right (unused)
    },
    .{
        .{ .n4, .accept, .down, .down, .accept, .n0, .n0, .n0 }, // 5->0 (vvA)
        .{ .n4, .accept, .left, .down, .accept, .n0, .n0, .n0 }, // 5->1 (<vA)
        .{ .n3, .accept, .down, .accept, .n0, .n0, .n0, .n0 }, // 5->2 (vA)
        .{ .n4, .accept, .down, .right, .accept, .n0, .n0, .n0 }, // 5->3 (v>A)
        .{ .n3, .accept, .left, .accept, .n0, .n0, .n0, .n0 }, // 5->4 (<A)
        .{ .n2, .accept, .accept, .n0, .n0, .n0, .n0, .n0 }, // 5->5 (A)
        .{ .n3, .accept, .right, .accept, .n0, .n0, .n0, .n0 }, // 5->6 (>A)
        .{ .n4, .accept, .left, .up, .accept, .n0, .n0, .n0 }, // 5->7 (<^A)
        .{ .n3, .accept, .up, .accept, .n0, .n0, .n0, .n0 }, // 5->8 (^A)
        .{ .n4, .accept, .up, .right, .accept, .n0, .n0, .n0 }, // 5->9 (^>A)
        .{ .n5, .accept, .down, .down, .right, .accept, .n0, .n0 }, // 5->accept (vv>A)
        undefined, // 5->left (unused)
        undefined, // 5->up (unused)
        undefined, // 5->down (unused)
        undefined, // 5->right (unused)
    },
    .{
        .{ .n5, .accept, .left, .down, .down, .accept, .n0, .n0 }, // 6->0 (<vvA)
        .{ .n5, .accept, .left, .left, .down, .accept, .n0, .n0 }, // 6->1 (<<vA)
        .{ .n4, .accept, .left, .down, .accept, .n0, .n0, .n0 }, // 6->2 (<vA)
        .{ .n3, .accept, .down, .accept, .n0, .n0, .n0, .n0 }, // 6->3 (vA)
        .{ .n4, .accept, .left, .left, .accept, .n0, .n0, .n0 }, // 6->4 (<<A)
        .{ .n3, .accept, .left, .accept, .n0, .n0, .n0, .n0 }, // 6->5 (<A)
        .{ .n2, .accept, .accept, .n0, .n0, .n0, .n0, .n0 }, // 6->6 (A)
        .{ .n5, .accept, .left, .left, .up, .accept, .n0, .n0 }, // 6->7 (<<^A)
        .{ .n4, .accept, .left, .up, .accept, .n0, .n0, .n0 }, // 6->8 (<^A)
        .{ .n3, .accept, .up, .accept, .n0, .n0, .n0, .n0 }, // 6->9 (^A)
        .{ .n4, .accept, .down, .down, .accept, .n0, .n0, .n0 }, // 6->accept (vvA)
        undefined, // 6->left (unused)
        undefined, // 6->up (unused)
        undefined, // 6->down (unused)
        undefined, // 6->right (unused)
    },
    .{
        .{ .n6, .accept, .right, .down, .down, .down, .accept, .n0 }, // 7->0 (>vvvA)
        .{ .n4, .accept, .down, .down, .accept, .n0, .n0, .n0 }, // 7->1 (vvA)
        .{ .n5, .accept, .down, .down, .right, .accept, .n0, .n0 }, // 7->2 (vv>A)
        .{ .n6, .accept, .down, .down, .right, .right, .accept, .n0 }, // 7->3 (vv>>A)
        .{ .n3, .accept, .down, .accept, .n0, .n0, .n0, .n0 }, // 7->4 (vA)
        .{ .n4, .accept, .down, .right, .accept, .n0, .n0, .n0 }, // 7->5 (v>A)
        .{ .n5, .accept, .down, .right, .right, .accept, .n0, .n0 }, // 7->6 (v>>A)
        .{ .n2, .accept, .accept, .n0, .n0, .n0, .n0, .n0 }, // 7->7 (A)
        .{ .n3, .accept, .right, .accept, .n0, .n0, .n0, .n0 }, // 7->8 (>A)
        .{ .n4, .accept, .right, .right, .accept, .n0, .n0, .n0 }, // 7->9 (>>A)
        .{ .n7, .accept, .right, .right, .down, .down, .down, .accept }, // 7->accept (>>vvvA)
        undefined, // 7->left (unused)
        undefined, // 7->up (unused)
        undefined, // 7->down (unused)
        undefined, // 7->right (unused)
    },
    .{
        .{ .n5, .accept, .down, .down, .down, .accept, .n0, .n0 }, // 8->0 (vvvA)
        .{ .n5, .accept, .left, .down, .down, .accept, .n0, .n0 }, // 8->1 (<vvA)
        .{ .n4, .accept, .down, .down, .accept, .n0, .n0, .n0 }, // 8->2 (vvA)
        .{ .n5, .accept, .down, .down, .right, .accept, .n0, .n0 }, // 8->3 (vv>A)
        .{ .n4, .accept, .left, .down, .accept, .n0, .n0, .n0 }, // 8->4 (<vA)
        .{ .n3, .accept, .down, .accept, .n0, .n0, .n0, .n0 }, // 8->5 (vA)
        .{ .n4, .accept, .down, .right, .accept, .n0, .n0, .n0 }, // 8->6 (v>A)
        .{ .n3, .accept, .left, .accept, .n0, .n0, .n0, .n0 }, // 8->7 (<A)
        .{ .n2, .accept, .accept, .n0, .n0, .n0, .n0, .n0 }, // 8->8 (A)
        .{ .n3, .accept, .right, .accept, .n0, .n0, .n0, .n0 }, // 8->9 (>A)
        .{ .n6, .accept, .down, .down, .down, .right, .accept, .n0 }, // 8->accept (vvv>A)
        undefined, // 8->left (unused)
        undefined, // 8->up (unused)
        undefined, // 8->down (unused)
        undefined, // 8->right (unused)
    },
    .{
        .{ .n6, .accept, .left, .down, .down, .down, .accept, .n0 }, // 9->0 (<vvvA)
        .{ .n6, .accept, .left, .left, .down, .down, .accept, .n0 }, // 9->1 (<<vvA)
        .{ .n5, .accept, .left, .down, .down, .accept, .n0, .n0 }, // 9->2 (<vvA)
        .{ .n4, .accept, .down, .down, .accept, .n0, .n0, .n0 }, // 9->3 (vvA)
        .{ .n5, .accept, .left, .left, .down, .accept, .n0, .n0 }, // 9->4 (<<vA)
        .{ .n4, .accept, .left, .down, .accept, .n0, .n0, .n0 }, // 9->5 (<vA)
        .{ .n3, .accept, .down, .accept, .n0, .n0, .n0, .n0 }, // 9->6 (vA)
        .{ .n4, .accept, .left, .left, .accept, .n0, .n0, .n0 }, // 9->7 (<<A)
        .{ .n3, .accept, .left, .accept, .n0, .n0, .n0, .n0 }, // 9->8 (<A)
        .{ .n2, .accept, .accept, .n0, .n0, .n0, .n0, .n0 }, // 9->9 (A)
        .{ .n5, .accept, .down, .down, .down, .accept, .n0, .n0 }, // 9->accept (vvvA)
        undefined, // 9->left (unused)
        undefined, // 9->up (unused)
        undefined, // 9->down (unused)
        undefined, // 9->right (unused)
    },
    .{
        .{ .n3, .accept, .left, .accept, .n0, .n0, .n0, .n0 }, // accept->0 (<A)
        .{ .n5, .accept, .up, .left, .left, .accept, .n0, .n0 }, // accept->1 (^<<A)
        .{ .n4, .accept, .left, .up, .accept, .n0, .n0, .n0 }, // accept->2 (<^A)
        .{ .n3, .accept, .up, .accept, .n0, .n0, .n0, .n0 }, // accept->3 (^A)
        .{ .n6, .accept, .up, .up, .left, .left, .accept, .n0 }, // accept->4 (^^<<A)
        .{ .n5, .accept, .left, .up, .up, .accept, .n0, .n0 }, // accept->5 (<^^A)
        .{ .n4, .accept, .up, .up, .accept, .n0, .n0, .n0 }, // accept->6 (^^A)
        .{ .n7, .accept, .up, .up, .up, .left, .left, .accept }, // accept->7 (^^^<<A)
        .{ .n6, .accept, .left, .up, .up, .up, .accept, .n0 }, // accept->8 (<^^^A)
        .{ .n5, .accept, .up, .up, .up, .accept, .n0, .n0 }, // accept->9 (^^^A)
        .{ .n2, .accept, .accept, .n0, .n0, .n0, .n0, .n0 }, // accept->accept (A)
        .{ .n5, .accept, .down, .left, .left, .accept, .n0, .n0 }, // accept->left (v<<A)
        .{ .n3, .accept, .left, .accept, .n0, .n0, .n0, .n0 }, // accept->up (<A)
        .{ .n4, .accept, .left, .down, .accept, .n0, .n0, .n0 }, // accept->down (<vA)
        .{ .n3, .accept, .down, .accept, .n0, .n0, .n0, .n0 }, // accept->right (vA)
    },
    .{
        undefined, // left->0 (unused)
        undefined, // left->1 (unused)
        undefined, // left->2 (unused)
        undefined, // left->3 (unused)
        undefined, // left->4 (unused)
        undefined, // left->5 (unused)
        undefined, // left->6 (unused)
        undefined, // left->7 (unused)
        undefined, // left->8 (unused)
        undefined, // left->9 (unused)
        .{ .n5, .accept, .right, .right, .up, .accept, .n0, .n0 }, // left->accept (>>^A)
        .{ .n2, .accept, .accept, .n0, .n0, .n0, .n0, .n0 }, // left->left (A)
        .{ .n4, .accept, .right, .up, .accept, .n0, .n0, .n0 }, // left->up (>^A)
        .{ .n3, .accept, .right, .accept, .n0, .n0, .n0, .n0 }, // left->down (>A)
        .{ .n4, .accept, .right, .right, .accept, .n0, .n0, .n0 }, // left->right (>>A)
    },
    .{
        undefined, // up->0 (unused)
        undefined, // up->1 (unused)
        undefined, // up->2 (unused)
        undefined, // up->3 (unused)
        undefined, // up->4 (unused)
        undefined, // up->5 (unused)
        undefined, // up->6 (unused)
        undefined, // up->7 (unused)
        undefined, // up->8 (unused)
        undefined, // up->9 (unused)
        .{ .n3, .accept, .right, .accept, .n0, .n0, .n0, .n0 }, // up->accept (>A)
        .{ .n4, .accept, .down, .left, .accept, .n0, .n0, .n0 }, // up->left (v<A)
        .{ .n2, .accept, .accept, .n0, .n0, .n0, .n0, .n0 }, // up->up (A)
        .{ .n3, .accept, .down, .accept, .n0, .n0, .n0, .n0 }, // up->down (vA)
        .{ .n4, .accept, .down, .right, .accept, .n0, .n0, .n0 }, // up->right (v>A)
    },
    .{
        undefined, // down->0 (unused)
        undefined, // down->1 (unused)
        undefined, // down->2 (unused)
        undefined, // down->3 (unused)
        undefined, // down->4 (unused)
        undefined, // down->5 (unused)
        undefined, // down->6 (unused)
        undefined, // down->7 (unused)
        undefined, // down->8 (unused)
        undefined, // down->9 (unused)
        .{ .n4, .accept, .up, .right, .accept, .n0, .n0, .n0 }, // down->accept (^>A)
        .{ .n3, .accept, .left, .accept, .n0, .n0, .n0, .n0 }, // down->left (<A)
        .{ .n3, .accept, .up, .accept, .n0, .n0, .n0, .n0 }, // down->up (^A)
        .{ .n2, .accept, .accept, .n0, .n0, .n0, .n0, .n0 }, // down->down (A)
        .{ .n3, .accept, .right, .accept, .n0, .n0, .n0, .n0 }, // down->right (>A)
    },
    .{
        undefined, // right->0 (unused)
        undefined, // right->1 (unused)
        undefined, // right->2 (unused)
        undefined, // right->3 (unused)
        undefined, // right->4 (unused)
        undefined, // right->5 (unused)
        undefined, // right->6 (unused)
        undefined, // right->7 (unused)
        undefined, // right->8 (unused)
        undefined, // right->9 (unused)
        .{ .n3, .accept, .up, .accept, .n0, .n0, .n0, .n0 }, // right->accept (^A)
        .{ .n4, .accept, .left, .left, .accept, .n0, .n0, .n0 }, // right->left (<<A)
        .{ .n4, .accept, .left, .up, .accept, .n0, .n0, .n0 }, // right->up (<^A)
        .{ .n3, .accept, .left, .accept, .n0, .n0, .n0, .n0 }, // right->down (<A)
        .{ .n2, .accept, .accept, .n0, .n0, .n0, .n0, .n0 }, // right->right (A)
    },
};
