const std = @import("std");

const Gate = enum {
    band,
    bor,
    bxor,

    fn from_string(gate_string: []const u8) Gate {
        if (std.mem.eql(u8, gate_string, "AND")) return .band;
        if (std.mem.eql(u8, gate_string, "OR")) return .bor;
        if (std.mem.eql(u8, gate_string, "XOR")) return .bxor;
        unreachable;
    }

    fn compute(gate: Gate, x: bool, y: bool) bool {
        return switch (gate) {
            .band => x and y,
            .bor => x or y,
            .bxor => x != y,
        };
    }
};

fn Day24(length: usize) type {
    return struct {
        const Self = @This();

        wires: std.AutoHashMap(u24, bool) = undefined,
        expressions: [length][3]u24 = undefined,
        gates: [length]Gate = undefined,
        allocator: std.mem.Allocator,

        fn init(data: []const u8, allocator: std.mem.Allocator) !Self {
            var result = Self{ .allocator = allocator };

            result.wires = std.AutoHashMap(u24, bool).init(allocator);

            var lexer = std.mem.splitScalar(u8, data, '\n');
            while (lexer.next()) |line| {
                if (line.len == 0) break;
                try result.wires.put(wire_to_u24(line[0..3]), line[5] == '1');
            }

            var i: usize = 0;
            while (lexer.next()) |line| : (i += 1) {
                if (line.len == 0) break;

                var inner_lexer = std.mem.tokenizeScalar(u8, line, ' ');

                result.expressions[i][0] = wire_to_u24(inner_lexer.next().?);
                result.gates[i] = Gate.from_string(inner_lexer.next().?);
                result.expressions[i][1] = wire_to_u24(inner_lexer.next().?);

                _ = inner_lexer.next();

                result.expressions[i][2] = wire_to_u24(inner_lexer.next().?);
            }

            return result;
        }

        fn deinit(self: *Self) void {
            self.wires.deinit();
        }

        fn part1(self: *Self) !u64 {
            var z_count: usize = 0;
            for (self.expressions) |expression| {
                if (expression[2] >> 16 == 'z') z_count += 1;
            }

            var result: u64 = 0;
            while (z_count > 0) {
                for (self.expressions, self.gates) |expression, gate| {
                    const left, const right, const output = expression;

                    if (self.wires.contains(output)) continue;

                    const value_first = self.wires.get(left) orelse continue;
                    const value_second = self.wires.get(right) orelse continue;
                    const computed = gate.compute(value_first, value_second);

                    if (output >> 16 == 'z') {
                        const index = ((output >> 8) - '0') * 10 + ((output & 0xff) - '0');
                        const bit: u64 = if (computed) 1 else 0;

                        result |= bit << @intCast(index);
                        z_count -= 1;
                    }

                    try self.wires.put(output, computed);
                }
            }
            return result;
        }

        fn part2(self: Self) ![8]u24 {
            var wire_gates = std.AutoHashMap([2]u24, void).init(self.allocator);
            defer wire_gates.deinit();

            for (self.expressions, self.gates) |expression, gate| {
                try wire_gates.put(.{ expression[0], @intFromEnum(gate) }, {});
                try wire_gates.put(.{ expression[1], @intFromEnum(gate) }, {});
            }

            var result: [8]u24 = undefined;
            const x00 = 0x783030;
            const z45 = 0x7a3435;

            var i: usize = 0;
            for (self.expressions, self.gates) |expression, gate| {
                const left, const right, const output = expression;

                switch (gate) {
                    .band => {
                        if (left != x00 and right != x00 and
                            !wire_gates.contains(.{ output, @intFromEnum(Gate.bor) }))
                        {
                            result[i] = output;
                            i += 1;
                        }
                    },
                    .bor => {
                        if (output >> 16 == 'z' and output != z45 or
                            wire_gates.contains(.{ output, @intFromEnum(Gate.bor) }))
                        {
                            result[i] = output;
                            i += 1;
                        }
                    },
                    .bxor => {
                        if (left >> 16 == 'x' or right >> 16 == 'x') {
                            if (left != x00 and right != x00 and
                                !wire_gates.contains(.{ output, @intFromEnum(Gate.bxor) }))
                            {
                                result[i] = output;
                                i += 1;
                            }
                        } else {
                            if (output >> 16 != 'z') {
                                result[i] = output;
                                i += 1;
                            }
                        }
                    },
                }
            }

            std.mem.sort(u24, &result, {}, std.sort.asc(u24));
            return result;
        }

        fn wire_to_u24(wire: []const u8) u24 {
            return (@as(u24, wire[0]) << 16) + (@as(u16, wire[1]) << 8) + wire[2];
        }
    };
}

pub const title = "Day 24: Crossed Wires";

pub fn run(allocator: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    const input = @embedFile("./data/day24.txt");
    var puzzle = try Day24(222).init(input, allocator);
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
    \\x00: 1
    \\x01: 1
    \\x02: 1
    \\y00: 0
    \\y01: 1
    \\y02: 0
    \\
    \\x00 AND y00 -> z00
    \\x01 XOR y01 -> z01
    \\x02 OR y02 -> z02
;

test "day 24 part 1 sample 1" {
    var puzzle = try Day24(3).init(sample_input, std.testing.allocator);
    defer puzzle.deinit();
    const result = try puzzle.part1();
    try std.testing.expectEqual(4, result);
}

const sample_input2 =
    \\x00: 1
    \\x01: 0
    \\x02: 1
    \\x03: 1
    \\x04: 0
    \\y00: 1
    \\y01: 1
    \\y02: 1
    \\y03: 1
    \\y04: 1
    \\
    \\ntg XOR fgs -> mjb
    \\y02 OR x01 -> tnw
    \\kwq OR kpj -> z05
    \\x00 OR x03 -> fst
    \\tgd XOR rvg -> z01
    \\vdt OR tnw -> bfw
    \\bfw AND frj -> z10
    \\ffh OR nrd -> bqk
    \\y00 AND y03 -> djm
    \\y03 OR y00 -> psh
    \\bqk OR frj -> z08
    \\tnw OR fst -> frj
    \\gnj AND tgd -> z11
    \\bfw XOR mjb -> z00
    \\x03 OR x00 -> vdt
    \\gnj AND wpb -> z02
    \\x04 AND y00 -> kjc
    \\djm OR pbm -> qhw
    \\nrd AND vdt -> hwm
    \\kjc AND fst -> rvg
    \\y04 OR y02 -> fgs
    \\y01 AND x02 -> pbm
    \\ntg OR kjc -> kwq
    \\psh XOR fgs -> tgd
    \\qhw XOR tgd -> z09
    \\pbm OR djm -> kpj
    \\x03 XOR y03 -> ffh
    \\x00 XOR y04 -> ntg
    \\bfw OR bqk -> z06
    \\nrd XOR fgs -> wpb
    \\frj XOR qhw -> z04
    \\bqk OR frj -> z07
    \\y03 OR x01 -> nrd
    \\hwm AND bqk -> z03
    \\tgd XOR rvg -> z12
    \\tnw OR pbm -> gnj
;

test "day 24 part 1 sample 2" {
    var puzzle = try Day24(36).init(sample_input2, std.testing.allocator);
    defer puzzle.deinit();
    const result = try puzzle.part1();
    try std.testing.expectEqual(2024, result);
}
