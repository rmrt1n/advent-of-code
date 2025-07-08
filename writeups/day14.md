# Day 14: Restroom Redoubt

[Full solution](../src/days/day14.zig).

## Puzzle Input

Today's input is a list of robot **positions** and **velocities**:

```plaintext
p=0,4 v=3,-3
p=6,3 v=-1,-3
p=10,3 v=-1,2
p=2,0 v=2,-1
p=0,0 v=1,3
p=3,0 v=-2,-2
p=7,6 v=-1,-3
p=3,0 v=-1,-2
p=9,3 v=2,3
p=7,3 v=-1,2
p=2,4 v=2,-3
p=9,5 v=-3,-3
```

We'll parse the input into two array of vectors, one for positions and the other for velocities:

```zig
fn Day14(length: usize) type {
    return struct {
        const Self = @This();

        positions: [length]@Vector(2, i32) = undefined,
        velocities: [length]@Vector(2, i32) = undefined,
        map_size: @Vector(2, u16),

        fn init(input: []const u8, map_size: [2]u16) !Self {
            var result = Self{ .map_size = map_size };

            var i: usize = 0;
            var lexer = std.mem.tokenizeAny(u8, input, "\n ");
            while (lexer.next()) |line| : (i += 1) {
                var inner_lexer = std.mem.tokenizeScalar(u8, line[2..], ',');
                result.positions[i][0] = try std.fmt.parseInt(i32, inner_lexer.next().?, 10);
                result.positions[i][1] = try std.fmt.parseInt(i32, inner_lexer.next().?, 10);

                inner_lexer = std.mem.tokenizeScalar(u8, lexer.next().?[2..], ',');
                result.velocities[i][0] = try std.fmt.parseInt(i32, inner_lexer.next().?, 10);
                result.velocities[i][1] = try std.fmt.parseInt(i32, inner_lexer.next().?, 10);
            }

            return result;
        }

    };
}
```

> [!NOTE]
> We pass the `map_size` as a parameter because it can be different for the actual puzzle vs the examples.

## Part One

We have to calculate the **safety factor** after 100 seconds have elapsed. The safety factor is the product of the number of robots in each quadrant. Robots that are exactly in the middle don't count and should be ignored.

To get the final position of each robot, we add its position vector with its velocity vector multiplied by the duration of the simulation. Since robots wrap around the map, we'll modulo the result with the map size.

Since we parsed the positions and velocities as vectors, we can use regular arithmetic operations on it as if they're just regular integers. To check if a robot is in a specific quadrant, we compare its position against the midpoint.

Here's the code:

```zig
fn part1(self: Self, seconds: i32) u64 {
    const seconds_vector: @Vector(2, i32) = @splat(seconds);
    const mid_point = self.map_size / [_]u8{ 2, 2 };

    var counts: @Vector(4, u64) = @splat(0);
    for (self.positions, self.velocities) |position, velocity| {
        const destination = @mod(position + velocity * seconds_vector, self.map_size);
        const offset_x, const offset_y = destination - mid_point;

        counts += @intFromBool(@Vector(4, bool){
            offset_x < 0 and offset_y < 0,
            offset_x < 0 and offset_y > 0,
            offset_x > 0 and offset_y < 0,
            offset_x > 0 and offset_y > 0,
        });
    }
    return @reduce(.Mul, counts);
}
```

> [!NOTE]
> We pass the `seconds` as a parameter because we'll need to simulate the robots after different numbers of seconds in part two.

## Part Two

Today's part two is one of the most creative puzzles I've seen. We have to find the exact number of seconds needed for the robot to form a **Christmas tree**.

I originally solved this by printing each "frame" and manually inspecting them to find the tree. This worked, but I wanted an automated solution.

A hint was given in part one. The safety factor of the map can act as a measure of its entropy. A more structured image (e.g. a Christmas tree), has a lower entropy than a random distribution of pixels. To get our answer, we have to find the value for `seconds` that results in the lowest safety factor:

```zig
fn part2(self: Self) u64 {
    var result: u64 = 0;
    var safety_factor_min: u64 = std.math.maxInt(u64);

    for (0..(self.map_size[0] * self.map_size[1])) |seconds| {
        const safety_factor = self.part1(seconds);
        if (safety_factor < safety_factor_min) {
            safety_factor_min = safety_factor;
            result = seconds;
        }
    }

    return result;
}
```

> [!NOTE]
> The search space is bounded. After `self.map_size[0] * self.map_size[1]` seconds, the robot positions start to repeat.

## Benchmark

All benchmarks were performed on an [Apple M3 Pro](https://en.wikipedia.org/wiki/Apple_M3) with times in microseconds (µs).

| Debug | ReleaseSafe | ReleaseFast | ReleaseSmall |
| ----- | ----------- | ----------- | ------------ |
|       |             |             |              |
