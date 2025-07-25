# Day 25: Code Chronicle

[Full solution](../src/days/day25.zig).

## Puzzle Input

Finally we have reached the last day. A relatively easy puzzle to end the event!

Today's input is a list of **locks** and **keys**:

```plaintext
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

 Locks have their top row filled with `#` while keys have their bottom rows filled. We'll parse these into two arrays, one for the locks and one for the keys:
 
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
                        heights[i] += @intFromBool(pin == '#');
                    }
                }
                try list.append(heights);
            }

            return result;
        }

        fn deinit(self: Self) void {
            self.locks.deinit();
            self.keys.deinit();
        }
    };
}
```

We use the same representation for both locks and keys: a 5-length vector where each element represents the height of each pin in the lock or key.

## Part One

We need to count the number of **unique lock/key pair that fits together** without any pin overlap. Two pins overlap when their combined height is greater than the maximum pin height (which is 5).

The solution is pretty straightforward. For each lock and key pair, check if any of the pins overlap. If not, increment the result. This day is a great showcase of Zig's SIMD capabilities:

```zig
fn part1(self: Self) u64 {
    var result: u64 = 0;
    for (self.locks.items) |lock| {
        for (self.keys.items) |key| {
            const fitted = lock + key > @as(@Vector(5, u8), @splat(5));
            const is_overlap = @reduce(.Or, fitted);
            result += @intFromBool(!is_overlap);
        }
    }
    return result;
}
```


## Part Two

Thank you for reading this far and congratulations on completing Advent of Code 2024!

```zig
fn part2(_: Self) u64 {
    return 50;
}
```

## Benchmark

All benchmarks were performed on an [Apple M3 Pro](https://en.wikipedia.org/wiki/Apple_M3) with times in microseconds (µs).

| Part/Optimise | Debug (µs) | ReleaseSafe (µs) | ReleaseFast (µs) | ReleaseSmall (µs) |
|-------------- | ---------: | ---------------: | ---------------: | ----------------: |
| Parsing       | 696.7      | 45.2             | 24.9             | 60.3              |
| Part 1        | 189.1      | 66.8             | 0.0              | 0.0               |
| Part 2        | 0.0        | 0.0              | 0.0              | 0.0               |
| **Total**     | **885.9**  | **112.1**        | **24.9**         | **60.4**          |
