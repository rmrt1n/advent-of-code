# Day 15: Warehouse Woes

[Full solution](../src/days/day15.zig).

## Part one

Our fifth 2D grid puzzle. We're given a map of a warehouse that looks like this:

```
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
```

The `@` character is a robot. It attempts to move following its instructions and pushes boxes `O` that are in its way. Boxes cannot be pushed into a wall `#`. The tricky part here is that if multiple boxes in a sequence are pushed, all of them will be moved. After moving based on all of its instructions, the boxes in the map will be reorganized. Our task for the day is to get the sum of the coordinates of all the boxes.

Instead of regular x and y coordinate values, the coordinate of a box is 100 times its distance from the top edge of the map plus its distance from the left edge of the map.

This day requires quite a lot of code, so first we'll create a helper struct with common 2D grid navigating functionalities:

```zig
fn Simulation(comptime rows: usize, comptime columns: usize) type {
    return struct {
        map: [rows][columns]u8 = undefined,
        position: @Vector(2, i16) = undefined,

        const Self = @This();

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
}
```

I refactored my code after the challenge has ended so it's easier to read, but in reality when you're doing the challenge you probably won't write tidy code. The `Simulation` type will be a base type that the part-specific types will "inherit".

Also, we'll bring in the direction enum from previous days:

```zig
const Direction = enum {
    up, right, down, left,

    fn vector(direction: Direction) @Vector(2, i8) {
        const directions = [_][2]i8{ .{ -1, 0 }, .{ 0, 1 }, .{ 1, 0 }, .{ 0, -1 } };
        return directions[@intFromEnum(direction)];
    }

    pub fn opposite(direction: Direction) Direction {
        return @enumFromInt((@as(u8, @intFromEnum(direction)) + 2) % 4);
    }
};
```

Okay, now let's parse the input file:

```zig
fn Day15(length: usize) type {
    return struct {
        simulation1: SimulationPart1(length) = SimulationPart1(length){},
        instructions: std.ArrayList(Direction) = undefined,
        allocator: std.mem.Allocator,

        const Self = @This();

        fn init(input: []const u8, allocator: std.mem.Allocator) !Self {
            var result = Self{ .allocator = allocator };
            result.instructions = std.ArrayList(Direction).init(allocator);

            var i: usize = 0;
            var lexer = std.mem.splitScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                if (line.len == 0) break;
                for (line, 0..) |c, j| {
                    result.simulation1.base.map[i][j] = c;
                    if (c == '@') {
                        result.simulation1.base.map[i][j] = '.';
                    }
                }
            }

            while (lexer.next()) |line| {
                if (line.len == 0) break;
                for (line) |c| {
                    const dir = switch (c) {
                        '<' => Direction.left,
                        '>' => Direction.right,
                        '^' => Direction.up,
                        'v' => Direction.down,
                        else => unreachable,
                    };
                    try result.instructions.append(dir);
                }
            }

            return result;
        }
    };
}
```

The map is parsed into the `SimulationPart1` type (we'll get to this in a bit) that wraps a base `Simulation` type. The map already has a border, so we don't have to add it ourselves. Next, the instructions are parsed into an `std.ArrayList`. Based on my benchmarks using a regular array over `std.ArrayList` here doesn't really result in faster code, so I left it as is.

Now let's get to the implementation. For part one we just have to iterate over the instructions and move the robot and boxes accordingly. Here's the code for the `SimulationPart1` struct I talked about earlier:

```zig
fn SimulationPart1(comptime length: usize) type {
    return struct {
        base: Simulation(length, length) = Simulation(length, length){},

        const Self = @This();

        fn move(self: *Self, direction: Direction) void {
            var simulation = &self.base;
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
                        return;
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
    };
}
```

The `move` function performs a single step given a direction to move to. If we encounter a box, we peek in the directin of the box until we reach either an obstacle `#` tile or an empty `.` tile. If we see an obstacle, it means that the boxes can't be moved, we'll just return. If we see an empty tile, we'll move all of the boxes one tile forward. Now we just have to combine this with the instructions:

```zig
fn part1(self: Self) u64 {
    var simulation = self.simulation1;
    for (self.instructions.items) |direction| {
        simulation.move(direction);
    }
    return simulation.base.get_sum('O');
}
```

`get_sum` is a method in `Simulation` that calculates the sum of the coordinates of the boxes:

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

`box_characters` denote what character represents the boxes. I wrote it this way just so that I can reuse it for part two.


## Part two

The twist in part two is that the warehouse is actually twice as wide. Our parsing rules are changed as follows:

- If the tile is #, the new map contains ## instead.
- If the tile is O, the new map contains [] instead.
- If the tile is ., the new map contains .. instead.
- If the tile is @, the new map contains @. instead.

Because boxes (`[]`) are two tiles wide now, a new problem is presented to us. The box-pushing behavior of the robot is the same for horizontal steps, but it's a bit different for vertical steps. If the robot is directly under/above either the left or right side of the box:

```
...
[].
@..
```

The box can be pushed. The most frustrating part of this change is that you can get this configuration:

```
.....
[][].
.[]..
.@...
```

In this case, the if the robot moves up, all three boxes are moved up. We have to figure out a way to check if a box above/under another box can be pushed along. First things first, let's update our parsing function to parse part two:

```zig
fn Day15(length: usize) type {
    return struct {
        // ...
        simulation2: SimulationPart2(length) = SimulationPart2(length){},

        const Self = @This();

        fn init(input: []const u8, allocator: std.mem.Allocator) !Self {
            var result = Self{ .allocator = allocator };
            result.instructions = std.ArrayList(Direction).init(allocator);

            var i: usize = 0;
            var lexer = std.mem.splitScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                if (line.len == 0) break;
                for (line, 0..) |c, j| {
                    result.simulation1.base.map[i][j] = c;
                    const wide_tile = switch (c) {
                        '#' => "##",
                        'O' => "[]",
                        '.', '@' => "..",
                        else => unreachable,
                    };
                    @memcpy(result.simulation2.base.map[i][(2 * j)..(2 * j + 2)], wide_tile);
                    if (c == '@') {
                        result.simulation1.base.map[i][j] = '.';
                        result.simulation1.base.position = .{ @intCast(i), @intCast(j) };
                        result.simulation2.base.position = .{ @intCast(i), @intCast(j * 2) };
                    }
                }
            }

            // ...
        }
    };
}
```

Now for the solution. Since only the columns are doubled, the logic for horizontal box pushes is still the same, with the exception of the different box characters. The only new code we have to write is for vertical movement. Here's the entry point to part two:

```zig
fn part2(self: Self) u64 {
    var simulation = self.simulation2;
    for (self.instructions.items) |direction| {
        switch (direction) {
            .left, .right => simulation.move_horizontal(direction),
            .up, .down => simulation.move_vertical(direction),
        }
    }
    return simulation.base.get_sum('[');
}
```

For `SimulationPart2`, we can copy+paste the `move` method from part one for `move_horizontal.` Here's the code:

```zig
fn SimulationPart2(comptime length: usize) type {
    return struct {
        base: Simulation(length, length * 2) = Simulation(length, length * 2){},

        const Self = @This();

        fn move_horizontal(self: *Self, direction: Direction) void {
            var simulation = &self.base;
            const original_position = simulation.position;
            simulation.position += direction.vector();
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
                        return;
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
    };
}
```

Now for the hard part. We have to come up with a new box-pushing logic. First, I'll show you the full code for vertical movement first then I'll explain it in detail:

```zig
fn SimulationPart2(comptime length: usize) type {
    return struct {
        // ...

        fn move_vertical(self: *Self, direction: Direction) void {
            var simulation = &self.base;
            const original_position = simulation.position;
            simulation.position += direction.vector();
            switch (simulation.get_tile()) {
                '[', ']' => {
                    var queue: [30][2]i16 = undefined;
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
                                return;
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
                },
                // Other cases just handle like you would in a horizontal movement.
                '#', '.' => {
                    simulation.position -= direction.vector();
                    self.move_horizontal(direction);
                },
                else => unreachable,
            }
        }
    };
}
```

Here, I used a queue to keep track of the boxes that is in front of the robot. I got magic number `30` for the queue size after experimenting with different values. It was the smallest number that didn't crash the program. This queue holds the coordinates of the boxes' left ('[') and right (`]`) part. The logic goes like this:

1. We start with the left and right side of the box directly above/under the robot. Add them to the queue. The left part always goes first.
    ```zig
    var queue: [30][2]i16 = undefined;
    if (simulation.get_tile() == '[') {
        queue[0] = simulation.position;
        queue[1] = simulation.position + Direction.right.vector();
    } else {
        queue[0] = simulation.position + Direction.left.vector();
        queue[1] = simulation.position;
    }
    ```
2. Then, we iterate through the queue items. For each part, we peek the next tile in the direction we're moving in. If the tile is another part of a box, we'll add both of its part into the queue. If it's an obstacle tile, we just return and process the next instruction. I used a regular array as my "queue" here and iterate through the items FIFO, except that none of the items are popped out as we'll need to use them again later.
    ```zig
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
                return;
            },
            '.' => continue,
            else => unreachable,
        }
    }
    ```

    Note: we make a special exception when the peeked tile is `]`. If it's the same value as the last item in the queue, we have already parsed it so we just continue. We know this because there are only a few possible patterns here:

    ```
    1. 
    peeked:  []
    current: [.

    2. 
    peeked:  []
    current: .[

    3. 
    peeked:  [] # This is already parse by 1., so we don't have to add it again to the queue
    current: .]

    4. 
    peeked:  []
    current: ].
    ```

    I hope this explanation makes sense, as I don't know a better way to explain it...
3. If we reached this step, it means that we can push all of the boxes in the queue one tile in the direction we're moving. Here, I iterate through the queue in reverse, for each tile I copied the value, pasted it in the next tile in the direction, and replaced the old tile with `.`.
    ```zig
    for (0..right) |i| {
        simulation.position = queue[right - 1 - i] + direction.vector();
        simulation.set_tile(simulation.peek_tile(direction.opposite()));
        simulation.position -= direction.vector();
        simulation.set_tile('.');
    }
    simulation.position = original_position + direction.vector();
    ```

And that's it. I didn't like this day. Procrastinated writing this writeup for six months because it's such a pain to write.

## Benchmarks
