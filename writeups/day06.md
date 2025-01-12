# Day 06: Guard Gallivant

[Full solution](../src/days/day06.zig).

## Part one

For day six we're given a 2D grid, which we'll see a lot in later days. We're given a map like:

```
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

Where a `.` is a regular tile, a `#` is an obstacle, and `^` is the starting position of the **guard**. The guard will traverse through this map one tile at a time until it reaches the end of the map. Each time the guard encounters and obstacle, it will rotate 90 degrees to the right. The starting direction of the guard is north.

For part one, we have to count the number of unique tiles that guard visits in its path, including the starting position. We'll start by parsing the input:

```zig
const obstacle: u8 = 0;
const path: u8 = 1;
const visited: u8 = 2;
const exit: u8 = 3;

fn Day06(comptime length: usize) type {
    return struct {
        map: [length + 2][length + 2]u8 = .{.{exit} ** (length + 2)} ** (length + 2),
        position: [2]i16 = undefined,
        direction: Direction = .up,

        const Self = @This();

        fn init(input: []const u8) Self {
            var result = Self{};

            var i: usize = 1;
            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                for (line, 1..) |tile, j| {
                    switch (tile) {
                        '#' => result.map[i][j] = obstacle,
                        '.' => result.map[i][j] = path,
                        '^' => {
                            result.map[i][j] = path;
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

I made some non-obvious decisions in the parsing code, so I'll explain about it first before going into the solution code. The first point is that the map is parsed into a matrix of size N+2, where N is the number of rows/columns of the map. This is an added border to the 2D grid so that we don't have to worry about out of bound checks later. Here's a visualization using the sample input from above:

```
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

With this added border, we only have to check if the current tile is `*`, instead of doing an index check like `x >= 0 && y >= 0 && x < N && y < N`. It results in less instructions and IMO the resulting code is simpler.

Another point is that we're parsing the tiles into the `obstacle`, `path`, `exit`, and `visited` variables instead of just using the `.`, `#`, `*` characters. A benefit of this is that the verbs encode meaning so that we don't have to remember what `.` stands for, but the main reason for this will become apparent in part two, so bear with me until then. It's hard to explain without the context needed that will be given in part two.

We're also keeping track of the positions as a `[2]i16` instead of other unsigned integer types. If you've done some LeetCode before, you might be familiar with this kind of code:

```python
# This is python code.
for inc_x, inc_y in [[-1, 0], [0, 1], [1, 0], [0, -1]]:
    dfs(x + inc_x, y + inc_y)
```

We can do the same thing in Zig, but this requires signed integers because we're incrementing by a negative number. Unfortunately in Zig, even if the code is guaranteed to never overflow, the compiler doesn't allow arithmetics on mixed signed integers, which is why we're encoding the position as `[2]i16`.

The last point is the `Direction` type. This is an enum that represents the four directions we can go in the grid: up, down, left, and right.

```zig
const Direction = enum { up, right, down, left };
```

Zig enums can have methods, so we'll define some methods that we'll need later. Here's a trick I've discovered during this Advent for dealing with positions and directions in 2D grids:

```zig
const Direction = enum {
    // ...

    fn vector(direction: Direction) @Vector(2, i8) {
        const directions = [_]@Vector(2, i8){ .{ -1, 0 }, .{ 0, 1 }, .{ 1, 0 }, .{ 0, -1 } };
        return directions[@intFromEnum(direction)];
    }
};
```

This method returns a [vector](https://zig.guide/language-basics/vectors/) for the current direction. In Zig, you can perform arithmetics on vectors just like how you would on regular numbers:

```zig
const position = [2]i16{ 2, 3 };
const direction = Direction.up.vector(); // Returns {-1, 0 }
const next_position = position + direction; // Becomes { 1, 3 }
```

This code is easier to read than something like `[2]i16{ position[0] + direction[0], position[1] + direction[1]}` and also faster since it uses [SIMD instructions](https://en.wikipedia.org/wiki/Single_instruction,_multiple_data).

We'll also need a `rotate` method that'll return the current direction rotated to the right, e.g. `.up` rotated becomes `.right`, `.right` rotated becomes `.down`, and so on.

```zig
const Direction = enum {
    // ...

    fn rotate(direction: Direction) Direction {
        return @enumFromInt((@as(u8, @intFromEnum(direction)) + 1) % 4);
    }
};
```

Okay, we can get started on part one's solution now. Here are the traversal rules again for reference:

1. The guard's starting direction is north/up.
2. The guard walks one tile at a time. If it encounters an obstacle it'll turn right 90 degrees.
3. We do this until we encounter an exit tile.

And here's the code:

```zig
fn part1(self: Self) u64 {
    var result: u64 = 0;
    var simulation = self; // This is a copy by value
    while (simulation.get_tile() != exit) {
        switch (simulation.get_tile()) {
            obstacle => {
                simulation.position -= simulation.direction.vector();
                simulation.direction = simulation.direction.rotate();
            },
            path => {
                simulation.set_tile(visited);
                result += 1;
            },
            visited => {},
            else => unreachable,
        }
        simulation.position += simulation.direction.vector();
    }
    return result;
}
```

For each `path` we encounter, we'll mark it as visited an increment the `result` variable, which holds the count of unique tiles visited. If the current tile is an `obstacle` we move to the previous tile with `position -= direction.vector()` and turn right.

`set_tile` and `get_tile` are helper methods because the indexing code is verbose and makes it harder to read:

```zig
fn get_tile(self: Self) u8 {
    return self.map[@intCast(self.position[0])][@intCast(self.position[1])];
}

fn set_tile(self: *Self, tile: u8) void {
    self.map[@intCast(self.position[0])][@intCast(self.position[1])] = tile;
}
```

You'll see a lot of `@intCast` in Zig code for Advent of Code because only unsigned integers can be used to index and there is no implicit type casting in Zig.

## Part two

Part two is a lot more difficult. Now, we can to trap the guard in a loop by placing a single obstacle anywhere in the map except for the starting point. Then, we have to count the number of positions on the map which will cause a loop when an obstacle is placed there.

We can bruteforce this by trying all possible `.` and replacing them with a `#`, but that would be very inefficient. In fact, there are only a small number of positions where we can create a loop with. The obstacle would have to be placed in the guard's initial path, because those are the only tiles that the guard visits. If the answer to part one is 41, it means that we only have to check 40 tiles for part two (excluding the starting position).

The next question is how do we detect a loop? A loop happens when a guard visits a previously-visited tile with the same direction as the initial visit. Therefore, we have to keep track of the visited tiles, as well as the direction we visisted it with. There are several ways to do this, e.g. a hashmap of position to direction, a separate map holding directions instead of the tile.

When I was solving this, my initial thought was to try a technique similar to [pointer tagging](https://en.wikipedia.org/wiki/Tagged_pointer), where you store the direction as a metadata of the tile. This is the main reason as to why we parsed the tiles the way we did. Let me explain. Here's what the tiles look like in binary representation:

1. `obstacle: u8 = 0` -> `00000000`
2. `path: u8 = 1` -> `00000001`
3. `visited: u8 = 2` -> `00000010`
4. `exit: u8 = 3` -> `00000011`

As you can see, the highest four bits are unused. We can use this to store metadata about the directions, one bit for each direction. Here's an illustration:

```
        direction metadata   tile data
           ┌─────┴─────┐   ┌─────┴─────┐
┌────────┬─┴─┬───┬───┬─┴─┬─┴─┬───┬───┬─┴─┐
│ Tile:  │ 1 │ 0 │ 0 │ 0 │ 0 │ 0 │ 1 │ 0 │
└────────┴─┬─┴─┬─┴─┬─┴─┬─┴───┴───┴───┴───┘
   up bit ─┘   │   │   └─ left bit
    right bit ─┘ down bit
```

E.g., if a tile's up bit is set, it means that we have previously visited it heading up. With this, we don't need extra space to hold the direction information. To get/set this metadata, we'll use [bitmasking](https://en.wikipedia.org/wiki/Mask_(computing)). We'll create a method to return the mask for each direction:

```zig
const Direction = enum {
    // ...

    // This'll return:
    // .up    => 1000
    // .right => 0100
    // .down  => 0010
    // .left  => 0001
    fn mask(direction: Direction) u4 {
        return @as(u4, 1) << @intFromEnum(direction);
    }
   }
};
```

We can use this to:

1. Check if a tile has been visited by a direction: `tile >> 4 & mask == mask`
2. Set a tile as visited by a direction: `tile | mask << 4`

Now for the solution to part two:

```zig
fn part2(self: Self) u64 {
    var result: u64 = 0;
    var simulation = self;
    while (simulation.get_tile() != exit) {
        switch (simulation.get_tile()) {
            obstacle => {
                simulation.position -= simulation.direction.vector();
                simulation.direction = simulation.direction.rotate();
            },
            path => {
                var time_loop = simulation;
                time_loop.set_tile(obstacle);

                while (time_loop.get_tile() != exit) {
                    const current = time_loop.get_tile();
                    if (current == obstacle) {
                        time_loop.position -= time_loop.direction.vector();
                        time_loop.direction = time_loop.direction.rotate();
                    } else {
                        const mask = time_loop.direction.mask();
                        if (current >> 4 & mask == mask) {
                            result += 1;
                            break;
                        }
                        time_loop.set_tile(current | @as(u8, mask) << 4);
                        time_loop.position += time_loop.direction.vector();
                    }
                }
                simulation.set_tile(visited);
            },
            visited => {},
            else => unreachable,
        }
        simulation.position += simulation.direction.vector();
    }
    return result;
}
```

We'll follow the same path as in part one, but for each step we'll simulate if a loop happens if the current tile is replaced with an obstacle. An optimization here is to simulate the loop in parallel since we don't have to do it sequentially and that we already have the list of tiles in the guards path (from part one). I have a self-imposed constraint to write only single threaded code, so I won't be doing it.

## Benchmarks
