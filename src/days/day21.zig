const std = @import("std");

const Keypad = enum(u8) { zero, one, two, three, four, five, six, seven, eight, nine, accept, left, up, down, right };

fn Day21() type {
    return struct {
        numbers: [5]u16 = undefined,
        codes: [5][5]Keypad = .{.{.accept} ** 5} ** 5,
        allocator: std.mem.Allocator,

        const Self = @This();

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
            var frequencies = std.StringHashMap(u64).init(self.allocator);
            defer frequencies.deinit();

            var window = std.mem.window(Keypad, code, 2, 1);
            while (window.next()) |pair| {
                const instruction = &instructions[@intFromEnum(pair[0])][@intFromEnum(pair[1])];
                const best_moves = instruction[1..(@intFromEnum(instruction[0]) + 1)];
                const entry = try frequencies.getOrPutValue(@ptrCast(best_moves), 0);
                entry.value_ptr.* += 1;
            }

            for (0..depth) |_| {
                var new_frequencies = std.StringHashMap(u64).init(self.allocator);

                var iterator = frequencies.iterator();
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

                frequencies.deinit();
                frequencies = new_frequencies;
            }

            var length: u64 = 0;
            var it = frequencies.iterator();
            while (it.next()) |e| {
                length += (e.key_ptr.*.len - 1) * e.value_ptr.*;
            }
            return length;
        }
    };
}

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

const instructions: [15][15][8]Keypad = .{
    .{
        .{ .two, .accept, .accept, .zero, .zero, .zero, .zero, .zero }, // 0->0 (A)
        .{ .four, .accept, .up, .left, .accept, .zero, .zero, .zero }, // 0->1 (^<A)
        .{ .three, .accept, .up, .accept, .zero, .zero, .zero, .zero }, // 0->2 (^A)
        .{ .four, .accept, .up, .right, .accept, .zero, .zero, .zero }, // 0->3 (^>A)
        .{ .five, .accept, .up, .up, .left, .accept, .zero, .zero }, // 0->4 (^^<A)
        .{ .four, .accept, .up, .up, .accept, .zero, .zero, .zero }, // 0->5 (^^A)
        .{ .five, .accept, .up, .up, .right, .accept, .zero, .zero }, // 0->6 (^^>A)
        .{ .six, .accept, .up, .up, .up, .left, .accept, .zero }, // 0->7 (^^^<A)
        .{ .five, .accept, .up, .up, .up, .accept, .zero, .zero }, // 0->8 (^^^A)
        .{ .six, .accept, .up, .up, .up, .right, .accept, .zero }, // 0->9 (^^^>A)
        .{ .three, .accept, .right, .accept, .zero, .zero, .zero, .zero }, // 0->accept (>A)
        .{.zero} ** 8, // 0->left (unused)
        .{.zero} ** 8, // 0->up (unused)
        .{.zero} ** 8, // 0->down (unused)
        .{.zero} ** 8, // 0->right (unused)
    },
    .{
        .{ .four, .accept, .right, .down, .accept, .zero, .zero, .zero }, // 1->0 (>vA)
        .{ .two, .accept, .accept, .zero, .zero, .zero, .zero, .zero }, // 1->1 (A)
        .{ .three, .accept, .right, .accept, .zero, .zero, .zero, .zero }, // 1->2 (>A)
        .{ .four, .accept, .right, .right, .accept, .zero, .zero, .zero }, // 1->3 (>>A)
        .{ .three, .accept, .up, .accept, .zero, .zero, .zero, .zero }, // 1->4 (^A)
        .{ .four, .accept, .up, .right, .accept, .zero, .zero, .zero }, // 1->5 (^>A)
        .{ .five, .accept, .up, .right, .right, .accept, .zero, .zero }, // 1->6 (^>>A)
        .{ .four, .accept, .up, .up, .accept, .zero, .zero, .zero }, // 1->7 (^^A)
        .{ .five, .accept, .up, .up, .right, .accept, .zero, .zero }, // 1->8 (^^>A)
        .{ .six, .accept, .up, .up, .right, .right, .accept, .zero }, // 1->9 (^^>>A)
        .{ .five, .accept, .right, .right, .down, .accept, .zero, .zero }, // 1->accept (>>vA)
        .{.zero} ** 8, // 1->left (unused)
        .{.zero} ** 8, // 1->up (unused)
        .{.zero} ** 8, // 1->down (unused)
        .{.zero} ** 8, // 1->right (unused)
    },
    .{
        .{ .three, .accept, .down, .accept, .zero, .zero, .zero, .zero }, // 2->0 (vA)
        .{ .three, .accept, .left, .accept, .zero, .zero, .zero, .zero }, // 2->1 (<A)
        .{ .two, .accept, .accept, .zero, .zero, .zero, .zero, .zero }, // 2->2 (A)
        .{ .three, .accept, .right, .accept, .zero, .zero, .zero, .zero }, // 2->3 (>A)
        .{ .four, .accept, .left, .up, .accept, .zero, .zero, .zero }, // 2->4 (<^A)
        .{ .three, .accept, .up, .accept, .zero, .zero, .zero, .zero }, // 2->5 (^A)
        .{ .four, .accept, .up, .right, .accept, .zero, .zero, .zero }, // 2->6 (^>A)
        .{ .five, .accept, .left, .up, .up, .accept, .zero, .zero }, // 2->7 (<^^A)
        .{ .four, .accept, .up, .up, .accept, .zero, .zero, .zero }, // 2->8 (^^A)
        .{ .five, .accept, .up, .up, .right, .accept, .zero, .zero }, // 2->9 (^^>A)
        .{ .four, .accept, .down, .right, .accept, .zero, .zero, .zero }, // 2->accept (v>A)
        .{.zero} ** 8, // 2->left (unused)
        .{.zero} ** 8, // 2->up (unused)
        .{.zero} ** 8, // 2->down (unused)
        .{.zero} ** 8, // 2->right (unused)
    },
    .{
        .{ .four, .accept, .left, .down, .accept, .zero, .zero, .zero }, // 3->0 (<vA)
        .{ .four, .accept, .left, .left, .accept, .zero, .zero, .zero }, // 3->1 (<<A)
        .{ .three, .accept, .left, .accept, .zero, .zero, .zero, .zero }, // 3->2 (<A)
        .{ .two, .accept, .accept, .zero, .zero, .zero, .zero, .zero }, // 3->3 (A)
        .{ .five, .accept, .left, .left, .up, .accept, .zero, .zero }, // 3->4 (<<^A)
        .{ .four, .accept, .left, .up, .accept, .zero, .zero, .zero }, // 3->5 (<^A)
        .{ .three, .accept, .up, .accept, .zero, .zero, .zero, .zero }, // 3->6 (^A)
        .{ .six, .accept, .left, .left, .up, .up, .accept, .zero }, // 3->7 (<<^^A)
        .{ .five, .accept, .left, .up, .up, .accept, .zero, .zero }, // 3->8 (<^^A)
        .{ .four, .accept, .up, .up, .accept, .zero, .zero, .zero }, // 3->9 (^^A)
        .{ .three, .accept, .down, .accept, .zero, .zero, .zero, .zero }, // 3->accept (vA)
        .{.zero} ** 8, // 3->left (unused)
        .{.zero} ** 8, // 3->up (unused)
        .{.zero} ** 8, // 3->down (unused)
        .{.zero} ** 8, // 3->right (unused)
    },
    .{
        .{ .five, .accept, .right, .down, .down, .accept, .zero, .zero }, // 4->0 (>vvA)
        .{ .three, .accept, .down, .accept, .zero, .zero, .zero, .zero }, // 4->1 (vA)
        .{ .four, .accept, .down, .right, .accept, .zero, .zero, .zero }, // 4->2 (v>A)
        .{ .five, .accept, .down, .right, .right, .accept, .zero, .zero }, // 4->3 (v>>A)
        .{ .two, .accept, .accept, .zero, .zero, .zero, .zero, .zero }, // 4->4 (A)
        .{ .three, .accept, .right, .accept, .zero, .zero, .zero, .zero }, // 4->5 (>A)
        .{ .four, .accept, .right, .right, .accept, .zero, .zero, .zero }, // 4->6 (>>A)
        .{ .three, .accept, .up, .accept, .zero, .zero, .zero, .zero }, // 4->7 (^A)
        .{ .four, .accept, .up, .right, .accept, .zero, .zero, .zero }, // 4->8 (^>A)
        .{ .five, .accept, .up, .right, .right, .accept, .zero, .zero }, // 4->9 (^>>A)
        .{ .six, .accept, .right, .right, .down, .down, .accept, .zero }, // 4->accept (>>vvA)
        .{.zero} ** 8, // 4->left (unused)
        .{.zero} ** 8, // 4->up (unused)
        .{.zero} ** 8, // 4->down (unused)
        .{.zero} ** 8, // 4->right (unused)
    },
    .{
        .{ .four, .accept, .down, .down, .accept, .zero, .zero, .zero }, // 5->0 (vvA)
        .{ .four, .accept, .left, .down, .accept, .zero, .zero, .zero }, // 5->1 (<vA)
        .{ .three, .accept, .down, .accept, .zero, .zero, .zero, .zero }, // 5->2 (vA)
        .{ .four, .accept, .down, .right, .accept, .zero, .zero, .zero }, // 5->3 (v>A)
        .{ .three, .accept, .left, .accept, .zero, .zero, .zero, .zero }, // 5->4 (<A)
        .{ .two, .accept, .accept, .zero, .zero, .zero, .zero, .zero }, // 5->5 (A)
        .{ .three, .accept, .right, .accept, .zero, .zero, .zero, .zero }, // 5->6 (>A)
        .{ .four, .accept, .left, .up, .accept, .zero, .zero, .zero }, // 5->7 (<^A)
        .{ .three, .accept, .up, .accept, .zero, .zero, .zero, .zero }, // 5->8 (^A)
        .{ .four, .accept, .up, .right, .accept, .zero, .zero, .zero }, // 5->9 (^>A)
        .{ .five, .accept, .down, .down, .right, .accept, .zero, .zero }, // 5->accept (vv>A)
        .{.zero} ** 8, // 5->left (unused)
        .{.zero} ** 8, // 5->up (unused)
        .{.zero} ** 8, // 5->down (unused)
        .{.zero} ** 8, // 5->right (unused)
    },
    .{
        .{ .five, .accept, .left, .down, .down, .accept, .zero, .zero }, // 6->0 (<vvA)
        .{ .five, .accept, .left, .left, .down, .accept, .zero, .zero }, // 6->1 (<<vA)
        .{ .four, .accept, .left, .down, .accept, .zero, .zero, .zero }, // 6->2 (<vA)
        .{ .three, .accept, .down, .accept, .zero, .zero, .zero, .zero }, // 6->3 (vA)
        .{ .four, .accept, .left, .left, .accept, .zero, .zero, .zero }, // 6->4 (<<A)
        .{ .three, .accept, .left, .accept, .zero, .zero, .zero, .zero }, // 6->5 (<A)
        .{ .two, .accept, .accept, .zero, .zero, .zero, .zero, .zero }, // 6->6 (A)
        .{ .five, .accept, .left, .left, .up, .accept, .zero, .zero }, // 6->7 (<<^A)
        .{ .four, .accept, .left, .up, .accept, .zero, .zero, .zero }, // 6->8 (<^A)
        .{ .three, .accept, .up, .accept, .zero, .zero, .zero, .zero }, // 6->9 (^A)
        .{ .four, .accept, .down, .down, .accept, .zero, .zero, .zero }, // 6->accept (vvA)
        .{.zero} ** 8, // 6->left (unused)
        .{.zero} ** 8, // 6->up (unused)
        .{.zero} ** 8, // 6->down (unused)
        .{.zero} ** 8, // 6->right (unused)
    },
    .{
        .{ .six, .accept, .right, .down, .down, .down, .accept, .zero }, // 7->0 (>vvvA)
        .{ .four, .accept, .down, .down, .accept, .zero, .zero, .zero }, // 7->1 (vvA)
        .{ .five, .accept, .down, .down, .right, .accept, .zero, .zero }, // 7->2 (vv>A)
        .{ .six, .accept, .down, .down, .right, .right, .accept, .zero }, // 7->3 (vv>>A)
        .{ .three, .accept, .down, .accept, .zero, .zero, .zero, .zero }, // 7->4 (vA)
        .{ .four, .accept, .down, .right, .accept, .zero, .zero, .zero }, // 7->5 (v>A)
        .{ .five, .accept, .down, .right, .right, .accept, .zero, .zero }, // 7->6 (v>>A)
        .{ .two, .accept, .accept, .zero, .zero, .zero, .zero, .zero }, // 7->7 (A)
        .{ .three, .accept, .right, .accept, .zero, .zero, .zero, .zero }, // 7->8 (>A)
        .{ .four, .accept, .right, .right, .accept, .zero, .zero, .zero }, // 7->9 (>>A)
        .{ .seven, .accept, .right, .right, .down, .down, .down, .accept }, // 7->accept (>>vvvA)
        .{.zero} ** 8, // 7->left (unused)
        .{.zero} ** 8, // 7->up (unused)
        .{.zero} ** 8, // 7->down (unused)
        .{.zero} ** 8, // 7->right (unused)
    },
    .{
        .{ .five, .accept, .down, .down, .down, .accept, .zero, .zero }, // 8->0 (vvvA)
        .{ .five, .accept, .left, .down, .down, .accept, .zero, .zero }, // 8->1 (<vvA)
        .{ .four, .accept, .down, .down, .accept, .zero, .zero, .zero }, // 8->2 (vvA)
        .{ .five, .accept, .down, .down, .right, .accept, .zero, .zero }, // 8->3 (vv>A)
        .{ .four, .accept, .left, .down, .accept, .zero, .zero, .zero }, // 8->4 (<vA)
        .{ .three, .accept, .down, .accept, .zero, .zero, .zero, .zero }, // 8->5 (vA)
        .{ .four, .accept, .down, .right, .accept, .zero, .zero, .zero }, // 8->6 (v>A)
        .{ .three, .accept, .left, .accept, .zero, .zero, .zero, .zero }, // 8->7 (<A)
        .{ .two, .accept, .accept, .zero, .zero, .zero, .zero, .zero }, // 8->8 (A)
        .{ .three, .accept, .right, .accept, .zero, .zero, .zero, .zero }, // 8->9 (>A)
        .{ .six, .accept, .down, .down, .down, .right, .accept, .zero }, // 8->accept (vvv>A)
        .{.zero} ** 8, // 8->left (unused)
        .{.zero} ** 8, // 8->up (unused)
        .{.zero} ** 8, // 8->down (unused)
        .{.zero} ** 8, // 8->right (unused)
    },
    .{
        .{ .six, .accept, .left, .down, .down, .down, .accept, .zero }, // 9->0 (<vvvA)
        .{ .six, .accept, .left, .left, .down, .down, .accept, .zero }, // 9->1 (<<vvA)
        .{ .five, .accept, .left, .down, .down, .accept, .zero, .zero }, // 9->2 (<vvA)
        .{ .four, .accept, .down, .down, .accept, .zero, .zero, .zero }, // 9->3 (vvA)
        .{ .five, .accept, .left, .left, .down, .accept, .zero, .zero }, // 9->4 (<<vA)
        .{ .four, .accept, .left, .down, .accept, .zero, .zero, .zero }, // 9->5 (<vA)
        .{ .three, .accept, .down, .accept, .zero, .zero, .zero, .zero }, // 9->6 (vA)
        .{ .four, .accept, .left, .left, .accept, .zero, .zero, .zero }, // 9->7 (<<A)
        .{ .three, .accept, .left, .accept, .zero, .zero, .zero, .zero }, // 9->8 (<A)
        .{ .two, .accept, .accept, .zero, .zero, .zero, .zero, .zero }, // 9->9 (A)
        .{ .five, .accept, .down, .down, .down, .accept, .zero, .zero }, // 9->accept (vvvA)
        .{.zero} ** 8, // 9->left (unused)
        .{.zero} ** 8, // 9->up (unused)
        .{.zero} ** 8, // 9->down (unused)
        .{.zero} ** 8, // 9->right (unused)
    },
    .{
        .{ .three, .accept, .left, .accept, .zero, .zero, .zero, .zero }, // accept->0 (<A)
        .{ .five, .accept, .up, .left, .left, .accept, .zero, .zero }, // accept->1 (^<<A)
        .{ .four, .accept, .left, .up, .accept, .zero, .zero, .zero }, // accept->2 (<^A)
        .{ .three, .accept, .up, .accept, .zero, .zero, .zero, .zero }, // accept->3 (^A)
        .{ .six, .accept, .up, .up, .left, .left, .accept, .zero }, // accept->4 (^^<<A)
        .{ .five, .accept, .left, .up, .up, .accept, .zero, .zero }, // accept->5 (<^^A)
        .{ .four, .accept, .up, .up, .accept, .zero, .zero, .zero }, // accept->6 (^^A)
        .{ .seven, .accept, .up, .up, .up, .left, .left, .accept }, // accept->7 (^^^<<A)
        .{ .six, .accept, .left, .up, .up, .up, .accept, .zero }, // accept->8 (<^^^A)
        .{ .five, .accept, .up, .up, .up, .accept, .zero, .zero }, // accept->9 (^^^A)
        .{ .two, .accept, .accept, .zero, .zero, .zero, .zero, .zero }, // accept->accept (A)
        .{ .five, .accept, .down, .left, .left, .accept, .zero, .zero }, // accept->left (v<<A)
        .{ .three, .accept, .left, .accept, .zero, .zero, .zero, .zero }, // accept->up (<A)
        .{ .four, .accept, .left, .down, .accept, .zero, .zero, .zero }, // accept->down (<vA)
        .{ .three, .accept, .down, .accept, .zero, .zero, .zero, .zero }, // accept->right (vA)
    },
    .{
        .{.zero} ** 8, // left->0 (unused)
        .{.zero} ** 8, // left->1 (unused)
        .{.zero} ** 8, // left->2 (unused)
        .{.zero} ** 8, // left->3 (unused)
        .{.zero} ** 8, // left->4 (unused)
        .{.zero} ** 8, // left->5 (unused)
        .{.zero} ** 8, // left->6 (unused)
        .{.zero} ** 8, // left->7 (unused)
        .{.zero} ** 8, // left->8 (unused)
        .{.zero} ** 8, // left->9 (unused)
        .{ .five, .accept, .right, .right, .up, .accept, .zero, .zero }, // left->accept (>>^A)
        .{ .two, .accept, .accept, .zero, .zero, .zero, .zero, .zero }, // left->left (A)
        .{ .four, .accept, .right, .up, .accept, .zero, .zero, .zero }, // left->up (>^A)
        .{ .three, .accept, .right, .accept, .zero, .zero, .zero, .zero }, // left->down (>A)
        .{ .four, .accept, .right, .right, .accept, .zero, .zero, .zero }, // left->right (>>A)
    },
    .{
        .{.zero} ** 8, // up->0 (unused)
        .{.zero} ** 8, // up->1 (unused)
        .{.zero} ** 8, // up->2 (unused)
        .{.zero} ** 8, // up->3 (unused)
        .{.zero} ** 8, // up->4 (unused)
        .{.zero} ** 8, // up->5 (unused)
        .{.zero} ** 8, // up->6 (unused)
        .{.zero} ** 8, // up->7 (unused)
        .{.zero} ** 8, // up->8 (unused)
        .{.zero} ** 8, // up->9 (unused)
        .{ .three, .accept, .right, .accept, .zero, .zero, .zero, .zero }, // up->accept (>A)
        .{ .four, .accept, .down, .left, .accept, .zero, .zero, .zero }, // up->left (v<A)
        .{ .two, .accept, .accept, .zero, .zero, .zero, .zero, .zero }, // up->up (A)
        .{ .three, .accept, .down, .accept, .zero, .zero, .zero, .zero }, // up->down (vA)
        .{ .four, .accept, .down, .right, .accept, .zero, .zero, .zero }, // up->right (v>A)
    },
    .{
        .{.zero} ** 8, // down->0 (unused)
        .{.zero} ** 8, // down->1 (unused)
        .{.zero} ** 8, // down->2 (unused)
        .{.zero} ** 8, // down->3 (unused)
        .{.zero} ** 8, // down->4 (unused)
        .{.zero} ** 8, // down->5 (unused)
        .{.zero} ** 8, // down->6 (unused)
        .{.zero} ** 8, // down->7 (unused)
        .{.zero} ** 8, // down->8 (unused)
        .{.zero} ** 8, // down->9 (unused)
        .{ .four, .accept, .up, .right, .accept, .zero, .zero, .zero }, // down->accept (^>A)
        .{ .three, .accept, .left, .accept, .zero, .zero, .zero, .zero }, // down->left (<A)
        .{ .three, .accept, .up, .accept, .zero, .zero, .zero, .zero }, // down->up (^A)
        .{ .two, .accept, .accept, .zero, .zero, .zero, .zero, .zero }, // down->down (A)
        .{ .three, .accept, .right, .accept, .zero, .zero, .zero, .zero }, // down->right (>A)
    },
    .{
        .{.zero} ** 8, // right->0 (unused)
        .{.zero} ** 8, // right->1 (unused)
        .{.zero} ** 8, // right->2 (unused)
        .{.zero} ** 8, // right->3 (unused)
        .{.zero} ** 8, // right->4 (unused)
        .{.zero} ** 8, // right->5 (unused)
        .{.zero} ** 8, // right->6 (unused)
        .{.zero} ** 8, // right->7 (unused)
        .{.zero} ** 8, // right->8 (unused)
        .{.zero} ** 8, // right->9 (unused)
        .{ .three, .accept, .up, .accept, .zero, .zero, .zero, .zero }, // right->accept (^A)
        .{ .four, .accept, .left, .left, .accept, .zero, .zero, .zero }, // right->left (<<A)
        .{ .four, .accept, .left, .up, .accept, .zero, .zero, .zero }, // right->up (<^A)
        .{ .three, .accept, .left, .accept, .zero, .zero, .zero, .zero }, // right->down (<A)
        .{ .two, .accept, .accept, .zero, .zero, .zero, .zero, .zero }, // right->right (A)
    },
};
