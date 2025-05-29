# Day 14: Restroom Redoubt

[Full solution](../src/days/day14.zig).

## Part one

For day 14 we're given a list of robot **positions** and **velocities**, with one robot per line:

```
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

These robots inhabit a bathroom map (a 2D grid), and every second the robot moves in the vector specified by its velocity. E.g., in the first second, the first robot will move three tiles to the right and three tiles down from the position (0, 4) and end up at (3, 1). If the robot moves out of the bounds of the map, it will **teleport** or wrap around to the other side.

For part one, we're asked to find the **safety factor** of the bathroom after a certain duration, which in this case is 100 seconds. The safety factor is the result of multiplying the number of robots in each quadrant of the map.

First things first, we'll parse the input:

```zig
fn Day14(length: usize) type {
    return struct {
        robot_positions: [length][2]i32 = undefined,
        robot_velocities: [length][2]i32 = undefined,
        map_size: [2]u8,

        const Self = @This();

        fn init(input: []const u8, map_size: [2]u8) !Self {
            var result = Self{ .map_size = map_size };

            var i: usize = 0;
            var lexer = std.mem.tokenizeAny(u8, input, "\n ");
            while (lexer.next()) |line| : (i += 1) {
                var inner_lexer = std.mem.tokenizeScalar(u8, line[2..], ',');
                result.robot_positions[i][0] = try std.fmt.parseInt(i32, inner_lexer.next().?, 10);
                result.robot_positions[i][1] = try std.fmt.parseInt(i32, inner_lexer.next().?, 10);

                inner_lexer = std.mem.tokenizeScalar(u8, lexer.next().?[2..], ',');
                result.robot_velocities[i][0] = try std.fmt.parseInt(i32, inner_lexer.next().?, 10);
                result.robot_velocities[i][1] = try std.fmt.parseInt(i32, inner_lexer.next().?, 10);
            }

            return result;
        }
    };
}
```

We'll take the map dimension as an argument so that it's easier to test. In part one, the map size is 101 tiles by 103 tiles, but the example given uses a map of size 11x7.

To get the final position after a certain time has passed, we can use the equation for displacement:

$$
\vec{r} = \vec{r_0} + \vec{v} \cdot t
$$

Where:
- $\vec{r}$ is the displacement or the resulting position. The arrow on top signifies that it's a vector.
- $\vec{r_0}$ is the starting position.
- $\vec{v}$ is the velocity.
- $t$ is the time taken.

To account for the teleportation, we'll [mod](https://en.wikipedia.org/wiki/Modulo) the resulting position with the map size. This will wrap the robot back into the map from the other side.

To solve part one, we'll have to iterate over all robots, calculate the final position, and find the quadrant it is in. Here is the code for this:

```zig
fn part1(self: Self, seconds: usize) u64 {
    var counts: @Vector(4, u64) = @splat(0);
    const mid_point = .{ self.map_size[0] / 2, self.map_size[1] / 2 };
    for (self.robot_positions, self.robot_velocities) |position, velocity| {
        const i_seconds: i32 = @intCast(seconds);
        const destination = .{
            @mod((position[0] + velocity[0] * i_seconds), self.map_size[0]),
            @mod((position[1] + velocity[1] * i_seconds), self.map_size[1]),
        };
        counts += [_]u1{
            @intFromBool(destination[0] < mid_point[0] and destination[1] < mid_point[1]),
            @intFromBool(destination[0] < mid_point[0] and destination[1] > mid_point[1]),
            @intFromBool(destination[0] > mid_point[0] and destination[1] < mid_point[1]),
            @intFromBool(destination[0] > mid_point[0] and destination[1] > mid_point[1]),
        };
    }
    var result: u64 = 1;
    for (0..4) |i| result *= counts[i];
    return result;
}
```

We can check if a robot is in a specific quadrant by comparing its position with the mid point, e.g. if a robot's X and Y position are both less than the midpoint, it is in the first quadrant. We'll store the robot count of each quadrant in a vector so that we avoid branching from doing if checks (although the Zig compiler might be smart enough to optimize it by itself?). Then we just get the product of the quadrant counts.

## Part two

Day 14 is probably one of the coolest puzzles this year. It turns out that after a certain duration has passed, the robots will group together to form a picture of a christmas tree! We have to find the lowest duration where the robots will form this picture.

The description for part two is really short and didn't even show what the christmas tree looked like. The way I originally solved it was to print the map each iteration into a file, then manually look for anything that looked like the tree. I did this after scrolling through the Advent subreddit hoping to find a screenshot of the tree.

It worked, but I wanted an automated solution. After reading other solutions, I found out that a hint to part two was given in part one. It turns out that you can use the safety factor of the map to detect if the map has the christmas tree.

The safety factor can act as a measure of the entropy of an image (in this case our map). A more structured image has a lower entropy than random pixels. I've read some comments saying that this doesn't work on all inputs, but it worked for mine so that's good enough for me.

For part two, we'll calculate the safety factor for every second until 10,403, which is 103 multiplied by 101. There is only a limited number of ways the robots can be arranged in the map, and after a certain iteration (the previous number), it will repeat itself. We'll reuse part one to get the safety factor, so the code for part two looks like:

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

This was a very cool puzzle with a lot of different solutions. Checkout the other solutions in the [Advent subreddit](https://www.reddit.com/r/adventofcode/comments/1hdvhvu/2024_day_14_solutions/), some of them are very creative!

## Benchmarks
