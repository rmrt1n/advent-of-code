# Day 06: Guard Gallivant

[Full solution](../src/days/day06.zig).

## Puzzle Input

Today's input is a 2D map of a **manufacturing lab**:

```plaintext
....#.....
.........#
..........
..#.......
.......#..
..........
.#..^.....
........#.
#.........
......#...
```

There are three types of "tiles" in this map: Guard tiles `^`, path tiles `.`, and obstacle tiles `#`. There is only one guard tile, and we'll be simulating its movement later.

Later we'll have to check if the guard is out of bounds. We can simplify this check by adding a one-tile border to the map during parsing, e.g.:

```plaintext
************
*....#.....*
*.........#*
*..........*
*..#.......*
*.......#..*
*..........*
*.#..^.....*
*........#.*
*#.........*
*......#...*
************
```

Now, instead of checking out of bounds using a condition like `x < 0 or y < 0 or x >= n_rows or y >= n_cols`, we can use the condition `map[x][y] == '*'`. This makes the code simpler and easier to read.

Here's the code to parse the input:

```zig
fn Day06(comptime length: usize) type {
    return struct {
        const Self = @This();

        const map_size = length + 2; // Add borders

        map: [map_size][map_size]Tile = .{.{Tile.init(.exit)} ** map_size} ** map_size,
        position: @Vector(2, i16) = undefined,
        direction: Direction = .up,

        fn init(input: []const u8) Self {
            var result = Self{};

            var i: usize = 1;
            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                for (line, 1..) |tile, j| {
                    switch (tile) {
                        '#' => result.map[i][j] = Tile.init(.obstacle),
                        '.' => result.map[i][j] = Tile.init(.path),
                        '^' => {
                            result.map[i][j] = Tile.init(.path);
                            result.position = .{ @intCast(i), @intCast(j) };
                        },
                        else => unreachable,
                    }
                }
            }

            return result;
        }
    };
}
```

There's a few things going on here, so here's a breakdown:

The map is stored in a 2D array of `Tile`s, where each `Tile` holds information about what type it is:

```zig
const Tile = packed struct(u8) {
    const TileType = enum { obstacle, path, visited, exit };
    
    type: TileType,
    
    fn init(tile_type: TileType) Tile {
        return Tile{ .type = tile_type };
    }
};
```

We add two new tile types, `.visited` for paths we have visited and `.exit` for the borders. We'll see later why we need the visited tile. `init` is a helper function to initialise a `Tile` with a given type.

> [!NOTE]
> We'll get to why I used a packed struct instead of an enum for the `Tile` type in part two. For now, just consider `Tile` as a regular enum type.

We don't have a `.guard` tile type because we only care about it's starting position and direction. We store the starting position and parse the guard tile as a path tile. The position is stored as a [@Vector(2, i16)](https://ziglang.org/documentation/master/#Vectors) to make the movement logic cleaner, which we'll see soon in part one.

We also store the initial direction `.up`. This is represented using an enum type:

```zig
const Direction = enum { up, right, down, left };
```

> [!TIP]
> Not to be confused with the [mathematical vector](https://en.wikipedia.org/wiki/Vector_(mathematics_and_physics)) or C++'s [`std::vector`](https://en.wikipedia.org/wiki/Sequence_container_(C%2B%2B)#Vector), `@Vector` in Zig is an fixed-sized, array-like data structure that can be processed by a single CPU instruction ([SIMD](https://en.wikipedia.org/wiki/Single_instruction,_multiple_data)).

## Part One

We have to simulate the guard's movement and count how many **distinct positions** the guard visits before leaving the map. The guard movement rules are as follow:

1. If the guard encounters an obstacle tile, it will turn right by 90 degrees.
2. Else, the guard will keep moving, one tile at a time, in its direction until it leaves the map.

To count the unique positions, we'll increment the result only when we encounter an unvisited tile. After visiting a path tile, we'll swap it with a visited tile to avoid double-counting. Here's the code:

```zig
const Direction = enum {
    up, right, down, left,

    fn vector(direction: Direction) @Vector(2, i8) {
        const directions = [_]@Vector(2, i8){ .{ -1, 0 }, .{ 0, 1 }, .{ 1, 0 }, .{ 0, -1 } };
        return directions[@intFromEnum(direction)];
    }

    fn rotate(direction: Direction) Direction {
        return @enumFromInt((@as(u8, @intFromEnum(direction)) + 1) % 4);
    }
};

fn part1(self: Self) u64 {
    var result: u64 = 0;
    // Copy by value because we still need the original map for part two.
    var simulation = self;

    while (true) {
        switch (simulation.get_tile().type) {
            .obstacle => {
                simulation.position -= simulation.direction.vector();
                simulation.direction = simulation.direction.rotate();
            },
            .path => {
                simulation.set_tile(Tile.init(.visited));
                result += 1;
            },
            .visited => {},
            .exit => break,
        }
        simulation.position += simulation.direction.vector();
    }

    return result;
}
```

We added two helper methods to `Direction`:

1. `vector` returns the direction as a vector, e.g. `.up` becomes `.{ -1, 0 }`.
2. `rotate` returns the new direction after turning right.

Since both the position and directions are stored as vectors, we can use regular arithmetic operators on them as if they are regular integers. This not only makes the code faster but also much easier to read than something like `simulation.position = { pos[0] + dir[0], pos[1] + dir[1] }`.

`get_tile` and `set_tile` are just helper functions for getting/setting the map:

```zig
fn get_tile(self: Self) Tile {
    return self.map[@intCast(self.position[0])][@intCast(self.position[1])];
}

fn set_tile(self: *Self, tile: Tile) void {
    self.map[@intCast(self.position[0])][@intCast(self.position[1])] = tile;
}
```

## Part Two

For part two, we have to count the number of positions we could place an obstacle tile that results in the guard getting **stuck in a loop**. An additional constraint is that we can't place the obstacle in the guard's original position.

We could brute force this by replacing every possible path tile, but that would be very inefficient. In reality, there are only a small number of positions where placing an obstacle could create a loop. The new obstacle must be placed somewhere along the guard's original path, since those are the only tiles that the guard visits. If the answer to part one is 41, that means we only have to try placing the obstacle in 40 tiles (excluding the starting position).

A loop happens when the guard revisits tile in the same direction as the initial visit. To detect this, we need to keep track of the visited tiles as well as the direction we visited them from.

We could use a hash map or a set for this, but this looked like the perfect use case for bit-packing. Instead of storing the position and direction in a separate map/set, we'll store the visited directions in the tile itself.

There are only four types of tiles. We could've stored them as characters or enums, both would've take one byte of space. Let's say we store them as enums:

```zig
const Tile = enum { obstacle, path, visited, exit };
```

This is what each tile looks like in binary representation:

```plaintext
.obstacle -> 00000000
.path     -> 00000001
.visited  -> 00000010
.path     -> 00000011
```

As you can see, the upper six bits are unused. You only need two bits to represent tiles. We can use this extra space to store metadata about the directions we visited the tiles from. This was the reason why `Tile` uses a packed struct instead of an enum. Here's the refactored definition:

```zig
const Tile = packed struct(u8) {
    const TileType = enum(u4) { obstacle, path, visited, exit };

    up: u1 = 0,
    right: u1 = 0,
    down: u1 = 0,
    left: u1 = 0,
    type: TileType,

    // ...
}
```

Each bit in the upper four bits are used to store the directions. If a tile's direction bit is set, it means it has previously been visited from that direction. `TileType` is `u4` here just so it fits neatly into a byte. Here's an illustration of the memory layout of `Tile`:

```plaintext
        direction metadata   tile type
           ┌─────┴─────┐   ┌─────┴─────┐
┌────────┬─┴─┬───┬───┬─┴─┬─┴─┬───┬───┬─┴─┐
│ Tile:  │ 1 │ 0 │ 0 │ 0 │ 0 │ 0 │ 1 │ 0 │
└────────┴─┬─┴─┬─┴─┬─┴─┬─┴───┴───┴───┴───┘
   up bit ─┘   │   │   └─ left bit
    right bit ─┘ down bit
```

This is the representation in big-endian systems. In little-endian systems (most modern hardware), the type bits and the direction bits will be in reversed order. We'll have to handle endianness explicitly in code. Here are some helper methods to get/set the direction bits:

```zig
const Tile = packed struct(u8) {
    // ...
    const endian = builtin.target.cpu.arch.endian();
    
    fn visit(self: Tile, direction: Direction) Tile {
        const mask: u8 = if (endian == .big) direction.mask() << 4 else direction.mask();
        const int_self = &@as(u8, @bitCast(self));

        var result = @as(Tile, @bitCast(int_self.* | mask));
        result.type = .visited;
        return result;
    }

    fn has_visited(self: Tile, direction: Direction) bool {
        const mask = direction.mask();
        const int_self = @as(u8, @bitCast(self));
        const bits = if (endian == .big) int_self >> 4 else int_self & 0xff;
        return bits & mask == mask;
    }
};
```

`visit` returns a copy of the tile with the given direction bit set and the type changed to `.visited`. `has_visited` checks is a tile has been visited from a certain direction.

We used [bit-masking](https://en.wikipedia.org/wiki/Mask_(computing)) here to get/set the bits instead of `switch` because it's [branchless](https://en.algorithmica.org/hpc/pipelining/branching/). This results in faster code but is a bit less readable than:

```zig
fn has_visited(self: Tile, direction: Direction) bool {
    switch (direction) {
        .up => return self.up == 1,
        .right => return self.right == 1,
        .down => return self.down == 1,
        .left => return self.left == 1,
    }
}
```

Here's how we get the bitmask for each direction:

```zig
// This returns:
// .up    => 1000
// .right => 0100
// .down  => 0010
// .left  => 0001
fn mask(direction: Direction) u4 {
    return @as(u4, 1) << @intFromEnum(direction);
}
```

Now for the solution. We can reuse the logic from part one to get the guard's original path. For each path tile, we'll create a copy of the map, replace the path with an obstacle, run the simulation again and check if it loops:

```zig
fn part2(self: *Self) u64 {
    var result: u64 = 0;

    self.position += self.direction.vector();

    while (true) {
        switch (self.get_tile().type) {
            .obstacle => {
                self.position -= self.direction.vector();
                self.direction = self.direction.rotate();
            },
            .path => {
                var simulation = self.*;

                simulation.set_tile(Tile.init(.obstacle));

                while (true) {
                    const inner_tile = simulation.get_tile();
                    switch (inner_tile.type) {
                        .exit => break,
                        .obstacle => {
                            simulation.position -= simulation.direction.vector();
                            simulation.direction = simulation.direction.rotate();
                        },
                        else => {
                            if (inner_tile.has_visited(simulation.direction)) {
                                result += 1;
                                break;
                            }

                            simulation.set_tile(inner_tile.visit(simulation.direction));
                            simulation.position += simulation.direction.vector();
                        },
                    }
                }
                self.set_tile(Tile.init(.visited));
            },
            .visited => {},
            .exit => break,
        }
        self.position += self.direction.vector();
    }

    return result;
}
```

> [!TIP]
> You can do this type of metadata packing with pointers too! It's called [pointer tagging](https://en.wikipedia.org/wiki/Tagged_pointer).

## Benchmark

All benchmarks were performed on an [Apple M3 Pro](https://en.wikipedia.org/wiki/Apple_M3) with times in microseconds (µs).

| Debug | ReleaseSafe | ReleaseFast | ReleaseSmall |
| ----- | ----------- | ----------- | ------------ |
|       |             |             |              |
