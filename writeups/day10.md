# Day 10: Hoof It

[Full solution](../src/days/day10.zig).

## Part one

Day ten is another 2D grid puzzle. This time it's a map of elevations (a topographic map), where each tile is a number that represents its height:

```
0123
1234
8765
9876
```

Each map has **trailheads**, which are any position that begins with a height `0` and ends at a height `9`. For part one, we have to find the sum of all **trailhead scores**. The score of a trailhead is the number of `9`-height trails reachable from the start of the trailhead.

First, we'll parse the input:

```zig
fn Day10(length: usize) type {
    return struct {
        map: [length + 2][length + 2]u8 = .{.{10} ** (length + 2)} ** (length + 2),
        starts: std.ArrayList([2]i16) = undefined,
        allocator: std.mem.Allocator,

        const Self = @This();

        fn init(input: []const u8, allocator: std.mem.Allocator) !Self {
            var result = Self{ .allocator = allocator };

            result.starts = std.ArrayList([2]i16).init(allocator);

            var i: usize = 1;
            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                for (line, 1..) |c, j| {
                    const height = c - '0';
                    if (height == 0) try result.starts.append(.{ @intCast(i), @intCast(j) });
                    result.map[i][j] = height;
                }
            }

            return result;
        }
    };
}
```

The map tiles are parsed into their integer representation. Just like in previous days, we'll add a border to the map so that we don't have to check for out of bound errors. Here, the border tile is represented by a `10` height. We're also keeping track of all of the starting positions of the trailheads (the `0` height tiles), since we just have to start from those. This saves around 0.1ms from both parts, which is a small performance boost. Instead of an `std.ArrayList` we could've used a regular array here, but from my benchmarking this doesn't result in much of a difference so I'm keeping this version for simplicity.

This problem maps nicely into a recursive solution, so here is one way to solve it:

```zig
const directions = [_]@Vector(2, i8){ .{ -1, 0 }, .{ 0, 1 }, .{ 1, 0 }, .{ 0, -1 } };

fn get_trailhead_score(
    self: Self,
    pos: [2]i16,
    previous: i8,
    result_set: *std.AutoHashMap([2]i16, void),
) !void {
    if (pos[0] < 0 or pos[0] == self.map.len or pos[1] < 0 or pos[1] == self.map.len) return;

    const current: i8 = @intCast(self.map[@intCast(pos[0])][@intCast(pos[1])]);

    if (current - previous != 1) return;

    if (current == 9) {
        try result_set.put(pos, {});
        return;
    }

    for (directions) |inc| {
        try self.get_trailhead_score(.{ pos[0] + inc[0], pos[1] + inc[1] }, current, result_set);
    }
}
```

This is a depth-first search (DFS) algorithm that recursively goes to the next tile until it finds a `9` tile. It keeps track of all the seen `9` tiles by using a set. An improvement to this is to implement this function iteratively, which results in a roughly 13x performance boost on my machine because the program doesn't have the overhead of creating new stackframes. Here's the previous function refactored to be iterative:

```zig
const StackItem = struct { position: [2]i16, previous: i8 };

fn part1(self: Self) !u64 {
    var result: u64 = 0;
    for (self.starts.items) |point| {
        var stack: [30]StackItem = undefined;
        stack[0] = .{ .position = .{ point[0], point[1] }, .previous = -1 };

        var trail_ends = std.AutoHashMap([2]i16, void).init(self.allocator);
        defer trail_ends.deinit();

        var stack_length: usize = 1;
        while (stack_length > 0) {
            stack_length -= 1;
            const position = stack[stack_length].position;
            const previous = stack[stack_length].previous;

            const current: i8 = @intCast(
                self.map[@intCast(position[0])][@intCast(position[1])],
            );

            if (current == 10 or current - previous != 1) continue;

            if (current == 9) {
                try trail_ends.put(position, {});
                continue;
            }

            for (directions) |direction| {
                stack[stack_length] = .{
                    .position = position + direction,
                    .previous = previous + 1,
                };
                stack_length += 1;
            }
        }
        result += trail_ends.count();
    }
    return result;
}
```

In the iterative solution, the function call stack is replace with.. a regular stack. We can get the trailhead score by getting the number of items in the set of positions.

Here I went ahead and skipped an optimization step to keep this writeup from being too long. Originally I used `std.ArrayList` to implement the stack, popping items in each iteration. I replaced this with a regular array after finding the maximum number of items in the stack, which is less than 30. This resulted in around a 3x speedup. Another optimization that can be done here is to use a "struct of arrays" instead of an "array of structs". This is a common pattern in [data-oriented design](https://en.wikipedia.org/wiki/Data-oriented_design) to make better use of the CPU cache. In my case, I did a benchmark of both but didn't find a huge increase in the struct of arrays approach so I kept the code as is.

## Part two

Like most people, I too solved part two before solving part one because I didn't read the puzzle description correctly. For part two, instead of the trailhead score, we have to find the **trailhead rating**, which is the number of distinct trails that start from a trailhead. This is one of those days where the part two is easier than the part one.

In our recursive solution from before, we just have to modify it a little bit to get the trailhead score:

```zig
fn get_trailhead_rating(self: Self, pos: [2]i16, previous: i8) u32 {
    if (pos[0] < 0 or pos[0] == self.map.len or pos[1] < 0 or pos[1] == self.map.len) return 0;

    const current: i8 = @intCast(self.map[@intCast(pos[0])][@intCast(pos[1])]);

    if (current - previous != 1) return 0;

    if (current == 9) return 1;

    var result: u32 = 0;
    for (directions) |inc| {
        result += self.get_trailhead_rating(.{ pos[0] + inc[0], pos[1] + inc[1] }, current);
    }
    return result;
}
```

Since each iteration (through recursion) goes to a different tile, when we reach a `9` tile we're guaranteed to come from a different trail. Here is the function in an iterative style:

```zig
fn part2(self: Self) !u64 {
    var result: u32 = 0;
    for (self.starts.items) |point| {
        var stack: [30]StackItem = undefined;
        stack[0] = .{ .position = .{ point[0], point[1] }, .previous = -1 };

        var stack_length: usize = 1;
        while (stack_length > 0) {
            stack_length -= 1;
            const position = stack[stack_length].position;
            const previous = stack[stack_length].previous;

            const current: i8 = @intCast(
                self.map[@intCast(position[0])][@intCast(position[1])],
            );

            if (current == 10 or current - previous != 1) continue;

            if (current == 9) {
                result += 1;
                continue;
            }

            for (directions) |direction| {
                stack[stack_length] = .{
                    .position = position + direction,
                    .previous = previous + 1,
                };
                stack_length += 1;
            }
        }
    }
    return result;
}
```

## Benchmarks
