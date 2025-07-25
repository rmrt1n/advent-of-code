# Day 12: Garden Groups

[Full solution](../src/days/day12.zig).

## Puzzle Input

Today's input is a map of **garden plot** regions in a farm:

```plaintext
AAAA
BBCD
BBCC
EEEC
```

Each region grows only one type of plant, represented by its character. We'll parse this map into a 2D array and add a border just like in day 10:

```zig
fn Day12(length: usize) type {
    return struct {
        const Self = @This();

        const map_size = length + 2; // Add borders

        // Borders are 26 because the minimum is the next character after 'Z' - 'A' (25).
        garden: [map_size][map_size]u8 = .{.{26} ** map_size} ** map_size,

        fn init(input: []const u8) Self {
            var result = Self{};

            var i: usize = 1;
            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                @memcpy(result.garden[i][1..(length + 1)], line);
            }

            return result;
        }
    };
}
```

> [!NOTE]
> We'll get to why the borders use `26` as the character in part one.

## Part One

We need to find the **total price of fencing** each region in the map. The price of fencing a region is its area multiplied by its perimeter.

We'll use DFS to explore the tiles of each region. When we find an unvisited tile of the same region, we increment the area. If we find a different plant or a border, we'll increment the perimeter. We'll skip visited tiles of the same region.

Here is the code:

```zig
const stack_capacity = 1024;

fn part1(self: Self) u64 {
    // Copy by value because we still need the original map for part two.
    var copy = self;
    var result: u64 = 0;
    var stack: [stack_capacity][2]i16 = undefined;

    for (copy.garden[1..(map_size - 1)], 1..) |row, i| {
        for (row[1..(map_size - 1)], 1..) |plant, j| {
            if (plant < 'A') continue;

            var area: u64 = 0;
            var perimeter: u64 = 0;

            stack[0] = .{ @intCast(i), @intCast(j) };

            var stack_length: usize = 1;
            while (stack_length > 0) {
                stack_length -= 1;

                const position = stack[stack_length];
                const tile = copy.get_tile_at(position);

                if (tile == plant - 'A') continue;
                if (tile != plant) {
                    perimeter += 1;
                    continue;
                }

                copy.set_tile_at(position, plant - 'A');
                area += 1;

                for ([_]Direction{ .up, .right, .down, .left }) |direction| {
                    stack[stack_length] = position + direction.vector();
                    stack_length += 1;
                }
            }

            result += area * perimeter;
        }
    }

    return result;
}
```

We mark a tile as visited by subtracting it with `A`, e.g. `A` becomes `0`, `B` becomes `1`, `Z` becomes `25`. This is why the borders are marked as `26`; to avoid conflicting with the visited plant type.

> [!NOTE]
> The stack capacity I used is an arbitrary number I found through trial and error. I'm not sure of an exact way to calculate the minimum capacity of the stack here, so I just tested numbers until I get one that works for all my inputs.

Here are the definitions for the helper functions `get_tile_at` and `set_tile_at`:

```zig
fn get_tile_at(self: Self, position: [2]i16) u8 {
    return self.garden[@intCast(position[0])][@intCast(position[1])];
}

fn set_tile_at(self: *Self, position: [2]i16, tile: u8) void {
    self.garden[@intCast(position[0])][@intCast(position[1])] = tile;
}
```

The `Direction` type is implemented the same way as in day six:

```zig
const Direction = enum {
    up, right, down, left,

    fn vector(direction: Direction) @Vector(2, i8) {
        const directions = [_][2]i8{ .{ -1, 0 }, .{ 0, 1 }, .{ 1, 0 }, .{ 0, -1 } };
        return directions[@intFromEnum(direction)];
    }

    fn rotate(direction: Direction) Direction {
        return @enumFromInt((@as(u8, @intFromEnum(direction)) + 1) % 4);
    }
};
```

## Part Two

For part two, we need to calculate the total price of fencing after applying a **bulk discount**. Now, the price of a region is calculated by multiplying its area with the number of sides it has.

To get the number of sides a region has, we can count the number of corners the region has. The number of sides of a polygon is always the same as the number of corners. There are two types of corners we can find, outside corners and inside corners.

Here's a visualisation of what these corners look like:

```plaintext
# Outside corner
┌───┬───┐      ┌───┬───┐
│ # │ # │      │ # │ A │
├───┼───┤  Or  ├───┼───┤
│ A │ # │      │ A │ # │
└───┴───┘      └───┴───┘

# Inside corner
┌───┬───┐
│ A │ # │
├───┼───┤
│ A │ A │
└───┴───┘
```

We'll know a tile is a corner if it follows these rules:

1. **Outside corner**: The tile above and the tile to the right are not part of the same region.
2. **Inside corner**: The tile above and the tile to the right are part of the same region, and the tile to the top right is not part of the same region.

We'll update our part one code to count corners instead of the perimeter:

```zig
fn part2(self: *Self) u64 {
    var result: u64 = 0;
    var stack: [stack_capacity]struct { position: [2]i16, direction: Direction } = undefined;

    for (self.garden[1..(map_size - 1)], 1..) |row, i| {
        for (row[1..(map_size - 1)], 1..) |plant, j| {
            if (plant < 'A') continue;

            var area: u64 = 0;
            var sides: u64 = 0;

            stack[0] = .{ .position = .{ @intCast(i), @intCast(j) }, .direction = .up };

            var stack_length: usize = 1;
            while (stack_length > 0) {
                stack_length -= 1;

                const current = stack[stack_length];
                const tile = self.get_tile_at(current.position);

                if (tile == plant - 'A') continue;
                if (tile != plant) {
                    const turn1 = current.position + current.direction.rotate().vector();
                    const turn2 = turn1 - current.direction.vector();
                    const top_right = self.get_tile_at(turn1);
                    const right = self.get_tile_at(turn2);

                    if ((top_right == plant or top_right == plant - 'A') or
                        (right != plant and right != plant - 'A'))
                    {
                        sides += 1;
                    }
                    continue;
                }

                self.set_tile_at(current.position, tile - 'A');
                area += 1;

                for ([_]Direction{ .up, .right, .down, .left }) |direction| {
                    stack[stack_length] = .{
                        .position = current.position + direction.vector(),
                        .direction = direction,
                    };
                    stack_length += 1;
                }
            }
            result += area * sides;
        }
    }
    return result;
}
```

## Benchmark

All benchmarks were performed on an [Apple M3 Pro](https://en.wikipedia.org/wiki/Apple_M3) with times in microseconds (µs).

| Part/Optimise | Debug (µs)  | ReleaseSafe (µs) | ReleaseFast (µs) | ReleaseSmall (µs) |
|-------------- | ----------: | ---------------: | ---------------: | ----------------: |
| Parsing       | 67.6        | 6.9              | 6.8              | 7.8               |
| Part 1        | 1,224.6     | 258.1            | 164.4            | 189.2             |
| Part 2        | 1,794.9     | 368.4            | 249.0            | 252.5             |
| **Total**     | **3,087.2** | **633.5**        | **420.3**        | **449.4**         |
