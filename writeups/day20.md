# Day 20: Race Condition

[Full solution](../src/days/day20.zig).

## Puzzle Input

Today's input is a map of a **race track**:

```plaintext
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

The race track is a single path from the start tile `S` to the end tile `E`. We'll parse the map into a 2D array and store the start and end positions:

```zig
fn Day20(comptime length: usize) type {
    return struct {
        const Self = @This();

        const path: u32 = std.math.maxInt(u32);

        map: [length][length]u32 = undefined,
        start: [2]i16 = undefined,
        end: [2]i16 = undefined,

        fn init(data: []const u8) Self {
            var result = Self{};

            var i: usize = 0;
            var lexer = std.mem.tokenizeScalar(u8, data, '\n');
            while (lexer.next()) |line| : (i += 1) {
                for (line, 0..) |c, j| {
                    switch (c) {
                        '#' => result.map[i][j] = '#',
                        '.' => result.map[i][j] = path,
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

> [!NOTE]
> The path `.` tiles are parsed as `std.math.maxInt(u32)` instead of their original character. The reason for this will become apparent in part one.

## Part One

We have to find the number of **cheats that save at least 100 picoseconds**.

Normally a race's duration is the same as the number of path tiles `.` it has, since each step takes 1 picosecond. Once during a race, you're allowed to **cheat** following these rules:

1. You can go through obstacle tiles `#` for the duration of the cheat. In this case it is 2 picoseconds.
2. Cheats must end on a path tile.
3. Cheats are identified by their start and end positions. Even if multiple cheat paths exist from the same start and end position, they count as a single cheat. In this case, we take the **best cheat**, which is the path that saves the most time.

The examples shows cheats taking different paths, but we don't actually care about the exact path. We just need the minimum number of tiles needed to reach a cheat end tile.

We can calculate this using the concept of [Manhattan distance](https://en.wikipedia.org/wiki/Taxicab_geometry). In plain terms, the manhattan distance of two points is the minimum number of steps needed to move from one point to another, using only horizontal and vertical movements (no diagonals). In math terms, it is defined as the sum of the absolute differences of their coordinates:

$$
Manhattan((x_1,y_1),(x_2,y_2)) = |x_1 - x_2| + |y_1 - y_2|
$$

When activating a cheat, the possible end tiles are those within a Manhattan distance **less than or equal to the cheat duration**. Cheats may also end early, so the reachable area forms a diamond-shaped region centered on the start tile. This region is the cheat "window."

When we activate a cheat, the possible end tiles are only those within a Manhattan distance equal to or less than the cheat duration. It can be less than the Manhattan distance because cheats can end early. The reachable tiles forms a diamond-shaped window. We can use this window to find all valid cheats for a starting tile.

Here's an example to visualise the window for the starting position $i,j$:

```plaintext
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

All the tiles marked `.......` are unreachable.

We'll create a function to count the total number of cheats given the cheat duration and the minimum time saved (100 picoseconds in this case). The function is a bit long, so I'll break it down.

The first thing we'll do is build a list of path tile positions. Later, we'll iterate through this list and find all valid cheats starting from each tile position:

```zig
const directions = [_]@Vector(2, i8){ .{ -1, 0 }, .{ 0, 1 }, .{ 1, 0 }, .{ 0, -1 } };

fn count_cheats(self: *Self, cheat_duration: i32, min_time_saved: u32) u64 {
    const track_capacity = 10_000;
    var race_track: [track_capacity][2]i32 = undefined;

    var i: u32 = 0;
    while (!std.mem.eql(i16, &self.start, &self.end)) : (i += 1) {
        for (directions) |direction| {
            const next = self.start + direction;
            if (self.get_tile_at(next) == path) {
                race_track[i] = .{ self.start[0], self.start[1] };
                self.set_tile_at(self.start, i);
                self.start = next;
                break;
            }
        }
    }
    race_track[i] = .{ self.end[0], self.end[1] };
    self.set_tile_at(self.end, i);
    
    // ...
}
```

While building the list of positions, we also mapped each position to the time it takes to reach it without cheats. We'll need this to calculate how much time is saved by cheating to a certain tile. Instead of using a hash map `std.AutoHashMap`, we'll mutate the map tiles directly. This is why the original path tiles are parsed as `std.math.maxInt(u32)`, so that we avoid conflicts—the `.` (ASCII value 46) collides with 46 picoseconds.

Next, we'll iterate over every tile in the race track. For each tile, we'll find every cheat end tile in the diamond window. If the cheat saves at least 100 picoseconds, we'll increment the result:

```zig
fn count_cheats(self: *Self, cheat_duration: i32, min_time_saved: u32) u64 {
    // ...
    
    var result: u64 = 0;
    for (race_track[0..(i + 1)], 0..) |tile, pico_seconds| {
        const tile_x, const tile_y = tile;
        const x_min: usize = @intCast(@max(tile_x - cheat_duration, 0));
        const x_max: usize = @intCast(@min(tile_x + cheat_duration + 1, length));
        const y_min: usize = @intCast(@max(tile_y - cheat_duration, 0));
        const y_max: usize = @intCast(@min(tile_y + cheat_duration + 1, length));

        for (x_min..x_max) |x| {
            for (y_min..y_max) |y| {
                const abs_x = @abs(@as(i32, @intCast(x)) - tile_x);
                const abs_y = @abs(@as(i32, @intCast(y)) - tile_y);

                const manhattan_distance = abs_x + abs_y;
                if (manhattan_distance > cheat_duration) continue;

                const end_tile = self.get_tile_at(.{ @intCast(x), @intCast(y) });
                if (end_tile != '#') {
                    const peek_time = end_tile;

                    // No use cheating here...
                    if (peek_time <= pico_seconds + manhattan_distance) continue;

                    const time_saved = peek_time - pico_seconds - manhattan_distance;
                    result += @intFromBool(time_saved >= min_time_saved);
                }
            }
        }
    }
    return result;
}
```

The time saved by a cheat is the normal travel time to reach the cheat end tile from its start tile, minus the manhattan distance of the cheat. 

Now all we have to do in our `part`1 function is call `count_cheats` with the correct arguments:

```zig
fn part1(self: *Self) u64 {
    return self.count_cheats(2, 100);
}
```

Here are the definitions for the helper functions:

```zig
fn get_tile_at(self: Self, position: [2]i16) u32 {
    return self.map[@intCast(position[0])][@intCast(position[1])];
}

fn set_tile_at(self: *Self, position: [2]i16, tile: u32) void {
    self.map[@intCast(position[0])][@intCast(position[1])] = tile;
}
```

And here's the full `count_cheats` function for your reference:

```zig
fn count_cheats(self: *Self, cheat_duration: i32, min_time_saved: u32) u64 {
    const track_capacity = 10_000;
    var race_track: [track_capacity][2]i32 = undefined;

    var i: u32 = 0;
    while (!std.mem.eql(i16, &self.start, &self.end)) : (i += 1) {
        for (directions) |direction| {
            const next = self.start + direction;
            if (self.get_tile_at(next) == path) {
                race_track[i] = .{ self.start[0], self.start[1] };
                self.set_tile_at(self.start, i);
                self.start = next;
                break;
            }
        }
    }
    race_track[i] = .{ self.end[0], self.end[1] };
    self.set_tile_at(self.end, i);

    var result: u64 = 0;
    for (race_track[0..(i + 1)], 0..) |tile, pico_seconds| {
        const tile_x, const tile_y = tile;
        const x_min: usize = @intCast(@max(tile_x - cheat_duration, 0));
        const x_max: usize = @intCast(@min(tile_x + cheat_duration + 1, length));
        const y_min: usize = @intCast(@max(tile_y - cheat_duration, 0));
        const y_max: usize = @intCast(@min(tile_y + cheat_duration + 1, length));

        for (x_min..x_max) |x| {
            for (y_min..y_max) |y| {
                const abs_x = @abs(@as(i32, @intCast(x)) - tile_x);
                const abs_y = @abs(@as(i32, @intCast(y)) - tile_y);

                const manhattan_distance = abs_x + abs_y;
                if (manhattan_distance > cheat_duration) continue;

                const end_tile = self.get_tile_at(.{ @intCast(x), @intCast(y) });
                if (end_tile != '#') {
                    const peek_time = end_tile;

                    // No use cheating here...
                    if (peek_time <= pico_seconds + manhattan_distance) continue;

                    const time_saved = peek_time - pico_seconds - manhattan_distance;
                    result += @intFromBool(time_saved >= min_time_saved);
                }
            }
        }
    }
    return result;
}
```


## Part Two

We still have to find the number of cheats that saves at least 100 seconds, but now the **cheat duration is 20 picoseconds**.

We can just call `count_cheats` again but use 20 as the value of `cheat_duration`:

```zig
fn part2(self: *Self) u64 {
    return self.count_cheats(20, 100);
}
```

Two short part twos in a row!

## Benchmark

All benchmarks were performed on an [Apple M3 Pro](https://en.wikipedia.org/wiki/Apple_M3) with times in microseconds (µs).

| Debug | ReleaseSafe | ReleaseFast | ReleaseSmall |
| ----- | ----------- | ----------- | ------------ |
|       |             |             |              |
