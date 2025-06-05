# Day 16:

[Full solution](../src/days/day16.zig).

## Part one

In day 16, we're given (you guessed it), yet another 2D grid puzzle. Our input is a map of a maze that looks like this:

```
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

This is a pathfinding puzzle. `S` is our starting position and `E` is the destination. We have to find the fastest path to reach the destination. We start facing east and move one tile at a time. A twist here is that the fastest path is indicated by the **score**. When we move forwards one tile, it increases the score by one. When we rotate 90 degrees, it increases the score by 1000.


For part one, we have to find the lowest score possible (the fastest path). First, let's parse the input:

```zig
fn Day16(length: usize) type {
    return struct {
        map: [length][length]u8 = undefined,
        start: [2]i16 = undefined,
        end: [2]i16 = undefined,
        allocator: std.mem.Allocator,

        const Self = @This();

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

Here we parsed the map into a matrix and store the start and end positions. Again, I'll bring in the `Direction` enum from previous days:

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
```

As with most pathfinding puzzles, we can use [Djikstra's algorithm](https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm) to solve this puzzle. This was my first time using Djikstra, so I was surprised to find out that Djikstra is just BFS, but instead of a regular queue you use a priority queue.

A nice part about Zig is that it already has a priority queue in its standard library, so we can just use that. The solution is a bit long, so I'll step through sections of the code:

```zig
fn part1(self: Self) !u64 {
    var simulation = self;
    var visited = VisitedSet(length){};

    var queue = std.PriorityQueue(Point1, void, Point1.compare).init(self.allocator, {});
    defer queue.deinit();

    try queue.add(Point1{
        .position = simulation.start,
        .direction = .right,
        .score = 0,
    });
    // ...
}
```

The first line just makes a copy of the current struct. We're going to mutate the map, so I made a copy so that part two still has access to the original data. `visited` is a set of the tiles we've visited before and the previously seen score. Before we get to the Djikstra's part, here is the definition of `Point1` and `VisitedSet`:

```zig
const Point1 = struct {
    position: [2]i16,
    direction: Direction,
    score: u32,

    fn compare(_: void, a: Point1, b: Point1) std.math.Order {
        return std.math.order(a.score, b.score);
    }
};
```

`Point1` (the `1` means it's just for part one) is a type for storing metadata about a tile for a specific iteration. It contains the position, direction, and the current score. The `compare` method is needed to get the correct ordering/priority by `std.PriorityQueue`.

Next, here's the definition of `VisitedSet`:

```zig
fn VisitedSet(comptime length: usize) type {
    return struct {
        map: [length][length][4]u32 = .{.{.{std.math.maxInt(u32)} ** 4} ** length} ** length,

        const Self = @This();

        fn get(self: Self, position: [2]i16, direction: Direction) u32 {
            return self.map[@intCast(position[0])][@intCast(position[1])][@intFromEnum(direction)];
        }

        fn set(self: *Self, position: [2]i16, direction: Direction, score: u32) void {
            self.map[@intCast(position[0])][@intCast(position[1])][@intFromEnum(direction)] = score;
        }
    };
}
```

The visited set is implemented as a matrix of `[4]u32`, which holds the last score when we visited a tile in a specific direction. This array is indexed using the point's direction. I factored out this type just because hardcoding the get and set operations in the solution function itself would make the line too long. The explicit type casts you have to do is one of the most annoying parts of zig. It makes what would've been an elegant function look like [Malboge](https://en.wikipedia.org/wiki/Malbolge).

Here's the implementation of Djikstra's algorithm:

```zig
fn part1(self: Self) !u64 {
    // ...
    const result = while (queue.count() > 0) {
        const point = queue.remove();
        const tile = simulation.get_tile_at(point.position);
        if (tile == 'E') break point.score;

        visited.set(point.position, point.direction, point.score);

        // The more we skip adding to the queue, the less allocations we do.
        for ([_]Direction{ .up, .right, .down, .left }) |direction| {
            if (direction == point.direction.opposite()) continue;

            const next = point.position + direction.vector();
            if (simulation.get_tile_at(next) == '#') continue;

            const increment: u32 = if (direction == point.direction) 1 else 1001;
            const next_score = point.score + increment;

            if (visited.get(next, direction) < next_score) continue;

            try queue.add(Point1{
                .position = next,
                .direction = direction,
                .score = next_score,
            });
        }
    } else unreachable;
    return result;
}
```

It looks exactly like BFS. For each point popped from the queue:

1. If it is the exit tile, we return it as it is the answer. This is a greedy algorithm, so the first answer we get is always the fastest path.
2. Add the tile to the visited set.
3. For all directions we can go to, move to that tile and increment the score based on the rules mentioned earlier. Note, we skip adding a tile in the queue if:
    a. It is an obstacle `#` tile, or
    b. We have visited it previously in the same direction, but the previous score is lower than the current one. This means that we have found a faster path earlier, so we should just return.

We do the next tile checks before we add to the queue so that we can reduce allocations. We could've put the checks before the inner loop, but it would result in slower code because we are doing more allocations by adding more stuff to the queue. The puzzle will always have a solution, so we can mark returning from the loop without the score as unreachable. Here's the full code for part one:

```zig
fn part1(self: Self) !u64 {
    var simulation = self;
    var visited = VisitedSet(length){};

    var queue = std.PriorityQueue(Point1, void, Point1.compare).init(self.allocator, {});
    defer queue.deinit();

    try queue.add(Point1{
        .position = simulation.start,
        .direction = .right,
        .score = 0,
    });

    const result = while (queue.count() > 0) {
        const point = queue.remove();
        const tile = simulation.get_tile_at(point.position);
        if (tile == 'E') {
            break point.score;
        }

        visited.set(point.position, point.direction, point.score);

        // The more we skip adding to the queue, the less allocations we do.
        for ([_]Direction{ .up, .right, .down, .left }) |direction| {
            if (direction == point.direction.opposite()) continue;

            const next = point.position + direction.vector();
            if (simulation.get_tile_at(next) == '#') continue;

            const increment: u32 = if (direction == point.direction) 1 else 1001;
            const next_score = point.score + increment;

            if (visited.get(next, direction) < next_score) continue;

            try queue.add(Point1{
                .position = next,
                .direction = direction,
                .score = next_score,
            });
        }
    } else unreachable;
    return result;
}
```

Before I forget, here is the definition of the helper function `get_tile_at`:

```zig
fn get_tile_at(self: Self, position: [2]i16) u8 {
    return self.map[@intCast(position[0])][@intCast(position[1])];
}
```

## Part two

Part two asks for the number of unique tiles on the best path(s) in the maze. There can be multiple different paths with the same lowest score we calculated in part one. This means we have to find all of the paths for getting the best score.

After looking at other people's solutions, some of them uses a reverse BFS from the end tile using the map of scores already computed in part one. Since one of my self-imposed constraints is that both parts should be solved separately, I can't do any additional work in part one that will speed up part two. I'll have to start from scratch.

I went with the most straightforward way to do this. Keep the greedy algorithm from part one with the addition that points must also contain the list of tiles that they have visited. In the while loop, the first time we encounter the `E` we'll know the best score. We'll then create a set of tiles visited that led to this score. Instead of returning immediately, we continue until we have emptied the queue. Whenever we reach another `E` tile, we'll compare the scores. If the score is the best score, we'll add the tiles from the point's list to the set.

We'll update the point type to store the list of tiles visited:

```zig
const Point2 = struct {
    position: [2]i16,
    direction: Direction,
    score: u32,
    path: std.ArrayList([2]i16),

    fn compare(_: void, a: Point2, b: Point2) std.math.Order {
        return std.math.order(a.score, b.score);
    }
};
```

The code is very similar to part one, so I'll just paste the entire function here:

```zig
fn part2(self: Self) !u64 {
    var simulation = self;
    var visited = VisitedSet(length){};

    var queue = std.PriorityQueue(Point2, void, Point2.compare).init(self.allocator, {});
    defer queue.deinit();

    var first_point = Point2{
        .position = simulation.start,
        .direction = .right,
        .score = 0,
        .path = std.ArrayList([2]i16).init(self.allocator),
    };
    try first_point.path.append(self.start);
    try queue.add(first_point);

    var best_score: ?u64 = null;
    var result_set = std.AutoHashMap([2]i16, void).init(self.allocator);
    defer result_set.deinit();

    while (queue.count() > 0) {
        const point = queue.remove();
        defer point.path.deinit();

        const tile = simulation.get_tile_at(point.position);
        if (tile == 'E') {
            if (best_score == null) {
                best_score = point.score; // This is guaranteed to be the best score.
            }
            if (point.score == best_score) {
                // Add all tiles that lead to the best score.
                for (point.path.items) |item| try result_set.put(item, {});
            }
            continue;
        }

        visited.set(point.position, point.direction, point.score);

        // The more we skip adding to the queue, the less allocations we do.
        for ([_]Direction{ .up, .right, .down, .left }) |direction| {
            if (direction == point.direction.opposite()) continue;

            const next = point.position + direction.vector();
            if (simulation.get_tile_at(next) == '#') continue;

            const increment: u32 = if (direction == point.direction) 1 else 1001;
            const next_score = point.score + increment;

            if (visited.get(next, direction) < next_score) continue;

            var new_point = Point2{
                .position = next,
                .direction = direction,
                .score = next_score,
                .path = try point.path.clone(),
            };
            try new_point.path.append(next);
            try queue.add(new_point);
        }
    }

    return result_set.count();
}
```

The length of the visited tiles set is the number of unique paths leading to the best score, so that is the answer for part two. This is probably not the fastest or most optimized way to do this, but it works and isn't too slow, so that's enough for me.

## Benchmarks
