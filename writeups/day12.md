# Day 12: Garden Groups

[Full solution](../src/days/day12.zig).

## Part one

In day 12 we're given a map (2D grid) of gardens, where each garden grows only a single type of plant. The garden's area is marked by a single capital letter that corresponds to the type of plant, like so:

```
AAAA
BBCD
BBCC
EEEC
```

For part one, we're task with fencing each garden and finding the **total price** of fencing all the gardens in the map. Here's a visualization of the gardens in the sample input above with fences (indicated by a `|` or `-`):

```
+-+-+-+-+
|A A A A|
+-+-+-+-+     +-+
              |D|
+-+-+   +-+   +-+
|B B|   |C|
+   +   + +-+
|B B|   |C C|
+-+-+   +-+ +
          |C|
+-+-+-+   +-+
|E E E|
+-+-+-+
```

To get the fence price for a single garden, we have to multiply its area by its perimeter. First, let's parse the input:

```zig
fn Day12(length: usize) type {
    return struct {
        garden: [length + 2][length + 2]u8 = .{.{'#'} ** (length + 2)} ** (length + 2),

        const Self = @This();

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

Like previous days, we're adding a border to the map to simplify out-of-bounds checks. Next, we'll need a way to get the area and perimeter of a garden plot. We can do this in a recursive way like so:

1. We start with a tile in the garden. This can be any tile. We'll initialize two counters, one for area and the other for the perimeter.
2. We mark the tile as visited, then increment the area counter by one. Then we visit all adjacent tiles.
3. If the next tile is of the same plant type, but we have visited it before, skip this iteration.
4. If the next tile is out-of-bounds (marked by a `#` character), or if it's a different type of plant, we increment the perimeter counter.

Instead of implementing this as a recursive function, we'll do it iteratively with a stack. This is both faster an also safer as we don't risk stack overflows. Here's the code implementation of the above algorithm:

```zig
fn part1(self: Self) u64 {
    var result: u64 = 0;
    var copy = self;
    for (1..(length + 1)) |i| {
        for (1..(length + 1)) |j| {
            const plant = copy.garden[i][j];
            if (plant < 'A') continue;

            var area: u64 = 0;
            var perimeter: u64 = 0;

            var stack: [580][2]i16 = undefined;
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

                copy.set_tile_at(position, tile - 'A');
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

We iterate over each tile in the map, and calculate the area and perimeter of an area only if it hasn't been visited before. This is checked by the line:

```zig
if (plant < 'A') continue;
```

The logic for this is that we mark tiles as visited subtracting `'A'` from it. Tiles are just regular capital alphabet characters, so we can:

1. Mark a tile as visited: `tile - 'A'`
2. Check if a tile is visited: `tile < 'A'`
3. Check if a visited tile is of the same plant type: `tile == plant - 'A'`

Doing this means we don't have to allocate extra space, e.g. with a hashmap, to store the visited tiles. We use an array of size 580 for the stack. I got this number by running the function first (with a larger capacity, e.g. 1000) and finding the max length of the stack first before updating the code. Depending on your input, this number might be too small.

We're also bringing back the `Direction` type we used in day six:

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

And here are the definitions for the helper functions `get_tile_at` and `set_tile_at`:

```zig
fn get_tile_at(self: Self, position: [2]i16) u8 {
    return self.garden[@intCast(position[0])][@intCast(position[1])];
}

fn set_tile_at(self: *Self, position: [2]i16, tile: u8) void {
    self.garden[@intCast(position[0])][@intCast(position[1])] = tile;
}
```

## Part two

For part two, instead of the perimeter, we have to multiply the area by the number of **sides** a garden has. This was a hard problem that I couldn't solve by myself in an elegant way, so I had to look at other people's solution.

The way to solve this recursively is to count the corners of a garden. The number of corners of a garden is always the same as the number of sides. There are two types of corners we have to look for, outside corners and inside corners.

Here's a visualization of what these corners look like:

```
# Here's an outside corner
┌───┬───┐
│ # │ # │
├───┼───┤
│ A │ # │
└───┴───┘

# And here's an inside corner
┌───┬───┐
│ A │ # │
├───┼───┤
│ A │ A │
└───┴───┘
```

A tile is a corner if it follows these rules:

1. If the tile above and the tile to its right are not the same as the current tile, it's an outside corner.
2. If the tile above and the tile to its right are the same as the current tile, and the tile to its top right is different, then it's an inside corner.

The "tile to the right" is respective to the direction we visited the tile from. In the example above, we visit the tile with the up direction, which is why we look at the top right and the right tiles. If we visit a tile with the left direction, we'll have to check the left bottom and bottom tiles.

We can reuse most of the code from part one for part two. One difference is that in part two, we'll keep track of the direction we visited a tile from.

The stack will now hold a struct type `StackItem`:

```zig
const StackItem = struct {
    position: [2]i16,
    direction: Direction,
};
```

And here's the code for part two:

```zig
fn part2(self: Self) u64 {
    var result: u64 = 0;
    var copy = self;
    for (1..(length + 1)) |i| {
        for (1..(length + 1)) |j| {
            const plant = copy.garden[i][j];
            if (plant < 'A') continue;

            var area: u64 = 0;
            var sides: u64 = 0;

            var stack: [580]StackItem = undefined; // Max is 577
            stack[0] = .{ .position = .{ @intCast(i), @intCast(j) }, .direction = .up };

            var stack_length: usize = 1;
            while (stack_length > 0) {
                stack_length -= 1;
                const current = stack[stack_length];

                const tile = copy.get_tile_at(current.position);
                if (tile == plant - 'A') continue;
                if (tile != plant) {
                    const turn1 = current.position + current.direction.rotate().vector();
                    const turn2 = turn1 - current.direction.vector();
                    const top_right = copy.get_tile_at(turn1);
                    const right = copy.get_tile_at(turn2);

                    if ((top_right == plant or top_right == plant - 'A') or
                        (right != plant and right != plant - 'A'))
                    {
                        sides += 1;
                    }
                    continue;
                }

                copy.set_tile_at(current.position, tile - 'A');
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

There's a slight modification from the corner counting rules from above. We'll check only if the current tile is not the same type as the previous tile, e.g.:

```
# The current tile is now '#'
┌───┬────┐
│ # │ ?1 │
├───┼────┤
│ A │ ?2 │
└───┴────┘
```

With this, the rules for a corner become:

1. If the tile at `?2` is not a the same tile as the rest of the garden, the `A` tile is an outside corner:
    ```
    # So either this:
    ┌───┬───┐
    │ # │ # │
    ├───┼───┤
    │ A │ # │
    └───┴───┘

    # Or this results in an outside corner.
    ┌───┬───┐
    │ # │ A │
    ├───┼───┤
    │ A │ # │
    └───┴───┘
    ```
2. If the tile at `?1` is the same tile as the rest of the garden, `A` is guaranteed to be a tile regardless of what tile `?2` is:
    ```
    # It can either be an outside corner:
    ┌───┬───┐
    │ # │ A │
    ├───┼───┤
    │ A │ # │
    └───┴───┘

    # Or an inside corner:
    ┌───┬───┐
    │ # │ A │
    ├───┼───┤
    │ A │ A │
    └───┴───┘
    ```

This maps to this section of part two's code:

```zig
fn part2(self: Self) u64 {
    // ...
    if (tile != plant) {
        const turn1 = current.position + current.direction.rotate().vector();
        const turn2 = turn1 - current.direction.vector();
        const top_right = copy.get_tile_at(turn1);
        const right = copy.get_tile_at(turn2);

        if ((top_right == plant or top_right == plant - 'A') or
            (right != plant and right != plant - 'A'))
        {
            sides += 1;
        }
        continue;
    }
    // ...
}
```

You can also solve both parts at the same time if you want to.

## Benchmarks
