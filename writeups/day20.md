# Day 20:

[Full solution](../src/days/day20.zig).

## Part one

Day 20 we're given a 2D grid representation of a race track:

```
###############
#...#...#.....#
#.#.#.#.#.###.#
#S#...#.#.#...#
#######.#.#.###
#######.#.#...#
#######.#.###.#
###..E#...#...#
###.#######.###
#...###...#...#
#.#####.#.###.#
#.#...#.#.#...#
#.#.#.#.#.#.###
#...#...#...###
###############
```

There is only one path from the start tile (`S`) to the end tile (`E`). As always, obstacle tiles are represented by `#` and path tiles by `.`. Every time you move along the track, your race time is incremented by one second. This means the total race time is the length of the race track.

For part one, **exactly once** during a race, you can disable collision for two seconds, i.e. pass through an obstacle to get to a path. This is called a **cheat** and allows you to finish the race with a faster time. Each cheat has a distinct start and end position. If two different cheats have the same start and end position, they're the same cheat, even if they save different times. If you find the same cheat with different times, you're supposed to only count the best cheat, which is the cheat that saved the most time.

For this day, we can have a general solution that works for both parts, just like day 11 and 19. Before going over the code, I'll explain about the solution first.

In part one, our cheat duration is two seconds. This means that we can jump to any tile that's at most two [manhattan distance](https://en.wikipedia.org/wiki/Taxicab_geometry) away from the current tile. Manhattan distance is a way to measure the distance between two points in a grid (by summing the absolute differences of their coordinates). In simpler terms, the manhattan distance between two tiles is how many steps it takes to get from tile A to tile B (movement can only be horizontal or vertical, diagonal is not allowed). The formula is:

$$
Manhattan((x_1,y_1),(x_2,y_2)) = |x_1 - x_2| + |y_1 - y_2|
$$

Here's an example to visualize:

```
┌─────────┬─────────┬─────────┬─────────┬─────────┬─────────┬─────────┐
│ ······· │ ······· │ ....... │  i-3,j  │ ······· │ ....... │ ....... │
├─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ ······· │ ....... │ i-2,j-1 │  i−2,j  │ i-2,j+1 │ ....... │ ....... │
├─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ ....... │ i-1,j-2 │ i-1,j-1 │  i−1,j  │ i−1,j+1 │ i-1,j+2 │ ....... │
├─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│  i,j−3  │  i,j−2  │  i,j−1  │   i,j   │  i,j+1  │  i,j+2  │  i,j+3  │
├─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ ....... │ i+1,j−2 │ i+1,j-1 │  i+1,j  │ i+1,j+1 │ i+1,j+2 │ ....... │
├─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ ······· │ ....... │ i+2,j-1 │  i+2,j  │ i+2,j+1 │ ....... │ ....... │
├─────────┼─────────┼─────────┼─────────┼─────────┼─────────┼─────────┤
│ ······· │ ······· │ ....... │  i+3,j  │ ······· │ ....... │ ....... │
└─────────┴─────────┴─────────┴─────────┴─────────┴─────────┴─────────┘
```

Above is a grid where the starting tile is `i,j` and the cheat duration (the max manhattan distance) is 3. The tiles with `.......` are unreachable within the cheat duration. So for our solution, we only have to check if the reachable tiles are valid path tiles, not obstacle tiles. Then, we have to check if cheating to that tile reduces the race time.

To get the saved time by cheating from tile A to tile B, we can subtract the normal time it takes to get from A to B with the cheat duration. The normal time is that time taken to get to a tile without using any cheats. In our case, since it takes one second to move one tile, the normal time taken to reach the $n^\th$ tile is $n$ seconds.

Okay, now let's get to the code. First we'll parse the input:

```zig
const path: u32 = std.math.maxInt(u32);
const obstacle: u32 = path - 1;

fn Day20(comptime length: usize) type {
    return struct {
        map: [length][length]u32 = undefined,
        start: [2]i16 = undefined,
        end: [2]i16 = undefined,

        const Self = @This();

        fn init(data: []const u8) Self {
            var result = Self{};

            var i: usize = 0;
            var lexer = std.mem.tokenizeScalar(u8, data, '\n');
            while (lexer.next()) |line| : (i += 1) {
                for (line, 0..) |c, j| {
                    switch (c) {
                        '.' => result.map[i][j] = path,
                        '#' => result.map[i][j] = obstacle,
                        'S' => result.start = .{ @intCast(i), @intCast(j) },
                        'E' => {
                            result.end = .{ @intCast(i), @intCast(j) };
                            result.map[i][j] = path;
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

To count the time saved, we'll need a mapping of a tile to its time taken. We can use a separate hashmap for this, but I'll just modify the map to store the time taken in the tile itself. I'll represent path tiles as `std.math.maxInt(u32)` for now, but later we'll change these to their corresponding time taken. Obstacles are represented as `std.math.maxInt(u32) - 1` just so that the time taken doesn't conflict with the other tile representations.

Next, we'll create a `count_cheats` function that will return the number of cheats that will save you at least `min_duration` with a certain `cheat_duration`. The function is a bit long, so I'll step through it one section at a time:

```zig
fn count_cheats(self: *Self, cheat_duration: i32, min_duration: u32) u32 {
    // My path length is around 9500, so allocate enough space for it.
    var race_track: [10_000][2]i32 = undefined;

    // Get the race path.
    var i: u32 = 0;
    while (!std.mem.eql(i16, &self.start, &self.end)) : (i += 1) {
        for (directions) |direction| {
            const next = self.start + direction;
            if (self.map[@intCast(next[0])][@intCast(next[1])] == path) {
                race_track[i] = .{ self.start[0], self.start[1] };
                self.map[@intCast(self.start[0])][@intCast(self.start[1])] = i;
                self.start = next;
                break;
            }
        }
    }
    race_track[i] = .{ self.end[0], self.end[1] };
    self.map[@intCast(self.end[0])][@intCast(self.end[1])] = i;

    // ...
}
```

The first part of the function finds the tiles of the race track. It appends it to an array and also updates the path tiles in the map with its corresponding time taken. We do this first so that when we iterate over the tiles, we already have the tile -> time taken mapping. Here's the next part of the function:

```zig
fn count_cheats(self: *Self, cheat_duration: i32, min_duration: u32) u32 {
    // ...
    var frequencies = [_]u32{0} ** 10_000;
    for (race_track, 0..) |tile, seconds| {
        var x = @max(tile[0] - cheat_duration, 0);
        while (x < @min(tile[0] + cheat_duration + 1, length)) : (x += 1) {
            var y = @max(tile[1] - cheat_duration, 0);
            while (y < @min(tile[1] + cheat_duration + 1, length)) : (y += 1) {
                const manhattan_distance = @abs(x - tile[0]) + @abs(y - tile[1]);
                if (manhattan_distance > cheat_duration) continue;

                if (self.map[@intCast(x)][@intCast(y)] != obstacle) {
                    const peek_seconds = self.map[@intCast(x)][@intCast(y)];

                    // No use cheating here...
                    if (peek_seconds <= seconds + manhattan_distance) continue;

                    const seconds_saved = peek_seconds - seconds - manhattan_distance;
                    frequencies[seconds_saved] += 1;
                }
            }
        }
    }
    // ...
}
```

Here, we iterate over all the tiles reachable within the manhattan distance (`cheat_duration`). If the tile is not an obstacle tile, we check the time saved by cheating to it. If the time taken with the cheat is greather than or equal to the normal time taken, it means the cheat is useless so we just continue.

We store the frequency of saved time instead of a mapping of cheat to time saved because we don't care about the cheat coordinates. The loop used guarantees that we won't get the same cheat coordinates twice, so we can just store the frequency of saved time, which is what we needed. As always, whenever you can use a regular array insted of a `std.AutoHashmap`, use the regular array.

The `x` and `y` loops are a bit unintuitive, so here's a simpler version of what it does:

```zig
var x = tile[0] - cheat_duration;
while (x < @tile[0] + cheat_duration + 1) : (x += 1) {
    var y = tile[1] - cheat_duration;
    while (y < @tile[1] + cheat_duration + 1) : (y += 1) {
        if (x < 0 or x >= length or y < 0 or y >= length) continue;
    }
}
```

Basically what I did was do the bounds check before the loop, e.g. if `tile[0] - cheat_duration` is less than 0 (out of bounds), start the loop from 0 instead. Here's the last section of the function:

```zig
fn count_cheats(self: *Self, cheat_duration: i32, min_duration: u32) u32 {
    // ...
    var result: u32 = 0;
    for (frequencies[min_duration..]) |count| result += count;
    return result;
}
```

For all saved time, if the duration is at least `min_duration`, add its frequency to the result. That's all we need to solve both parts! Here's the function in its entirety:

```zig
fn count_cheats(self: *Self, cheat_duration: i32, min_duration: u32) u32 {
    // My path length is around 9500, so allocate enough space for it.
    var race_track: [10_000][2]i32 = undefined;

    // Get the race path.
    var i: u32 = 0;
    while (!std.mem.eql(i16, &self.start, &self.end)) : (i += 1) {
        for (directions) |direction| {
            const next = self.start + direction;
            if (self.map[@intCast(next[0])][@intCast(next[1])] == path) {
                race_track[i] = .{ self.start[0], self.start[1] };
                self.map[@intCast(self.start[0])][@intCast(self.start[1])] = i;
                self.start = next;
                break;
            }
        }
    }
    race_track[i] = .{ self.end[0], self.end[1] };
    self.map[@intCast(self.end[0])][@intCast(self.end[1])] = i;

    var frequencies = [_]u32{0} ** 10_000;
    for (race_track, 0..) |tile, seconds| {
        var x = @max(tile[0] - cheat_duration, 0);
        while (x < @min(tile[0] + cheat_duration + 1, length)) : (x += 1) {
            var y = @max(tile[1] - cheat_duration, 0);
            while (y < @min(tile[1] + cheat_duration + 1, length)) : (y += 1) {
                const manhattan_distance = @abs(x - tile[0]) + @abs(y - tile[1]);
                if (manhattan_distance > cheat_duration) continue;

                if (self.map[@intCast(x)][@intCast(y)] != obstacle) {
                    const peek_seconds = self.map[@intCast(x)][@intCast(y)];

                    // No use cheating here...
                    if (peek_seconds <= seconds + manhattan_distance) continue;

                    const seconds_saved = peek_seconds - seconds - manhattan_distance;
                    frequencies[seconds_saved] += 1;
                }
            }
        }
    }

    var result: u32 = 0;
    for (frequencies[min_duration..]) |count| result += count;
    return result;
}
```

Finally, the `part1` function just calls `count_cheats`:

```zig
fn part1(self: *Self) u64 {
    return self.count_cheats(2, 100);
}
```

## Part two

In part two, the cheat duration is increased to 20. Since `count_cheats` already has the cheat duration as a parameter, we can just change it when calling the function:

```zig
fn part2(self: *Self) u64 {
    return self.count_cheats(20, 100);
}
```

## Benchmarks
