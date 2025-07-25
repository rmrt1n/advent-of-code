# Day 16: Reindeer Maze

[Full solution](../src/days/day16.zig).

## Puzzle Input

Today's input is a **reindeer maze**:

```plaintext
###############
#.......#....E#
#.#.###.#.###.#
#.....#.#...#.#
#.###.#####.#.#
#.#.#.......#.#
#.#.#####.###.#
#...........#.#
###.#.#####.#.#
#...#.....#.#.#
#.#.#.###.#.#.#
#.....#...#.#.#
#.###.#.#.#.#.#
#S..#.....#...#
###############
```

We'll parse this into a 2D array and keep track of the start `S` and end `E` positions:

```zig
fn Day16(length: usize) type {
    return struct {
        const Self = @This();

        map: [length][length]u8 = undefined,
        start: [2]i16 = undefined,
        end: [2]i16 = undefined,
        allocator: std.mem.Allocator,

        fn init(input: []const u8, allocator: std.mem.Allocator) Self {
            var result = Self{ .allocator = allocator };

            var i: usize = 0;
            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                for (line, 0..) |tile, j| {
                    switch (tile) {
                        '#', '.' => result.map[i][j] = tile,
                        'S' => {
                            result.map[i][j] = '.';
                            result.start = .{ @intCast(i), @intCast(j) };
                        },
                        'E' => {
                            result.map[i][j] = tile;
                            result.end = .{ @intCast(i), @intCast(j) };
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


## Part One

We need to find the **lowest score** a reindeer could get. The reindeer increases its score every time it moves following these rules:

1. Moving forward increases the score by 1.
2. Turning right/left (rotating by 90 degrees) increases the score by 1000.

Finding the lowest score basically means finding the best path in the maze. We'll use [Dijkstra's algorithm](https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm) for this:

```zig
fn part1(self: Self) !u64 {
    var simulation = self;
    var visited = VisitedSet(length){};

    var queue = std.PriorityQueue(Step1, void, Step1.compare).init(self.allocator, {});
    defer queue.deinit();

    try queue.add(Step1{
        .position = simulation.start,
        .direction = .right,
        .score = 0,
    });

    return while (queue.count() > 0) {
        const step = queue.remove();

        const tile = simulation.get_tile_at(step.position);
        if (tile == 'E') break step.score;

        visited.set(step.position, step.direction, step.score);

        // The more we skip adding to the queue, the less allocations we do.
        for ([_]Direction{ .up, .right, .down, .left }) |direction| {
            if (direction == step.direction.opposite()) continue;

            const next = step.position + direction.vector();
            if (simulation.get_tile_at(next) == '#') continue;

            const increment: u32 = if (direction == step.direction) 1 else 1001;
            const next_score = step.score + increment;

            if (visited.get(next, direction) < next_score) continue;

            try queue.add(Step1{
                .position = next,
                .direction = direction,
                .score = next_score,
            });
        }
    } else unreachable;
}
```

For each step in a path we explore, we store its position, direction, and the accumulated score. We define a type to represent this:

```zig
const Step1 = struct {
    position: [2]i16,
    direction: Direction,
    score: u32,

    fn compare(_: void, a: Step1, b: Step1) std.math.Order {
        return std.math.order(a.score, b.score);
    }
};
```

The `compare` function is passed to the `std.PriorityQueue` so that we always pop the step with the lowest score first. The core principle of Dijkstra is to always process the best/shortest paths first.

> [!NOTE]
> The reason it's called `Step1` because we'll create a slightly different type for part two called `Step2`.

To avoid exploring worse paths, we use a set to store the lowest scores seen at each tile and direction. If we reach a tile in the same direction we've visited it before, we compare the current score with the stored score and keep the lower one (the better path). Here's the definition of the set type:

```zig
fn VisitedSet(comptime length: usize) type {
    return struct {
        const Self = @This();

        map: [length][length][4]u32 = .{.{.{std.math.maxInt(u32)} ** 4} ** length} ** length,

        fn get(self: Self, position: [2]i16, direction: Direction) u32 {
            return self.map[@intCast(position[0])][@intCast(position[1])][@intFromEnum(direction)];
        }

        fn set(self: *Self, position: [2]i16, direction: Direction, score: u32) void {
            self.map[@intCast(position[0])][@intCast(position[1])][@intFromEnum(direction)] = score;
        }
    };
}
```

The `VisitedSet` mirrors the original maze 2D array's dimensions, but instead of the tile character, each position stores an array of 4 scores, one for each direction.

Finally, here are the definitions for the helper functions and types above:

```zig
const Direction = enum {
    up, right, down, left,

    fn vector(direction: Direction) @Vector(2, i8) {
        const directions = [_]@Vector(2, i8){ .{ -1, 0 }, .{ 0, 1 }, .{ 1, 0 }, .{ 0, -1 } };
        return directions[@intFromEnum(direction)];
    }

    fn opposite(direction: Direction) Direction {
        return @enumFromInt((@as(u8, @intFromEnum(direction)) + 2) % 4);
    }
};

fn get_tile_at(self: Self, position: [2]i16) u8 {
    return self.map[@intCast(position[0])][@intCast(position[1])];
}
```

> [!TIP]
> Dijkstra's algorithm is basically BFS but instead of using a regular queue, it uses a priority queue.

## Part Two

We need to count the number of **distinct tiles** that are part of at least one of the best paths in the maze. There can be paths with the same best score we got in part one.

To solve this, we only have to slightly modify our part one code. Now, we'll also store the actual paths taken for each step and explore all possible paths in the maze. Every time we encounter a best path, we insert all of the tiles visited into a set.

The resulting set's item count is the answer. Here's the code for this:

```zig
fn part2(self: Self) !u64 {
    var simulation = self;
    var visited = VisitedSet(length){};

    var queue = std.PriorityQueue(Step2, void, Step2.compare).init(self.allocator, {});
    defer queue.deinit();

    var first_step = Step2{
        .position = simulation.start,
        .direction = .right,
        .score = 0,
        .path = std.ArrayList([2]i16).init(self.allocator),
    };
    try first_step.path.append(self.start);
    try queue.add(first_step);

    var best_score: ?u64 = null;
    var result_set = std.AutoHashMap([2]i16, void).init(self.allocator);
    defer result_set.deinit();

    while (queue.count() > 0) {
        const step = queue.remove();
        defer step.path.deinit();

        const tile = simulation.get_tile_at(step.position);
        if (tile == 'E') {
            if (best_score == null) {
                best_score = step.score; // This is guaranteed to be the best score.
            }
            if (step.score == best_score) {
                // Add all tiles that lead to the best score.
                for (step.path.items) |item| try result_set.put(item, {});
            }
            continue;
        }

        visited.set(step.position, step.direction, step.score);

        // The more we skip adding to the queue, the less allocations we do.
        for ([_]Direction{ .up, .right, .down, .left }) |direction| {
            if (direction == step.direction.opposite()) continue;

            const next = step.position + direction.vector();
            if (simulation.get_tile_at(next) == '#') continue;

            const increment: u32 = if (direction == step.direction) 1 else 1001;
            const next_score = step.score + increment;

            if (visited.get(next, direction) < next_score) continue;

            var new_step = Step2{
                .position = next,
                .direction = direction,
                .score = next_score,
                .path = try step.path.clone(),
            };
            try new_step.path.append(next);
            try queue.add(new_step);
        }
    }

    return result_set.count();
}
```

And the new `Step2` type:

```zig
const Step2 = struct {
    position: [2]i16,
    direction: Direction,
    score: u32,
    path: std.ArrayList([2]i16),

    fn compare(_: void, a: Step2, b: Step2) std.math.Order {
        return std.math.order(a.score, b.score);
    }
};
```

Not the cleanest solution, but at least it works.

## Benchmark

All benchmarks were performed on an [Apple M3 Pro](https://en.wikipedia.org/wiki/Apple_M3) with times in microseconds (µs).

| Part/Optimise | Debug (µs)   | ReleaseSafe (µs) | ReleaseFast (µs) | ReleaseSmall (µs) |
|-------------- | -----------: | ---------------: | ---------------: | ----------------: |
| Parsing       | 153.9        | 49.2             | 12.6             | 46.9              |
| Part 1        | 15,397.6     | 4,676.7          | 2,480.8          | 2,665.8           |
| Part 2        | 48,751.2     | 15,408.5         | 9,010.7          | 9,338.2           |
| **Total**     | **64,302.7** | **20,134.4**     | **11,504.1**     | **12,050.9**      |
