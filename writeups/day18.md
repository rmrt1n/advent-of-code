# Day 18: RAM Run

[Full solution](../src/days/day18.zig).

## Puzzle Input

Today's input is a list of **falling byte** positions:

```plaintext
5,4
4,2
4,5
3,0
2,1
6,3
2,4
1,5
0,6
3,3
2,6
5,1
1,2
5,5
2,5
6,5
1,4
0,4
6,4
1,1
6,1
1,0
0,5
1,6
2,0
```

We'll parse this into an array:

```zig
fn Day18(length: usize) type {
    return struct {
        const Self = @This();

        bytes: [length][2]u8 = undefined,

        fn init(input: []const u8) !Self {
            var result = Self{};

            var i: usize = 0;
            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                var inner_lexer = std.mem.tokenizeScalar(u8, line, ',');
                const y = try std.fmt.parseInt(usize, inner_lexer.next().?, 10);
                const x = try std.fmt.parseInt(usize, inner_lexer.next().?, 10);
                result.bytes[i] = .{ @intCast(x), @intCast(y) };
            }

            return result;
        }
    };
}
```

## Part One

We have to count the **minimum steps** needed to reach the exit in a 71x71 grid after 1024 bytes have fallen. We start at the top left (0, 0) and end at the bottom right (70, 70). Each byte that falls becomes an obstacle.

This is another pathfinding puzzle. We can use BFS to find the path after adding the obstacles. Here's the code:

```zig
const directions: [2]@Vector(2, u1) = .{ .{ 1, 0 }, .{ 0, 1 } };

fn part1(self: Self, comptime map_size: usize, n_bytes: usize) u64 {
    var map: [map_size + 2][map_size + 2]u8 = .{.{'#'} ** (map_size + 2)} ** (map_size + 2);

    @memset(map[1..(map_size + 1)], .{'#'} ++ (.{'.'} ** map_size) ++ .{'#'});
    for (self.bytes[0..n_bytes]) |byte| {
        map[byte[0] + 1][byte[1] + 1] = '#';
    }

    const queue_capacity = 8192;
    var queue: [queue_capacity]struct { position: [2]u8, steps: u32 } = undefined;

    queue[0] = .{ .position = .{ 1, 1 }, .steps = 0 };

    var result: u64 = std.math.maxInt(u64);

    var left: usize = 0;
    var right: usize = 1;
    while (left < right) : (left += 1) {
        const current = queue[left];

        if (std.mem.eql(u8, &current.position, &.{ map_size, map_size })) {
            if (current.steps < result) result = current.steps;
            continue;
        }

        // Check again here because the queue can contain duplicate tiles. It's possibel to
        // pop a visited tile that was just marked in the previous iteration.
        if (map[current.position[0]][current.position[1]] == 'X') continue;

        map[current.position[0]][current.position[1]] = 'X';

        for (directions) |direction| {
            var next = current.position + direction;
            if (map[next[0]][next[1]] != '#' and map[next[0]][next[1]] != 'X') {
                queue[right] = .{ .position = next, .steps = current.steps + 1 };
                right += 1;
            }

            next = current.position - direction;
            if (map[next[0]][next[1]] != '#' and map[next[0]][next[1]] != 'X') {
                queue[right] = .{ .position = next, .steps = current.steps + 1 };
                right += 1;
            }
        }
    }

    return result;
}
```

We accept the map size as a parameter so we can reuse the function for the example inputs too. We also initialised the map with a border just like in previous days for simpler bounds checks. We use `#` to represent obstacles (falling bytes and borders) and `X` for visited tiles.

> [!NOTE]
> The queue capacity is 8192 through trial and error.  I couldn't figure out a way to get the "correct" minimum value, so I just tested numbers until I get one that works for all my inputs.

## Part Two

Now we have to find the first byte that will **prevent the exit from being reachable**. This is a surprisingly easy twist for a part two.

We can solve this by doing the pathfinding for increasing number of bytes. We can reuse part one's function for this. If it returns `std.math.maxInt(u64)`, it means there's no path to the exit.

We could check each byte one at a time, but we can optimise this with a few observations:

1. We can skip the first 1024 bytes. We know this since part one is guaranteed to have a solution.
2. We can use binary search. The input is already ordered so this will speed up the search.

Here's the code:

```zig
fn part2(self: Self, comptime map_size: usize, start: usize) [2]u64 {
    var left = start;
    var right = self.bytes.len;

    while (left < right) {
        const mid = left + (right - left) / 2;
        const result = self.part1(map_size, mid);
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

Just like in part one, the starting position is a parameter so we can reuse the function for the example inputs. For the actual puzzle input, we'll call it with 1025. We return the coordinates because that's what the puzzle asks for.

## Benchmark

All benchmarks were performed on an [Apple M3 Pro](https://en.wikipedia.org/wiki/Apple_M3) with times in microseconds (µs).

| Debug | ReleaseSafe | ReleaseFast | ReleaseSmall |
| ----- | ----------- | ----------- | ------------ |
|       |             |             |              |
