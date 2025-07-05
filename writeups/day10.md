# Day 10: Hoof It

[Full solution](../src/days/day10.zig).

## Puzzle Input

Today's input is a **topographic map** of an island:

```plaintext
0123
1234
8765
9876
```

We'll parse the input into a 2D array and convert each character into its numeric value. We'll also add a border of `10`s around it to simplify out of bounds checks. We'll also store the trailhead `0` positions in a list `std.ArrayList`:

```zig
fn Day10(length: usize) type {
    return struct {
        const Self = @This();

        const map_size = length + 2; // Add borders
        const directions = [_]@Vector(2, u1){ .{ 1, 0 }, .{ 0, 1 } };

        map: [map_size][map_size]u8 = .{.{10} ** map_size} ** map_size,
        trail_heads: std.ArrayList([2]u8) = undefined,
        allocator: std.mem.Allocator,

        fn init(input: []const u8, allocator: std.mem.Allocator) !Self {
            var result = Self{ .allocator = allocator };

            result.trail_heads = std.ArrayList([2]u8).init(allocator);

            var i: usize = 1;
            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                for (line, 1..) |c, j| {
                    const height = c - '0';
                    if (height == 0) try result.trail_heads.append(.{ @intCast(i), @intCast(j) });
                    result.map[i][j] = height;
                }
            }

            return result;
        }

        fn deinit(self: Self) void {
            self.trail_heads.deinit();
        }
    };
}
```

> [!TIP]
> We could've also used a regular array to store the trailhead positions, and store its length in another field. I benchmarked both approaches and found the current code to be faster (and also easier to read), so I'll keep it as is.

## Part One

We have to find the sum of the **trailhead scores** on the map. A trailhead's score is the number of unique peaks `9` reachable from it by following a path that increases elevation by exactly one each step.

We can use [depth-first search (DFS)](https://en.wikipedia.org/wiki/Depth-first_search) to explore all valid paths from the trailhead. When we have found a peak, we add it to a set to ensure we have unique peaks. The answer to part one is the number of items in this set:

```zig
const stack_capacity = 544;
const directions = [_]@Vector(2, u1){ .{ 1, 0 }, .{ 0, 1 } };

// Iterative solution is much faster than recursive.
fn part1(self: Self) !u64 {
    var result: u64 = 0;
    var stack: [stack_capacity][2]u8 = undefined;

    var trail_ends = std.AutoHashMap([2]u8, void).init(self.allocator);
    defer trail_ends.deinit();

    for (self.trail_heads.items) |trail_head| {
        stack[0] = trail_head;
        trail_ends.clearRetainingCapacity();

        var stack_length: usize = 1;
        while (stack_length > 0) {
            stack_length -= 1;

            const position = stack[stack_length];
            const tile = self.map[position[0]][position[1]];

            // Duplicating the code here results in much faster runtime vs using 4 i8
            // direction vectors. I'm not completely sure why, but I'll take this extra
            // code verbosity for the increased performance.
            for (directions) |direction| {
                const forwards = position + direction;
                var next_tile = self.map[forwards[0]][forwards[1]];
                if (next_tile != 10 and next_tile - tile == 1) {
                    if (next_tile == 9) {
                        try trail_ends.put(forwards, {});
                    } else {
                        stack[stack_length] = forwards;
                        stack_length += 1;
                    }
                }

                const backwards = position - direction;
                next_tile = self.map[backwards[0]][backwards[1]];
                if (next_tile != 10 and next_tile - tile == 1) {
                    if (next_tile == 9) {
                        try trail_ends.put(backwards, {});
                    } else {
                        stack[stack_length] = backwards;
                        stack_length += 1;
                    }
                }
            }
        }

        result += trail_ends.count();
    }

    return result;
}
```

The DFS is implemented iteratively instead of using recursion to avoid the overhead of allocating call stacks. There's a bit of duplication in the for loop, but after some benchmarks I've found this to be faster than doing something like:

```zig
const directions = [_]@Vector(2, i8){ .{ -1, 0 }, .{ 0, 1 }, .{ 1, 0 }, .{ 0, -1 } };

for (directions) |direction| {
    const next_position = position + direction;
    const next_tile = self.map[next_position[0]][next_position[1]];
    if (next_tile != 10 and next_tile - tile == 1) {
        if (next_tile == 9) {
            try trail_ends.put(next_position, {});
        } else {
            stack[stack_length] = next_position;
            stack_length += 1;
        }
    }
}
```

> [!NOTE]
> I'm not sure exactly why, but my guess is that the original code has a more predictable branch pattern than the second one. Unless you know how your code compiles to machine code, it's usually better to benchmark to guide performance-related decisions.

> [!TIP]
> The minimum stack capacity I used is the maximum number of items it can hold if we never pop any items. This happens when all of a tile's neighbours is one step above it in elevation, e.g.:
>
> ```
> 98765456789
> 87654345678
> 76543234567
> 65432123456
> 54321012345
> 65432123456
> 76543234567
> 87654345678
> 98765456789
> ```
>
> Starting from a trailhead, there are four initial tiles to reach. Each tile after can only reach three directions (forwards, left, and right. We don't go backwards). The capacity becomes:
> 
> $$4 + (3 \cdot 4 \cdot 1) + (3 \cdot 4 \cdot 2) + ... + (3 \cdot 4 \cdot 9) = 544$$

## Part Two

We have to find the sum of the **trailhead ratings** on the map. A trailhead's rating is the number of unique paths that reaches a peak.

We only have to modify our part one code a little bit to work for part two. Now, instead of using a set to track unique peak positions, we'll directly increment the total result everytime we find a valid path that reaches a peak:

```zig
fn part2(self: Self) u64 {
    var result: u32 = 0;
    var stack: [stack_capacity][2]u8 = undefined;

    for (self.trail_heads.items) |trail_head| {
        stack[0] = trail_head;

        var stack_length: usize = 1;
        while (stack_length > 0) {
            stack_length -= 1;

            const position = stack[stack_length];
            const tile = self.map[position[0]][position[1]];

            for (directions) |direction| {
                const forwards = position + direction;
                var next_tile = self.map[forwards[0]][forwards[1]];
                if (next_tile != 10 and next_tile - tile == 1) {
                    if (next_tile == 9) {
                        result += 1;
                    } else {
                        stack[stack_length] = forwards;
                        stack_length += 1;
                    }
                }

                const backwards = position - direction;
                next_tile = self.map[backwards[0]][backwards[1]];
                if (next_tile != 10 and next_tile - tile == 1) {
                    if (next_tile == 9) {
                        result += 1;
                    } else {
                        stack[stack_length] = backwards;
                        stack_length += 1;
                    }
                }
            }
        }
    }

    return result;
}
```

Like most people, I also unknowingly solved part two before solving part one because I didn't read the puzzle description correctly.

## Benchmark

All benchmarks were performed on an [Apple M3 Pro](https://en.wikipedia.org/wiki/Apple_M3) with times in microseconds (µs).

| Debug | ReleaseSafe | ReleaseFast | ReleaseSmall |
| ----- | ----------- | ----------- | ------------ |
|       |             |             |              |
