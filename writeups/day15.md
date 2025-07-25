# Day 15: Warehouse Woes

[Full solution](../src/days/day15.zig).

## Puzzle Input

Today's input consists of a **warehouse map** and a list of **robot instructions**:

```plaintext
##########
#..O..O.O#
#......O.#
#.OO..O.O#
#..O@..O.#
#O#..O...#
#O..O..O.#
#.OO.O.OO#
#....O...#
##########

<vv>^<v^>v>^vv^v>v<>v^v<v<^vv<<<^><<><>>v<vvv<>^v^>^<<<><<v<<<v^vv^v>^
vvv<<^>^v^^><<>>><>^<<><^vv^^<>vvv<>><^^v>^>vv<>v<<<<v<^v>^<^^>>>^<v<v
><>vv>v^v^<>><>>>><^^>vv>v<^^^>>v^v^<^^>v^^>v^<^v>v<>>v^v^<v>v^^<^^vv<
<<v<^>>^^^^>>>v^<>vvv^><v<<<>^^^vv^<vvv>^>v<^^^^v<>^>vvvv><>>v^<<^^^^^
^><^><>>><>^^<<^^v>>><^<v>^<vv>>v>>>^v><>^v><<<<v>>v<v<v>vvv>^<><<>^><
^>><>^v<><^vvv<^^<><v<<<<<><^v<<<><<<^^<v<^^^><^>>^<v^><<<^>>^v<v^v<v^
```

There are 4 types of "tiles" in this map: Robot tiles `@`, path tiles `.`, box tiles `O`, and obstacle tiles `#`. There is only one robot tile, and we'll be simulating its movement following the instructions list later.

We'll parse the map into a `Simulation` type, which is just a wrapper over a 2D array, and parse the instructions into a list `std.ArrayList` of directions:

```zig
fn Day15(length: usize) type {
    return struct {
        const Self = @This();

        simulation1: Simulation(length, length) = .{},
        instructions: std.ArrayList(Direction) = undefined,
        allocator: std.mem.Allocator,

        fn init(input: []const u8, allocator: std.mem.Allocator) !Self {
            var result = Self{ .allocator = allocator };

            // Using an array here doesn't speed up parsing a lot, so keep it here for simplicity.
            result.instructions = std.ArrayList(Direction).init(allocator);

            var i: usize = 0;
            var lexer = std.mem.splitScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                if (line.len == 0) break;

                for (line, 0..) |c, j| {
                    result.simulation1.map[i][j] = c;
                    if (c == '@') {
                        result.simulation1.position = .{ @intCast(i), @intCast(j) };
                    }
                }
            }

            while (lexer.next()) |line| {
                if (line.len == 0) break;

                for (line) |c| {
                    try result.instructions.append(switch (c) {
                        '<' => Direction.left,
                        '>' => Direction.right,
                        '^' => Direction.up,
                        'v' => Direction.down,
                        else => unreachable,
                    });
                }
            }

            return result;
        }

        fn deinit(self: Self) void {
            self.instructions.deinit();
        }
    };
}
```

Here is the definition for the `Simulation` type. We also add some helper methods for getting and setting the map:

```zig
fn Simulation(comptime rows: usize, comptime columns: usize) type {
    return struct {
        const Self = @This();

        map: [rows][columns]u8 = undefined,
        position: @Vector(2, i16) = undefined,

        fn peek_tile(self: Self, direction: Direction) u8 {
            const next = self.position + direction.vector();
            return self.map[@intCast(next[0])][@intCast(next[1])];
        }

        fn get_tile(self: Self) u8 {
            return self.map[@intCast(self.position[0])][@intCast(self.position[1])];
        }

        fn set_tile(self: *Self, tile: u8) void {
            self.map[@intCast(self.position[0])][@intCast(self.position[1])] = tile;
        }
    };
}
```

The `Direction` type is the same as in previous days:

```zig
const Direction = enum {
    up, right, down, left,

    fn vector(direction: Direction) @Vector(2, i8) {
        const directions = [_][2]i8{ .{ -1, 0 }, .{ 0, 1 }, .{ 1, 0 }, .{ 0, -1 } };
        return directions[@intFromEnum(direction)];
    }

    fn opposite(direction: Direction) Direction {
        return @enumFromInt((@as(u8, @intFromEnum(direction)) + 2) % 4);
    }
};
```

> [!NOTE]
> We name the field `simulation1` because we'll have another simulation field for part two.

## Part One

We have to find the sum of the boxes' **GPS coordinates** after moving the robot according to the instructions. The gps coordinate of a robot at $(x, y)$ is $x + 100y$.

We have to simulate the robot's movement following these rules:

1. If we encounter a box `O`, we attempt to move it and all consecutive boxes behind it. A sequence of boxes can only be moved if there is a path `.` behind it.
2. If the boxes can't be moved (there is an obstacle `#` behind them), skip to the next instruction.
3. Else, the robot just keeps moving in the specified direction, one tile at a time, until all instructions have been processed.

To move a sequence of boxes, we'll peek the next tiles in our current direction until we have found either a path or an obstacle. If we found path, move all boxes one tile in that direction. If we found an obstacle, immediately skip to the next iteration. Here's the code:

```zig
fn part1(self: Self) u64 {
    var simulation = self.simulation1;

    for (self.instructions.items) |direction| {
        const original_position = simulation.position;

        simulation.position += direction.vector();

        switch (simulation.get_tile()) {
            '#' => simulation.position -= direction.vector(),
            '.' => {},
            'O' => {
                var distance: usize = 0;
                var tile = simulation.get_tile();
                while (tile == 'O') : (tile = simulation.get_tile()) {
                    distance += 1;
                    simulation.position += direction.vector();
                }

                if (tile == '#') {
                    simulation.position = original_position;
                    continue;
                }

                for (0..distance) |_| {
                    simulation.set_tile(simulation.peek_tile(direction.opposite()));
                    simulation.position -= direction.vector();
                }

                simulation.set_tile('.');
            },
            else => unreachable,
        }
    }

    return simulation.get_sum('O');
}
```

At the start of each loop, we store the original position of the robot so that we can return to it if we peeked and found an obstacle. If the boxes can be moved, we shift them forward one tile at a time, starting from the back, to avoid overwriting any boxes during the move.

We also added a helper method to `Simulation` to get the sum of the gps coordinates given the box tile character:

```zig
fn Simulation(comptime rows: usize, comptime columns: usize) type {
    return struct {
        // ...

        fn get_sum(self: Self, box_character: u8) u64 {
            var result: u64 = 0;
            for (self.map, 0..) |line, i| {
                for (line, 0..) |c, j| {
                    if (c == box_character) result += @intCast(i * 100 + j);
                }
            }
            return result;
        }
    };
}

```

> [!NOTE]
> The reason we accept a `box_character` is so that we can reuse this function for part 2, where the box character is different.

## Part Two

We still need to count the sum of the GPS coordinates, but this time the map tiles are parsed **twice as wide**. The parsing rules are as follows:

1. `#` becomes a  `##`.
2. `O` becomes a  `[]`.
3. `.` becomes a  `..`.
4. `@` becomes a  `@.`.

We'll update the parsing code to parse the input for both parts at the same time. This time, we'll parse using `length * 2` for the columns length:

```zig

fn Day15(length: usize) type {
    return struct {
        // ...
        simulation2: Simulation(length, length * 2) = .{},

        fn init(input: []const u8, allocator: std.mem.Allocator) !Self {
            // ...
            while (lexer.next()) |line| : (i += 1) {
                if (line.len == 0) break;

                for (line, 0..) |c, j| {
                    result.simulation1.map[i][j] = c;

                    const wide_tile = switch (c) {
                        '#' => "##",
                        'O' => "[]",
                        '.', '@' => "..",
                        else => unreachable,
                    };
                    @memcpy(result.simulation2.map[i][(2 * j)..(2 * j + 2)], wide_tile);

                    if (c == '@') {
                        result.simulation1.position = .{ @intCast(i), @intCast(j) };
                        result.simulation2.position = .{ @intCast(i), @intCast(j * 2) };
                    }
                }
            }
            // ...
        }
    };
}
```

The major challenge for part 2 is figuring out how to push box sequences when moving in a vertical direction, as horizontal box pushes follow the same logic as in part one. Here's an example:

```plaintext
.....
[][].
.[]..
.@...
```

If the robot moves up, all of the boxes moves with it. But if there are any obstacles anywhere in front of the boxes like:

```plaintext
.#...
[][].
.[]..
.@...
```

This box sequence becomes immovable.

To simulate this, we'll use a queue to store the box tiles `[` `]` that we need to move. For each item in the queue, we'll scan its next row in the map. We keep doing this until we have parsed all of the boxes in a sequence. If at any point we encounter an obstacle, we'll return to the original position and skip to the next instruction.

This is probably my longest `part2`, so I'll break it down into sections.

Here's a high level overview of the function:

```zig
fn part2(self: Self) u64 {
    var simulation = self.simulation2;
    const queue_capacity = 256;
    var queue: [queue_capacity][2]i16 = undefined;
    
    top: for (self.instructions.items) |direction| {
        const original_position = simulation.position;

        simulation.position += direction.vector();

        const current_tile = simulation.get_tile();
        if ((direction == .up or direction == .down) and
            (current_tile == '[' or current_tile == ']'))
        {
            // Handle vertical box pushes...
        } else {
            // Handle horizontal box pushes and regular movement...
        }
    }
    
    return simulation.get_sum('[');
}
```

First, we initialise a queue to handle the vertical movements. I'll explain a bit later why it's using an array as the base data structure. Next, we iterate through each instruction and simulate the robot. The loop is labeled so we can break/continue from a heavily nested inner loop. After processing all instructions, we'll call `get_sum` again but using the new box character `[`.

> [!NOTE]
> The capacity 256 is an arbitrary number I got through trial and error with my different inputs. And yes, I don't write really long functions with deep nesting in "real" codebases. This is just for Advent of Code.

For each instruction, we handle two cases: the special case of pushing boxes vertically, and the more straightforward case of regular movement and horizontal box pushing. We'll start by implementing the horizontal case first, as it's almost the same as in part one:

```zig
fn part2(self: Self) u64 {
    // ...
    top: for (self.instructions.items) |direction| {
        if ((direction == .up or direction == .down) and
            (current_tile == '[' or current_tile == ']'))
        {
            // Handle vertical box pushes...
        } else {
            switch (simulation.get_tile()) {
                '#' => simulation.position -= direction.vector(),
                '.' => {},
                '[', ']' => {
                    var distance: usize = 0;
                    var tile = simulation.get_tile();
                    while (tile == '[' or tile == ']') : (tile = simulation.get_tile()) {
                        distance += 1;
                        simulation.position += direction.vector();
                    }

                    if (tile == '#') {
                        simulation.position = original_position;
                        continue;
                    }

                    for (0..distance) |_| {
                        simulation.set_tile(simulation.peek_tile(direction.opposite()));
                        simulation.position -= direction.vector();
                    }

                    simulation.set_tile('.');
                },
                else => unreachable,
            }
        }
    }
    // ...
}
```

Now for the hard part. To push a sequence of boxes vertically, first we'll insert the first 2 box tiles into the queue:

```zig
fn part2(self: Self) u64 {
    // ...
    top: for (self.instructions.items) |direction| {
        if ((direction == .up or direction == .down) and
            (current_tile == '[' or current_tile == ']'))
        {
            if (simulation.get_tile() == '[') {
                queue[0] = simulation.position;
                queue[1] = simulation.position + Direction.right.vector();
            } else {
                queue[0] = simulation.position + Direction.left.vector();
                queue[1] = simulation.position;
            }
            // ...
        } else {
            // Handle horizontal box pushes and regular movement...
        }
    }
    // ...
}
```

We always insert the left `[` part of the box first. We scan rows from the left, so its important that the left part of a box gets popped first.

Next, we iterate through items in the queue. For each box tile, we peek the next tiles. If the tile is another part of a box, we'll add both of its part into the queue. If it's an obstacle tile, we continue the top most loop and process the next instruction:

```zig
fn part2(self: Self) u64 {
    // ...
    top: for (self.instructions.items) |direction| {
        if ((direction == .up or direction == .down) and
            (current_tile == '[' or current_tile == ']'))
        {
            // ...
            var left: usize = 0;
            var right: usize = 2;
            while (left < right) : (left += 1) {
                simulation.position = queue[left];
                switch (simulation.peek_tile(direction)) {
                    '[' => {
                        const next = simulation.position + direction.vector();
                        queue[right] = next;
                        queue[right + 1] = next + Direction.right.vector();
                        right += 2;
                    },
                    ']' => {
                        const next = simulation.position + direction.vector();
                        if (!std.meta.eql(queue[right - 1], next)) {
                            queue[right] = next + Direction.left.vector();
                            queue[right + 1] = next;
                            right += 2;
                        }
                    },
                    '#' => {
                        simulation.position = original_position;
                        continue :top;
                    },
                    '.' => continue,
                    else => unreachable,
                }
            }
            // ...
        } else {
            // Handle horizontal box pushes and regular movement...
        }
    }
    // ...
}
```

For `[` tiles we check the tiles in front of it and to its front right. For `]`, we check its front as well as its front left. We make a special exception and don't enqueue the peeked tile when the current tile is `]` and the peeked tile is `]`. We know this because there are only a few possible patterns here:

1. If the current tile is `[`, we have 2 possible look aheads:
    ```
    1. 
    peeked:  []
    current: [.
        
    2. 
    peeked:  []
    current: .[
    ```
2. If the current tile is `]`, we have 2 possible look aheads, but we ignore 1 because we have parsed it when processing its pair:
    ```
    3. The [ is already parsed in 1., so we don't want to insert it again.
    peeked:  []
    current: .]
    
    4. 
    peeked:  []
    current: ].
    ```

If the boxes are moveable, we'll move them starting from the end by iterating over the queue in reverse. This is the reason why the queue is implemented using an array and why we never popped any items from it.

```zig
fn part2(self: Self) u64 {
    // ...
    top: for (self.instructions.items) |direction| {
        if ((direction == .up or direction == .down) and
            (current_tile == '[' or current_tile == ']'))
        {
            // ...
            for (0..right) |i| {
                simulation.position = queue[right - 1 - i] + direction.vector();
                simulation.set_tile(simulation.peek_tile(direction.opposite()));
                simulation.position -= direction.vector();
                simulation.set_tile('.');
            }
            
            simulation.position = original_position + direction.vector();
        } else {
            // Handle horizontal box pushes and regular movement...
        }
    }
    // ...
}
```

Here's the full `part2` function for your reference:

```zig
fn part2(self: Self) u64 {
    var simulation = self.simulation2;
    const queue_capacity = 256;
    var queue: [queue_capacity][2]i16 = undefined;

    top: for (self.instructions.items) |direction| {
        const original_position = simulation.position;

        simulation.position += direction.vector();

        const current_tile = simulation.get_tile();
        if ((direction == .up or direction == .down) and
            (current_tile == '[' or current_tile == ']'))
        {
            if (simulation.get_tile() == '[') {
                queue[0] = simulation.position;
                queue[1] = simulation.position + Direction.right.vector();
            } else {
                queue[0] = simulation.position + Direction.left.vector();
                queue[1] = simulation.position;
            }

            var left: usize = 0;
            var right: usize = 2;
            while (left < right) : (left += 1) {
                simulation.position = queue[left];
                switch (simulation.peek_tile(direction)) {
                    '[' => {
                        const next = simulation.position + direction.vector();
                        queue[right] = next;
                        queue[right + 1] = next + Direction.right.vector();
                        right += 2;
                    },
                    ']' => {
                        const next = simulation.position + direction.vector();
                        if (!std.meta.eql(queue[right - 1], next)) {
                            queue[right] = next + Direction.left.vector();
                            queue[right + 1] = next;
                            right += 2;
                        }
                    },
                    '#' => {
                        simulation.position = original_position;
                        continue :top;
                    },
                    '.' => continue,
                    else => unreachable,
                }
            }
            
            for (0..right) |i| {
                simulation.position = queue[right - 1 - i] + direction.vector();
                simulation.set_tile(simulation.peek_tile(direction.opposite()));
                simulation.position -= direction.vector();
                simulation.set_tile('.');
            }
            
            simulation.position = original_position + direction.vector();
        } else {
            // Horizontal box pushes has the same logic as part one.
            switch (simulation.get_tile()) {
                '#' => simulation.position -= direction.vector(),
                '.' => {},
                '[', ']' => {
                    var distance: usize = 0;
                    var tile = simulation.get_tile();
                    while (tile == '[' or tile == ']') : (tile = simulation.get_tile()) {
                        distance += 1;
                        simulation.position += direction.vector();
                    }

                    if (tile == '#') {
                        simulation.position = original_position;
                        continue;
                    }

                    for (0..distance) |_| {
                        simulation.set_tile(simulation.peek_tile(direction.opposite()));
                        simulation.position -= direction.vector();
                    }

                    simulation.set_tile('.');
                },
                else => unreachable,
            }
        }
    }

    return simulation.get_sum('[');
}
```


## Benchmark

All benchmarks were performed on an [Apple M3 Pro](https://en.wikipedia.org/wiki/Apple_M3) with times in microseconds (µs).

| Part/Optimise | Debug (µs)  | ReleaseSafe (µs) | ReleaseFast (µs) | ReleaseSmall (µs) |
|-------------- | ----------: | ---------------: | ---------------: | ----------------: |
| Parsing       | 311.0       | 77.5             | 14.6             | 16.6              |
| Part 1        | 634.5       | 212.3            | 228.5            | 257.4             |
| Part 2        | 1,103.9     | 461.0            | 458.3            | 503.1             |
| **Total**     | **2,049.4** | **750.7**        | **701.5**        | **777.1**         |
