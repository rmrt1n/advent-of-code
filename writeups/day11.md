# Day 11: Plutonian Pebbles

[Full solution](../src/days/day11.zig).

## Part one

Day eleven was my first introduction to the [lanternfish](https://www.reddit.com/r/adventofcode/comments/1hn2osp/note_to_self_always_ask_is_this_lanternfish/). This was the first day that stumped me so hard I had to look at other people's solutions to understand how to solve it. Thanks to this thoough I know how to solve the later challenges that were also lanternfishes.

The puzzle input is very short, e.g. `125 17`. Each number here is engraved on a stone. Every time we **blink**, the stones will evolve following these rules:

1. If the stone is a 0, it becomes a 1.
2. If the stone is has an even number of digits, it will be split from the middle into two stones. E.g., 2024 will be split into the stones 20 and 24. Leading zeros are ignored.
3. If rules 1 and 2 didn't apply, the stone's number is multiplied by 2024.

There's not a lot to do to parse the input:

```zig
fn Day11(length: usize) type {
    return struct {
        stones: [length]u32 = undefined,
        allocator: std.mem.Allocator,

        const Self = @This();

        fn init(input: []const u8, allocator: std.mem.Allocator) !Self {
            var result = Self{ .allocator = allocator };

            var i: usize = 0;
            var lexer = std.mem.tokenizeScalar(u8, std.mem.trim(u8, input, "\n"), ' ');
            while (lexer.next()) |line| : (i += 1) {
                result.stones[i] = try std.fmt.parseInt(u32, line, 10);
            }

            return result;
        }
    };
}
```

For part one we have to count the number of stones after 25 blinks. We can solve this very naively by simulating the blinks in a list, i.e. updating the list after each iteration. This may work for part one, but it will not work for part two, or at least it will take an extrememly long time for the code to finish.

Instead, we have to keep track of the counts of each stone each iteration, and add the previous counts in the current iteration, i.e. memoization. We'll use a hashmap to store the stone counts, as the numbers are really big and we would be wasting more space if we use a regular array as a map like in previous days.

We'll define a `count_stones` function that will return the number of stones after a certain number of blinks, passed as an argument to the function:

```zig
fn count_stones(self: Self, n_blinks: u8) !u64 {
    var frequencies = std.AutoHashMap(u64, u64).init(self.allocator);
    defer frequencies.deinit();

    for (self.stones) |stone| try frequencies.put(stone, 1);

    for (0..n_blinks) |_| {
        var new_frequencies = std.AutoHashMap(u64, u64).init(self.allocator);
        var iterator = frequencies.iterator();
        while (iterator.next()) |entry| {
            const stone = entry.key_ptr.*;
            const count = entry.value_ptr.*;

            // If the stone is 0, it becomes a 1.
            if (stone == 0) {
                const value = try new_frequencies.getOrPutValue(1, 0);
                value.value_ptr.* += count;
                continue;
            }

            // If the stone has an odd number of digits, it is multiplied by 2024.
            const n = std.math.log10(stone) + 1;
            if (n % 2 == 1) {
                const value = try new_frequencies.getOrPutValue(stone * 2024, 0);
                value.value_ptr.* += count;
                continue;
            }

            // If the stone has an even number of digits, it is split in two.
            const ten_power_n = std.math.pow(u64, 10, n / 2);
            const left_value = try new_frequencies.getOrPutValue(stone / ten_power_n, 0);
            left_value.value_ptr.* += count;
            const right_value = try new_frequencies.getOrPutValue(stone % ten_power_n, 0);
            right_value.value_ptr.* += count;
        }
        frequencies.deinit();
        frequencies = new_frequencies;
    }

    var result: u64 = 0;
    var iterator = frequencies.valueIterator();
    while (iterator.next()) |value| {
        result += value.*;
    }
    return result;
}
```

This is how lanternfish algorithms usually look like. For every evolved stone, we add the count of the previous stone to it. We keep doing this until the number of blinks is reached. Like in day seven, we can get number of digits of a stone by getting its log10 added by one. To get the left side of the stone, we divide it with $10^{n / 2}$ and to get the right side we get the remainder of the division.

And that's day 11 solved. The part one code is just a thin wrapper over this function:

```zig
fn part1(self: Self) !u64 {
    return try self.count_stones(25);
}
```

## Part two

Part two is also a thin wrapper over `count_stones`. This time, instead of 25 blinks, we have to blink 75 times:

```zig
fn part2(self: Self) !u64 {
    return try self.count_stones(75);
}
```

## Benchmarks
