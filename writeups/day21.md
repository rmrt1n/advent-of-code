# Day 21: Keypad Conundrum

[Full solution](../src/days/day21.zig).

## Puzzle Input

Today's input is a list of **codes**:

```plaintext
029A
980A
179A
456A
379A
```

We'll store these codes in two different representations:

1. A 2D array of `Keypad` enum values. We prefix each code with an additional `A`. You'll understand why in part one.
2. A list of the numerical representation of the first three digits of the codes.

```zig
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
    };
}
```

The `Keypad` enum represents all the buttons on the **numeric keypad** and the **directional keypad**:

```zig
const Keypad = enum(u8) { n0, n1, n2, n3, n4, n5, n6, n7, n8, n9, accept, left, up, down, right };
```

And here's the layout of the two keypads:

```plaintext
Numeric keypad:       Directional keypad:

+---+---+---+             +---+---+
| 7 | 8 | 9 |             | ^ | A |
+---+---+---+         +---+---+---+
| 4 | 5 | 6 |         | < | v | > |
+---+---+---+         +---+---+---+
| 1 | 2 | 3 |
+---+---+---+
    | 0 | A |
    +---+---+
```

## Part One

We have to calculate the sum of the **complexities** of the five codes in the input. The complexity of a code is its numeric part multiplied by the length of the shortest button sequence needed to input it.

This sequence consists of the button presses on a directional keypad that we control. Between this and the numeric keypad are 2 layers of robots, each with a directional keypad. There can be multiple valid sequences to input the same code, but we only want the shortest one.

Robots start and end at the `A` buttons. They also can't move across empty space (under the `1` in the numerical keypad and above the `<` in the directional keypad).

We can solve this greedily by always choosing the best moves (the best button sequence) for every combination of source and destination keys, e.g. `A -> 1`, `2 -> 9`, `> -> A`, etc. After some experimentation, I found these rules for getting the best moves:

1. Always choose the shortest route from one key to another. No detours.
2. When multiple shortest routes exist, choose the one with repeating keys, e.g. prefer `^^>`, not `^>^`. The former results in shorter sequences the more robot layers we add. Here's an example for 1 robot layer:

    - `^^>` becomes `<AAV>A^A`.
    - `^>^` becomes `<Av>A<^A>A`.
    
    The sole exception to this rule is if you have to avoid an empty space.
3. If there are multiple shortest routes where it's not straightforward to know which is faster, e.g. `^^<` vs `<^^`,  choose buttons in this order:

    1. `<`.
    2. Either `^` or `v`, it doesn't matter.
    3. `>`.
    
    The reason for this is that we want to visit the farthest keys first. Since we must return to `A` at the end, we can visit other keys on our way back. For smaller robot layers sometimes this doesn't make a difference, but for larger layers (like in part two), this results in significantly shorter sequences.

Based on these rules, we can precompute the best moves for every key combination. Below are the best moves for the numerical keypad:

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

We'll hardcode this table as a global constant so that instruction lookups are $O(1)$:

```zig
const moves_capacity = 8;
const instructions: [15][15][moves_capacity]Keypad = .{
    .{
        .{ .n2, .accept, .accept, .n0, .n0, .n0, .n0, .n0 }, // 0->0 (A)
        .{ .n4, .accept, .up, .left, .accept, .n0, .n0, .n0 }, // 0->1 (^<A)
        // ....
    },
    // ...
}
```

`instructions` is a 15x15 grid (0-9, 4 directions, `A`), where the item at index $i,j$ contains the best moves sequence for moving from key $i$ to key $j$.

Since move sequences can have different lengths, we store each sequence’s length as its first element. This avoids hardcoding a separate length array, which can be more error-prone, plus it also makes the file longer.

Next, we'll create a function to get the shortest sequence length given a code and a depth (the number of robot layers).

Instead of building the list of sequences like in the puzzle description, we'll use a lanternfish algorithm and keep a frequency map of individual sequences. Since we're only choosing best moves, the map will only contain sequences defined in `instructions`.

We start from the numeric keypad and count sequences for each robot layer. In the end, what's left in the frequency map are the sequences that make up the final input. To get the answer, we just have to sum the lengths of these sequences.

Here's the code:

```zig
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
```

> [!NOTE]
> We used the same double-buffer technique introduced in day 11. In fact, the logic is almost identical, so I'll skip explaining it here. If you're curious, I recommend checking it out!

All we have to now is to call `get_sequence_length_for_depth` for all the codes in our input:

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

## Part Two

We still need to count the sum of the complexities of the codes in our input, but this time we have to go through **25 layers of robots**.

We can just tweak our `part1` function and change the depth to 25:

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

This makes three short part twos in a row!

## Benchmark

All benchmarks were performed on an [Apple M3 Pro](https://en.wikipedia.org/wiki/Apple_M3) with times in microseconds (µs).

| Part/Optimise | Debug (µs) | ReleaseSafe (µs) | ReleaseFast (µs) | ReleaseSmall (µs) |
|-------------- | ---------: | ---------------: | ---------------: | ----------------: |
| Parsing       | 0.7        | 0.1              | 0.0              | 0.1               |
| Part 1        | 41.4       | 2.7              | 1.7              | 2.1               |
| Part 2        | 566.2      | 33.0             | 22.4             | 27.9              |
| **Total**     | **608.2**  | **35.7**         | **24.2**         | **30.1**          |
