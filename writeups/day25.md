# Day 25: Code Chronicle

[Full solution](../src/days/day25.zig).

## Part one

Finally we have reached the last day. An easy puzzle to end the event! Here's what the input looks like:

```
#####
.####
.####
.####
.#.#.
.#...
.....

#####
##.##
.#.##
...##
...#.
...#.
.....

.....
#....
#....
#...#
#.#.#
#.###
#####
```

It's a list of locks and keys. Locks are the ones that have the top row filled with `#` and keys are the ones with the bottom rows filled. A lock and a key fit together if none of their pins overlap.

For part one, we have to count the number of unique lock and key combination that fit together. First, let's parse the input:

```zig
fn Day25() type {
    return struct {
        const Self = @This();

        locks: std.ArrayList(@Vector(5, u8)) = undefined,
        keys: std.ArrayList(@Vector(5, u8)) = undefined,

        fn init(input: []const u8, allocator: std.mem.Allocator) !Self {
            var result = Self{};

            result.locks = std.ArrayList(@Vector(5, u8)).init(allocator);
            result.keys = std.ArrayList(@Vector(5, u8)).init(allocator);

            var lexer = std.mem.tokenizeSequence(u8, input, "\n\n");
            while (lexer.next()) |key_or_lock| {
                var inner_lexer = std.mem.tokenizeScalar(u8, key_or_lock, '\n');

                const first_line = inner_lexer.next().?;
                var list = if (first_line[0] == '#') &result.locks else &result.keys;

                var heights: [5]u8 = .{0} ** 5;
                for (0..5) |_| {
                    for (inner_lexer.next().?, 0..) |pin, i| {
                        if (pin == '#') {
                            heights[i] += 1;
                        }
                    }
                }
                try list.append(heights);
            }

            return result;
        }
    };
}
```

We'll represent locks and keys as vectors of length five (one index for each pin height). These are then stored in a `std.ArrayList`.

The solution for part one is pretty straightforward. For every lock and key combination, we just have to check if they fit together. If they fit, increment the result counter. Here's the code:

```zig
fn part1(self: Self) u64 {
    var result: u64 = 0;
    for (self.locks.items) |lock| {
        for (self.keys.items) |key| {
            const fitted = lock + key > @as(@Vector(5, u8), @splat(5));
            const is_overlap = @reduce(.Or, fitted);
            if (!is_overlap) result += 1;
        }
    }
    return result;
}
```

For each key and lock combination, we add up the heights of the key pins and the lock pins. If any of the resulting heights are greater than five (the maximum height of a pin), it means we have an overlap. Today is a really great showcase of SIMD instructions in Zig! 

## Part two

Thank you for reading this far and congratulations for completing Advent of Code 2024!

## Benchmarks
