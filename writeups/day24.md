# Day 24: Crossed Wires

[Full solution](../src/days/day24.zig).

## Puzzle Input

Today's input is a list of **wires** and **bitwise expressions**:

```plaintext
x00: 1
x01: 1
x02: 1
y00: 0
y01: 1
y02: 0

x00 AND y00 -> z00
x01 XOR y01 -> z01
x02 OR y02 -> z02
```

The first section lists the starting wires (`xNN`and `yNN`) and their initial values. The second part lists the bitwise expressions that uses these wires. There can be intermediary wires, e.g. `mjb`, `tnw`, etc.

We'll parse the wires into a hash map `std.AutoHashMap` and store the expressions in two separate arrays: one for the wire operands and results, and the other for the gate operators. We split them just because they're types are different:

```zig
fn Day24(length: usize) type {
    return struct {
        const Self = @This();

        wires: std.AutoHashMap(Wire, bool) = undefined,
        expressions: [length][3]Wire = undefined,
        gates: [length]Gate = undefined,
        allocator: std.mem.Allocator,

        fn init(data: []const u8, allocator: std.mem.Allocator) !Self {
            var result = Self{ .allocator = allocator };

            result.wires = std.AutoHashMap(Wire, bool).init(allocator);

            var lexer = std.mem.splitScalar(u8, data, '\n');
            while (lexer.next()) |line| {
                if (line.len == 0) break;
                try result.wires.put(Wire.init(line[0..3]), line[5] == '1');
            }

            var i: usize = 0;
            while (lexer.next()) |line| : (i += 1) {
                if (line.len == 0) break;

                var inner_lexer = std.mem.tokenizeScalar(u8, line, ' ');

                result.expressions[i][0] = Wire.init(inner_lexer.next().?);
                result.gates[i] = Gate.init(inner_lexer.next().?);
                result.expressions[i][1] = Wire.init(inner_lexer.next().?);

                _ = inner_lexer.next();

                result.expressions[i][2] = Wire.init(inner_lexer.next().?);
            }

            return result;
        }

        fn deinit(self: *Self) void {
            self.wires.deinit();
        }
    };
}
```

Wires are represented as a packed struct where each character stored in its own field. This type has the same size as a 24-bit integer `u24` and in some cases can be used interchangeably:

```zig
const Wire = packed struct(u24) {
    c0: u8,
    c1: u8,
    c2: u8,

    fn init(wire: []const u8) Wire {
        return Wire{ .c0 = wire[0], .c1 = wire[1], .c2 = wire[2] };
    }
};
```

We represent the gates as an enum:

```zig
const Gate = enum {
    band, bor, bxor,

    fn init(gate_string: []const u8) Gate {
        if (std.mem.eql(u8, gate_string, "AND")) return .band;
        if (std.mem.eql(u8, gate_string, "OR")) return .bor;
        if (std.mem.eql(u8, gate_string, "XOR")) return .bxor;
        unreachable;
    }
};
```

## Part One

We have to find the **resulting number** after simulating the system of gates and wires. The output is stored in the wires that start with `z`.

The expressions are essentially a directed graph with "layers", where each layer is composed of the expressions for a single step of the simulation. We can find the output by traversing each layer of this graph and calculating the values of the intermediary wires until we reach the output wires.

Here's the code:

```zig
fn part1(self: *Self) !u64 {
    var z_count: usize = 0;
    for (self.expressions) |expression| {
        if (expression[2].c0 == 'z') z_count += 1;
    }

    var result: u64 = 0;
    while (z_count > 0) {
        for (self.expressions, self.gates) |expression, gate| {
            const left, const right, const output = expression;

            if (self.wires.contains(output)) continue;

            const value_first = self.wires.get(left) orelse continue;
            const value_second = self.wires.get(right) orelse continue;
            const computed = gate.compute(value_first, value_second);

            if (output.c0 == 'z') {
                const index = (output.c1 - '0') * 10 + (output.c2 - '0');
                result |= @as(u64, @intFromBool(computed)) << @intCast(index);
                z_count -= 1;
            }

            try self.wires.put(output, computed);
        }
    }
    return result;
}
```

We update the result number one bit at a time as we loop through the expressions instead of doing a final pass on the `wires` map at the end.

We also defined a helper method on `Gate` to compute the result of an expression:

```zig
const Gate = enum {
    // ...
    
    fn compute(gate: Gate, x: bool, y: bool) bool {
        return switch (gate) {
            .band => x and y,
            .bor => x or y,
            .bxor => x != y,
        };
    }
};
```

## Part Two

We have to find **eight swapped wires** in the system of gates and wires.

It turns out the whole system is a [ripple-carry adder circuit](https://en.wikipedia.org/wiki/Adder_(electronics)#Ripple-carry_adder), a digital circuit that adds two numbers using just bitwise operations. The twist here is that the output is wrong because 4 pairs of wires have been swapped.

To find the swapped wires, we first have to understand how a ripple-carry adder works, in particular, its components: a half adder (for the first bit) and multiple full adders (for the remaining bits).

I'll use the expression $12 + 13$ as an example to illustrate.

This is what they look like in binary:

```plaintext
 1100
 1101
----- +
11001
```

First we'll look at the **half adder**. A half adder takes two input bits and produces a sum and a carry-out. There are three possible input combinations:

1. `0 + 0` -> sum = 0, carry-out = 0.
2. `1 + 0` -> sum = 1, carry-out = 0. This is the same as `0 + 1`, order doesn't matter.
3. `1 + 1` -> sum = 0, carry-out = 1.

From these, we can infer these rules:

1. `sum(a, b) = a ^ b`.
2. `carry(a, b) = a & b`.

Next, we'll look at the **full adder**. A full adder takes three inputs: two input bits and a carry-in bit. It produces a sum and a carry-out. There are six possible input combinations (the third bit is the carry-in):

1. `0 + 0 + 0` -> sum = 0, carry-out = 0.
2. `1 + 0 + 0` -> sum = 1, carry-out = 0.
3. `1 + 1 + 0` -> sum = 0, carry-out = 1.
4. `0 + 0 + 1` -> sum = 1, carry-out = 0.
5. `1 + 0 + 1` -> sum = 0, carry-out = 1.
6. `1 + 1 + 1` -> sum = 1, carry-out = 1.

From these, we can infer these rules:

1. `sum(a, b, c) = a ^ b ^ c`.
2. `carry(a, b, c) = (a & b) | ((a ^ b) ^ c)`

We can use the rules for the half and full adders to create a rule to detect a swapped wire in an expression:

1. If the output wire starts with `z`, the gate must be an XOR gate, except for `z45` which is actually the carry-out of the 43rd full adder, and must use an OR gate.
2. If the output wire doesn't start with `z`, and the operands aren't `xNN` or `yNN`, the gate must be either AND or OR, never XOR.

Unfortunately, just applying these rules only identifies 6 incorrect wires. To find the remaining two, we need a bit of "lookahead": we analyze not only the current gate, but how its output is used.

Unfortunately we can only get 6 wires from this approach. There are [several ways to get the other two](https://www.reddit.com/r/adventofcode/comments/1hla5ql/2024_day_24_part_2_a_guide_on_the_idea_behind_the/), but one elegant approach I found is to also check the expressions that uses the output of the current one.

This approach come's from [@maneatingape's](https://github.com/maneatingape) [solution](https://github.com/maneatingape/advent-of-code-rust/blob/main/src/year2024/day24.rs). Instead of the previous rules, these are the rules we'll follow:

1. **XOR**: If the inputs are `xNN` and `yNN` then output must be another XOR gate (except for inputs `x00` and `y00`). Otherwise, the output wire must be a `zNN`.
2. **AND**: The output must be an OR gate (except for inputs `x00` and `y00`).
3. **OR**: The output must be both AND and XOR gate, except for final carry which must output to `z45`.

Now for the solution. We first create a set of wire-gate pairs. Then, we iterate through all expressions and validate each one using the above rules. If an expression violates a rule, we add its output wire to the results array. Finally, we sort the array and return it.

Here's the code:

```zig
fn part2(self: Self) ![8]u24 {
    var wire_gates = std.AutoHashMap([2]u24, void).init(self.allocator);
    defer wire_gates.deinit();

    for (self.expressions, self.gates) |expression, gate| {
        try wire_gates.put(.{ @bitCast(expression[0]), @intFromEnum(gate) }, {});
        try wire_gates.put(.{ @bitCast(expression[1]), @intFromEnum(gate) }, {});
    }

    const x00 = Wire.init("x00");
    const z45 = Wire.init("z45");

    var result: [8]u24 = undefined;
    var i: usize = 0;
    for (self.expressions, self.gates) |expression, gate| {
        const left, const right, const output = expression;

        switch (gate) {
            .band => {
                if (left != x00 and right != x00 and
                    !wire_gates.contains(.{ @bitCast(output), @intFromEnum(Gate.bor) }))
                {
                    result[i] = output.to_big_endian_u24();
                    i += 1;
                }
            },
            .bor => {
                if (output.c0 == 'z' and output != z45 or
                    wire_gates.contains(.{ @bitCast(output), @intFromEnum(Gate.bor) }))
                {
                    result[i] = output.to_big_endian_u24();
                    i += 1;
                }
            },
            .bxor => {
                if (left.c0 == 'x' or right.c0 == 'x') {
                    if (left != x00 and right != x00 and
                        !wire_gates.contains(.{ @bitCast(output), @intFromEnum(Gate.bxor) }))
                    {
                        result[i] = output.to_big_endian_u24();
                        i += 1;
                    }
                } else {
                    if (output.c0 != 'z') {
                        result[i] = output.to_big_endian_u24();
                        i += 1;
                    }
                }
            },
        }
    }

    std.mem.sort(u24, &result, {}, std.sort.asc(u24));
    return result;
}
```

Because packed structs can have different memory layouts depending on system endianness, we add a method to convert a `Wire` to the correct representation, which is big-endian in our case:

```zig
const Wire = packed struct(u24) {
    const endian = builtin.target.cpu.arch.endian();

    // ...

    fn to_big_endian_u24(wire: Wire) u24 {
        if (endian == .big) return @bitCast(wire);
        return (@as(u24, wire.c0) << 16) + (@as(u16, wire.c1) << 8) + wire.c2;
    }
};
```

## Benchmark

All benchmarks were performed on an [Apple M3 Pro](https://en.wikipedia.org/wiki/Apple_M3) with times in microseconds (µs).

| Debug | ReleaseSafe | ReleaseFast | ReleaseSmall |
| ----- | ----------- | ----------- | ------------ |
|       |             |             |              |
