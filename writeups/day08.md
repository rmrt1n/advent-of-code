# Day 08: Resonant Collinearity

[Full solution](../src/days/day08.zig).

## Puzzle Input

Today's input is a map of a city with **antennas**:

```plaintext
............
........0...
.....0......
.......0....
....0.......
......A.....
............
............
........A...
.........A..
............
............
```

Today is a bit unique for a 2D grid puzzle as we don't have to parse the map. We just have to store the locations of the antennas. We'll parse the input into a mapping of antenna character to a list of its positions in the map:

```zig
fn Day08(length: usize) type {
    return struct {
        const Self = @This();

        antennas: std.AutoHashMap(u8, std.ArrayList([2]u8)) = undefined,
        allocator: std.mem.Allocator,

        fn init(input: []const u8, allocator: std.mem.Allocator) !Self {
            var result = Self{ .allocator = allocator };
            result.antennas = std.AutoHashMap(u8, std.ArrayList([2]u8)).init(allocator);

            var i: usize = 0;
            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                for (line, 0..) |c, j| {
                    if (c == '.') continue;
                    const entry = try result.antennas.getOrPutValue(
                        c,
                        std.ArrayList([2]u8).init(allocator),
                    );
                    try entry.value_ptr.append(.{ @intCast(i), @intCast(j) });
                }
            }

            return result;
        }
    };
}
```

This is also the first day we're using dynamic allocation. Trying to force a solution without it results in complex and unreadable code. We're only allocating during parsing, so it doesn't impact the performance of the rest of the parts much.

## Part One

We have to count how many distinct positions in the map contains an **antinode**. The antinode of antenna $a$ against antenna $b$ is the [reflection](https://en.wikipedia.org/wiki/Point_reflection) of $a$ across $b$. Antennas $a$ and $b$ must be of the same type. Antinodes can also overlap (reside in the same position) with other antennas.

We'll first create a function to get the antinode of two antennas using the formula $antinode(a,b) = 2b - a$. If the resulting antinode is out of bounds, we'll return `null`.

```zig
fn antinode_of(a: [2]u8, b: [2]u8) ?[2]u8 {
    const x = @as(i16, b[0] * 2) - a[0];
    const y = @as(i16, b[1] * 2) - a[1];
    if (x < 0 or y < 0 or x >= length or y >= length) return null;
    return .{ @intCast(x), @intCast(y) };
}
```

To find all antinodes for a specific antenna type, we'll try every combination of two antennas, calculate their antinode positions, and insert the results into a set. We'll do this for every antenna type in the map. The total number of entries in the set is our answer. Here's the code:

```zig
fn part1(self: Self) !u64 {
    var antinodes = std.AutoHashMap([2]u8, void).init(self.allocator);
    defer antinodes.deinit();

    var iterator = self.antennas.valueIterator();
    while (iterator.next()) |entry| {
        const antennas = entry.*.items;
        for (antennas[0..(antennas.len - 1)], 0..) |antenna_a, i| {
            for (antennas[(i + 1)..antennas.len]) |antenna_b| {
                if (antinode_of(antenna_a, antenna_b)) |antinode| {
                    try antinodes.put(antinode, {});
                }

                if (antinode_of(antenna_b, antenna_a)) |antinode| {
                    try antinodes.put(antinode, {});
                }
            }
        }
    }

    return antinodes.count();
}
```

> [!NOTE]
> We have to call `antinode_of` twice for each pair of antennas. The first is to get the antinode of $a$ against $b$, and the second is to get the antinode of $b$ against $a$.

> [!TIP]
> In Zig we usually use a hash map with a `void` value type as a set since there's no built-in, "general-purpose set type" in the standard library, e.g. `std.AutoHashMap(u8, void)`.
>
> Yeah there's `BufSet`, which uses `std.StringHashMap(void)` under the hood, but this only works for string keys. There's also the `BitSet` types, but these only support integer keys.

## Part Two

Part two introduced **resonant harmonics**. Now, for each pair of antennas, we have to keep finding antinodes recursively until we've gone out of bounds. E.g, after finding $antinode(a,b)$, we have to find $antinode(b,antinode(a,b))$, then $antinode(antinode(a,b),antinode(b, antinode(a,b)))$, and so on.

This isn't too big of a twist for part two, we can reuse most of our part one code. Now, we'll keep finding antinodes until `antinode_of` returns `null`, which means we've gone out of bounds. Here's the code:

```zig
fn part2(self: Self) !u64 {
    var antinodes = std.AutoHashMap([2]u8, void).init(self.allocator);
    defer antinodes.deinit();

    var iterator = self.antennas.valueIterator();
    while (iterator.next()) |entry| {
        const antennas = entry.*.items;
        for (antennas[0..(antennas.len - 1)], 0..) |antenna_a, i| {
            try antinodes.put(antenna_a, {});

            for (antennas[(i + 1)..antennas.len]) |antenna_b| {
                try antinodes.put(antenna_b, {});

                var current_a = antenna_a;
                var current_b = antenna_b;
                while (antinode_of(current_a, current_b)) |antinode| {
                    try antinodes.put(antinode, {});
                    current_a = current_b;
                    current_b = antinode;
                }

                current_a = antenna_b;
                current_b = antenna_a;
                while (antinode_of(current_a, current_b)) |antinode| {
                    try antinodes.put(antinode, {});
                    current_a = current_b;
                    current_b = antinode;
                }
            }
        }
    }

    return antinodes.count();
}
```

## Benchmark

All benchmarks were performed on an [Apple M3 Pro](https://en.wikipedia.org/wiki/Apple_M3) with times in microseconds (µs).

| Debug | ReleaseSafe | ReleaseFast | ReleaseSmall |
| ----- | ----------- | ----------- | ------------ |
|       |             |             |              |
