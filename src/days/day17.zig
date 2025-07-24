const std = @import("std");

fn Day17(length: usize) type {
    return struct {
        const Self = @This();
        const Opcode = enum { adv, bxl, bst, jnz, bxc, out, bdv, cdv };
        const Registers = struct {
            a: u64,
            b: u64,
            c: u64,
        };

        registers: Registers = undefined,
        instructions: [length]u3 = undefined,
        ip: usize = 0,
        allocator: std.mem.Allocator = undefined,

        fn init(input: []const u8, allocator: std.mem.Allocator) !Self {
            var result = Self{ .allocator = allocator };

            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            result.registers.a = try std.fmt.parseInt(u64, lexer.next().?[12..], 10);
            result.registers.b = try std.fmt.parseInt(u64, lexer.next().?[12..], 10);
            result.registers.b = try std.fmt.parseInt(u64, lexer.next().?[12..], 10);

            var i: usize = 0;
            lexer = std.mem.tokenizeScalar(u8, lexer.next().?[9..], ',');
            while (lexer.next()) |line| : (i += 1) {
                result.instructions[i] = try std.fmt.parseInt(u3, line, 10);
            }

            return result;
        }

        fn part1(self: *Self) !std.ArrayList(u3) {
            var result = std.ArrayList(u3).init(self.allocator);
            try self.run(&result);
            return result;
        }

        fn part2(self: *Self) !u64 {
            var queue = std.ArrayList(u64).init(self.allocator);
            defer queue.deinit();

            try queue.append(0);

            var output = std.ArrayList(u3).init(self.allocator);
            defer output.deinit();

            for (1..(length + 1)) |i| {
                const queue_length = queue.items.len;
                for (0..queue_length) |_| {
                    const candidate = queue.pop().? * 8;
                    for (candidate..(candidate + 8)) |next_candidate| {
                        // Clear output array and reset computer state.
                        output.clearRetainingCapacity();
                        self.reset();
                        self.registers.a = next_candidate;

                        try self.run(&output);

                        // We build a in a reverse order, so compare against the end of the program.
                        if (std.mem.eql(u3, output.items[0..], self.instructions[(length - i)..])) {
                            // This is O(n), but in practice it results in the same speed as using
                            // a separate array to store the next "level" (to append the the queue).
                            try queue.insert(0, next_candidate);
                        }
                    }
                }
            }

            std.mem.sort(u64, queue.items, {}, std.sort.asc(u64));
            return queue.items[0];
        }

        fn run(self: *Self, output: *std.ArrayList(u3)) !void {
            while (self.ip < self.instructions.len) {
                const opcode: Opcode = @enumFromInt(self.instructions[self.ip]);
                switch (opcode) {
                    .adv => {
                        const operand = self.get_operand(true);
                        const numerator = self.registers.a;
                        const denumerator = std.math.pow(u64, 2, operand);
                        self.registers.a = numerator / denumerator;
                    },
                    .bxl => {
                        const operand = self.get_operand(false);
                        self.registers.b ^= operand;
                    },
                    .bst => {
                        const operand = self.get_operand(true);
                        self.registers.b = operand % 8;
                    },
                    .jnz => {
                        if (self.registers.a != 0) {
                            self.ip = self.instructions[self.ip + 1];
                        } else {
                            self.ip += 2;
                        }
                    },
                    .bxc => {
                        self.registers.b ^= self.registers.c;
                        self.ip += 2;
                    },
                    .out => {
                        const operand = self.get_operand(true);
                        try output.append(@intCast(operand % 8));
                    },
                    .bdv => {
                        const operand = self.get_operand(true);
                        const numerator = self.registers.a;
                        const denumerator = std.math.pow(u64, 2, operand);
                        self.registers.b = numerator / denumerator;
                    },
                    .cdv => {
                        const operand = self.get_operand(true);
                        const numerator = self.registers.a;
                        const denumerator = std.math.pow(u64, 2, operand);
                        self.registers.c = numerator / denumerator;
                    },
                }
            }
        }

        fn get_operand(computer: *Self, is_combo: bool) u64 {
            defer computer.ip += 1;
            computer.ip += 1;

            const operand = computer.instructions[computer.ip];
            if (!is_combo) return operand;

            return switch (operand) {
                0, 1, 2, 3 => operand,
                4 => computer.registers.a,
                5 => computer.registers.b,
                6 => computer.registers.c,
                7 => unreachable, // reserved
            };
        }

        fn reset(self: *Self) void {
            self.registers.a = 0;
            self.registers.b = 0;
            self.registers.c = 0;
            self.ip = 0;
        }
    };
}

fn format_part1(allocator: std.mem.Allocator, answer: std.ArrayList(u3)) ![]const u8 {
    const length = answer.items.len;
    var buffer = try allocator.alloc(u8, length * 2 - 1);

    for (answer.items[0..(length - 1)], 0..) |number, i| {
        buffer[i * 2] = @as(u8, number) + '0';
        buffer[i * 2 + 1] = ',';
    }
    buffer[buffer.len - 1] = @as(u8, answer.items[length - 1]) + '0';

    return buffer;
}

pub const title = "Day 17: Chronospatial Computer";

pub fn run(allocator: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    const input = @embedFile("./data/day17.txt");
    var puzzle = try Day17(16).init(input, allocator);
    const time0 = timer.read();

    const result1 = try puzzle.part1();
    defer result1.deinit();
    const time1 = timer.read();

    const result2 = try puzzle.part2();
    const time2 = timer.read();

    const result1_string = try format_part1(allocator, result1);
    defer allocator.free(result1_string);

    if (is_run) {
        std.debug.print("Part 1: {s}\nPart 2: {d}\n", .{ result1_string, result2 });
    }

    return .{ time0, time1, time2 };
}

const sample_input =
    \\Register A: 729
    \\Register B: 0
    \\Register C: 0
    \\
    \\Program: 0,1,5,4,3,0
;

test "day 17 part 1 sample 1" {
    var puzzle = try Day17(6).init(sample_input, std.testing.allocator);
    const result = try puzzle.part1();
    defer result.deinit();
    try std.testing.expectEqualSlices(u3, &[_]u3{ 4, 6, 3, 5, 6, 3, 5, 2, 1, 0 }, result.items);
}
