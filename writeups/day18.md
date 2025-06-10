# Day 18:

[Full solution](../src/days/day18.zig).

## Part one

Day 18 is another 2D grid puzzle in disguise. The input doesn't look like one, but the puzzle itself is a 2D grid:

```
5,4
4,2
4,5
3,0
2,1
6,3
2,4
1,5
0,6
```

Each line in the puzzle input represent a coordinate where a byte will fall into a memory space (our 2D grid). This memory space can be any size, but for both parts the grid will be 71 rows x 71 cols. Our character is placed at coordinate `0,0` and we have to move it to the end of the space `71,71`. After each step, a byte will fall.

For part one, we have to find the minimum number of steps needed to get to the end of the memory space after 1024 bytes have fallen. First, we'll parse the input:

```zig
fn Day18(length: usize) type {
    return struct {
        bytes: [length][2]usize = undefined,
        allocator: std.mem.Allocator,

        const Self = @This();

        fn init(input: []const u8, allocator: std.mem.Allocator) !Self {
            var result = Self{ .allocator = allocator };

            var i: usize = 0;
            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                var inner_lexer = std.mem.tokenizeScalar(u8, line, ',');
                const y = try std.fmt.parseInt(usize, inner_lexer.next().?, 10);
                const x = try std.fmt.parseInt(usize, inner_lexer.next().?, 10);
                result.bytes[i] = .{ x, y };
            }

            return result;
        }
    };
}
```

Part one's solution is a simple BFS. We'll create a map (matrix) to represent the memory space, iterate through the first 1024 lines of the input, set the tiles in the map to obstacle tiles, then run BFS to get the shortest path. Here's the code:

```zig
fn part1(self: Self, comptime map_size: usize, n_bytes: usize) !u64 {
    var map: [map_size + 2][map_size + 2]u8 = undefined;

    @memset(map[1..(map_size + 1)], .{'#'} ++ (.{'.'} ** map_size) ++ .{'#'});
    @memset(&map[0], '#');
    @memset(&map[map_size + 1], '#');

    for (0..n_bytes) |i| {
        const coordinate = self.bytes[i] + @Vector(2, usize){ 1, 1 };
        map[coordinate[0]][coordinate[1]] = '#';
    }

    var result: u64 = std.math.maxInt(u64);

    var queue = std.ArrayList(Point).init(self.allocator);
    defer queue.deinit();

    try queue.append(.{ .pos = .{ 1, 1 }, .steps = 0 });

    const end = [_]i16{ map_size, map_size };
    while (queue.items.len > 0) {
        const current = queue.pop().?;
        if (std.mem.eql(i16, &current.pos, &end)) {
            if (current.steps < result) result = current.steps;
            continue;
        }

        if (map[@intCast(current.pos[0])][@intCast(current.pos[1])] == 'X') continue;

        map[@intCast(current.pos[0])][@intCast(current.pos[1])] = 'X';

        for (directions) |direction| {
            const next = current.pos + direction;
            if (map[@intCast(next[0])][@intCast(next[1])] == '#') continue;
            try queue.append(.{ .pos = next, .steps = current.steps + 1 });
        }
    }

    return result;
}

const Point = struct {
    pos: [2]i16,
    steps: u32,
};
```

Just like in some of the previous 2D grid problems, we add a border to the map to simplify the out of bounds check. This day's `part1` function is a bit different from other days because it has a lot more parameters. This is just to make it easier to test the function, because the map size and number of fallen bytes in the example input is different from the puzzle's.

## Part two

In part two, our new task is to determine the first byte that will block the path to the exit. This is a surprisingly easy part two for a later day puzzle.

Here, we can reuse the code from part one, the try every `n_bytes` value starting from 1025 (we know from part one that after 1024 there is always a path) until the end of the puzzle input. My first attempt at the solution looked like this:

```zig
fn part2(self: Self, comptime map_size: usize, n_bytes: usize) ![2]u64 {
    for (n_bytes..length) |i| {
        const res = try self.part1(map_size, i);
        if (res == std.math.maxInt(u64)) {
            return .{ self.bytes[i - 1][1], self.bytes[i - 1][0] };
        }
    }
    return .{ 0, 0 };
}
```

This works, but is a bit slow — it takes around 45 ms on my laptop. I wanted something faster. This is a good example of using a more efficient algorithm to improve performance. Here, we can replace the linear scan (O(N)) with a binary search (O(log N)):

```zig
fn part2(self: Self, comptime map_size: usize, n_bytes: usize) ![2]u64 {
    var left = n_bytes;
    var right = self.bytes.len;

    while (left < right) {
        const mid = left + (right - left) / 2;
        const result = try self.part1(map_size, mid);
        if (result == std.math.maxInt(u64)) {
            right = mid;
        } else {
            left = mid + 1;
        }
    }

    // No need to handle edge cases here as we're guaranteed a solution.

    return .{ self.bytes[left - 1][1], self.bytes[left - 1][0] };
}
```

This cut down the runtime of part two to just around 0.40 ms. That's more than 100x faster!

## Benchmarks
