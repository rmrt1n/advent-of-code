# Day 24:

[Full solution](../src/days/day24.zig).

## Part one

In day 24 we're given a list of wires and bitwise expressions:

```
x00: 1
x01: 0
x02: 1
x03: 1
x04: 0
y00: 1
y01: 1
y02: 1
y03: 1
y04: 1

ntg XOR fgs -> mjb
y02 OR x01 -> tnw
kwq OR kpj -> z05
x00 OR x03 -> fst
tgd XOR rvg -> z01
vdt OR tnw -> bfw
bfw AND frj -> z10
```

The first section of the input lists all of the starting wires (`xXX`and `yXX`) and their values. The second part lists the bitwise expressions using the wires. There can be intermediary wires, e.g. `mjb`, `tnw`, etc.

For part one, we have to simulate the expressions to get a resulting number. This number is represented by the bits stored in the wires `zXX`. First, we'll parse the input:

```zig
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
    };
}
```

Here I stored the initial wires in a `std.AutoHashMap` because we're going to store the intermediary wires here too. It's dynamically size because we don't know how many intermediary wires we'll have. The operand and output wires are stored together in `expresssions` and the gates are stored in a parallel array `gates` with the same length. 

The gates are stored as enums with some helper functions for parsing and evaluating expressions:

```zig
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
```

I used `bool` for the bit values instead of integers so instead of the bitwise operators we used logical operators.

The wires are stored as `u24` instead of their string representation. A wire is a three character string. We can "concatenate" each character (a byte or 8 bits) into a larger 24-bit integer by shifting their bits:

```zig
fn wire_to_u24(wire: []const u8) u24 {
    return (@as(u24, wire[0]) << 16) + (@as(u16, wire[1]) << 8) + wire[2];
}
```

This makes checking values of the wires a bit more inconvient but speeds up the solution a bit.

Now for the simulation. This is a graph problem so you could use either BFS or DFS and both should work. Here I used a BFS approach but instead of storing the next nodes to visit in a queue, I just iterated over all of the expressions until all wire values have been filled:

```zig
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
```

First we iterate over the expressions once to count the number of the `z` wires. Then we'll keep iterating over the expressions and compute the values of the intermediary and output wires and store it in the `wires` map. If we have computed the values of all of the `z` wires, return the result.

## Part two

Day 24 is the hardest day from the entire event in my opinion. It starts out as a deceptively simple simulation problem that evolved into a nightmare reverse engineering problem. After a brutal 23 days, I didn't have enough brain power to push through with part two.

In part two it turns out four pairs of gates have been swapped. We need to find all swapped wires and sort them alphabetically. After scrolling Reddit I learned that this was a [ripple carry adder circuit](https://en.wikipedia.org/wiki/Adder_(electronics)#Ripple-carry_adder), or basically how to add two integers using bitwise operators.

Here's an example-based explanation of how it works. We'll use the example expression `12 + 13`.

This is how they look in binary:

```
 1100
 1101
----- +
11001
```

We'll start with the first bit. There are three possible scenarios:

1. Both input bits are off. The output bit is off. Nothing is carried over (the carry bit is off).
    ```
     0
     0
    -- +
     0
    ```
2. One input bit is on and the other is off. The output bit is on and the carry bit is off. Note, order doesn't matter here.
    ```
     0
     1
    -- +
     1
    ```
3. Both input bits are on. The output bit is off and the carry bit is on.
    ```
    1 <-- this is the carry bit
     1
     1
    -- +
     0
    ```

Just for the first bit (and also single bit additions), this is called a half adder. Based on the input bits, we can always know the value of the output and the carry bit. The rules are:

1. Output = A XOR B
2. Carry = A AND B

A and B are the input bits. I'll skip the explanation as to why these are the rules. If you look at the rules and stare at the examples from above, it'll make sense soon!

Then, we have the full adder. This is when at the start we already have a carry bit. Now, there are six possible scenarios:

1. Carry bit is off and both input bits are off. Output bit and (the next) carry bit is off.
    ```
     0
     0
     0
    -- +
     0
    ```
2. Carry bit is off and one input bit is on and the other is off. Output bit is on and carry bit is off.
    ```
     0
     0
     1
    -- +
     1
    ```
3. Carry bit is off and both input bits are on. Output bit is off and the carry bit is on.
    ```
    10
     1
     1
    -- +
     0
    ```
4. Carry bit is on and both input bits are off. Output bit is on and the carry bit is off.
    ```
     1
     0
     0
    -- +
     1
    ```
5. Carry bit is on and one input bit is on and the other is off. Output bit is off and carry bit is on.
    ```
    11
     0
     1
    -- +
     0
    ```
6. Carry bit is off on both input bits are on. Output bit is on and the carry bit is on.
    ```
    11
     1
     1
    -- +
     0
    ```

From these, we can infer the following rules:

1. Output = A XOR B XOR C
2. Carry = (A AND B) OR (C ^ (A XOR B))

C is the carry bit. In total, we now have four rules that must be true for a correct ripple carry adder circuit. To solve part two, we just have to find the eight expressions that violate any of these rules.

Well, the rules above are just for the wires that contain the values for the output and the carry bits. There are intermediary wires for the full adders. I couldn't figure out a set of rules that would work given the gate and the output of an expression. In the end, I copied the rules from [someone else's solution](https://github.com/maneatingape/advent-of-code-rust/blob/main/src/year2024/day24.rs):

1. **XOR** If inputs are `x` and `y` then output must be another XOR gate (except for inputs `x00` and `y00`) otherwise output must be `z`.
2. **AND** Output must be an OR gate (except for inputs `x00` and `y00`).
3. **OR** Output must be both AND and XOR gate, except for final carry which must output to `z45`.

With this, we can now implement the solution:

```zig
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
```

This was just a Zig translation of @maneatingape's solution. I'm still frustrated I couldn't come up with this myself.

## Benchmarks
