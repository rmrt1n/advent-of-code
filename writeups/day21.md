# Day 21: Keypad Conundrum

[Full solution](../src/days/day21.zig).

## Part one

Another one of my favorite puzzles. The input file looks like this:

```
029A
980A
179A
456A
379A
```

Each line is a code we have to input into a numpad. They twist here is that this numpad is control by a directional keypad, which is controlled by another robot with a directional keypad, which is controlled by another directional keypad that is controlled by us. These keypads look like this:

```
Numerical keypad:

+---+---+---+
| 7 | 8 | 9 |
+---+---+---+
| 4 | 5 | 6 |
+---+---+---+
| 1 | 2 | 3 |
+---+---+---+
    | 0 | A |
    +---+---+

Directional keypad:

    +---+---+
    | ^ | A |
+---+---+---+
| < | v | > |
+---+---+---+
```

The initial position of the robots controlling the keypads are at the `A` button. Since the numerical keypad can only be clicked by a robot using the directional keypad, after moving to a button in the numerical keypad, we have to press the `A` button in the directional keypad to press the button in the numerical keypad. Also, robots can't move across empty space (under the `1` in the numerical keypad and above the `<` in the directional keypad).

For part one we have to find the sum of the **complexities** of the five codes in the input file. A complexity of a code is the length of the shortest sequence to create it multiplied by the numeric part of the code.

First, lets parse the input:

```zig
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
    };
}
```

Here I parsed prefixed each code with a `A`, so `029A` becomes `A029A`. The reason for this will become apparent when we get to the solution code.

Now, for the solution. My first thought (which luckily turned out to be correct) was that we can solve this greedily by always choosing the best moves. As long as we choose the best combination of keys, we will always reach the shortest sequence. The hard part was figuring out the best move.

I spent quite a while experimenting with the best moves, and the result are these rules:

1. Always choose the shortest route from key A to key B. No unnecessary detours.
2. When there are multiple shortest routes, choose the one with repeating keys, e.g. do `^^>`, not `^>^`. The former results in shorter sequences the more robot layers we add. At 1 robot layer, `^^>` becomes `<AAV>A^A`, but `^>^` becomes `<Av>A<^A>A` (we start and end from `A`). The sole exception is if you have to avoid the empty space.
3. If there are multiple shortest routes with where it's not so straightforward which is faster, e.g. `^^<` vs `<^^`, follow this order:
    a. `<`,
    b. Either `^` or `v`, it doesn't matter,
    c. `>`
    The reason for this is that we want to go to the farthest keys first in the directional keypad. Because we have to return to the `A` key at the end, we can visit the other keys on our way back. For lower robot layers sometimes this doesn't make a difference, but for larger layers (like in part two), this makes a lot of difference.

From these rules, we can precompute the best moves for every key combination. Below are the best moves for the numerical keypad:

| From\To | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | A |
|---------|---|---|---|---|---|---|---|---|---|---|---|
| **0** | A | ^<A | ^A | ^>A | ^^<A | ^^A | ^^>A | ^^^<A | ^^^A | ^^^>A | >A |
| **1** | >vA | A | >A | >>A | ^A | ^>A | ^>>A | ^^A | ^^>A | ^^>>A | >>vA |
| **2** | vA | <A | A | >A | <^A | ^A | ^>A | <^^A | ^^A | ^^>A | v>A |
| **3** | <vA | <<A | <A | A | <<^A | <^A | ^A | <<^^A | <^^A | ^^A | vA |
| **4** | >vvA | vA | v>A | v>>A | A | >A | >>A | ^A | ^>A | ^>>A | >>vvA |
| **5** | vvA | <vA | vA | v>A | <A | A | >A | <^A | ^A | ^>A | vv>A |
| **6** | <vvA | <<vA | <vA | vA | <<A | <A | A | <<^A | <^A | ^A | vvA |
| **7** | >vvvA | vvA | vv>A | vv>>A | vA | v>A | v>>A | A | >A | >>A | >>vvvA |
| **8** | vvvA | <vvA | vvA | vv>A | <vA | vA | v>A | <A | A | >A | vvv>A |
| **9** | <vvvA | <<vvA | <vvA | vvA | <<vA | <vA | vA | <<A | <A | A | vvvA |
| **A** | <A | ^^<<A | <^A | ^A | ^^<<A | <^^A | ^^A | ^^^<<A | <^^^A | ^^^A | A |

And here are the best moves for the directional keypad:

| From\To | < | ^ | v | > | A |
|---------|---|---|---|---|---|
| **<** | A | >^A | >A | >>A | >>^A |
| **^** | v<A | A | vA | v>A | >A |
| **v** | <A | ^A | A | >A | ^>A |
| **>** | <<A | <^A | <A | A | ^A |
| **A** | v<<A | <A | <vA | vA | A |

I hardcoded this table as a global variable so that instruction lookups are O(1):

```zig
const Keypad = enum(u8) { zero, one, two, three, four, five, six, seven, eight, nine, accept, left, up, down, right };

const instructions: [15][15][8]Keypad = .{
    .{
        .{ .two, .accept, .accept, .zero, .zero, .zero, .zero, .zero }, // 0->0
        .{ .four, .accept, .up, .left, .accept, .zero, .zero, .zero }, // 0->1
        // ....
    },
    // ...
}
```

The `instructions` is a 15x15 matrix (0-9 + 4 directions + A), where the item at index `i,j` contains the best moves for moving from key `i` to key `j`. Since different best move sequences can have different number of moves, the best move array's first element specifies it's length (length-prefixed). Please refer to the [full solution file](../src/days/day21.zig) for the whole table.

Next, we just have to write the function to simulate the robots clicking for a given code. We'll make a function with the number of robots as a parameter (we'll need this in part two):

```zig
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
```

A bit long, so I'll explain by section. The first section initializes a frequency map of instruction sequences. Since building the whole instruction string will be very inefficient, we just store sequences from `instructions` with a counter of how many times they show up:

```zig
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
    // ...
}
```

The first items we insert to the map are the best moves of the key combinations from the original code. This is the reason why we prefixed each code with a `A`, because the first key combination always start with `A`.

Next, we have have to iterate over every sequence in `frequencies`, get a new frequency map of sequences, and repeat until we have reached the required number of robots (`depth`):

```zig
fn get_sequence_length_for_depth(self: Self, code: []const Keypad, depth: u8) !u64 {
    // ...
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
    // ...
}
```

Finally, we just have to sum up the length of each sequence in the map multiplied by its frequency to get the total length of the shortest sequence:

```zig
fn get_sequence_length_for_depth(self: Self, code: []const Keypad, depth: u8) !u64 {
    // ...
    var length: u64 = 0;
    var it = frequencies.iterator();
    while (it.next()) |e| {
        length += (e.key_ptr.*.len - 1) * e.value_ptr.*;
    }
    return length;
}
```

And that's all we need. Our part one is solved:

```zig
fn part1(self: Self) !u64 {
    var result: u64 = 0;
    for (self.codes, self.numbers) |code, number| {
        const length = try self.get_sequence_length_for_depth(&code, 2);
        result += length * number;
    }
    return result;
}
```

## Part two

In part two, instead of two intermediary robots, the number of robots is increased to 25. We did all the hard work in part one and also made `get_sequence_length_for_depth` take in a `depth` parameter, so part two is as simple as changing the arguments we pass to the function:

```zig
fn part2(self: Self) !u64 {
    var result: u64 = 0;
    for (self.codes, self.numbers) |code, number| {
        const length = try self.get_sequence_length_for_depth(&code, 25);
        result += length * number;
    }
    return result;
}
```

## Benchmarks
