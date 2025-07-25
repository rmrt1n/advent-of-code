# Day 11: Plutonian Pebbles

[Full solution](../src/days/day11.zig).

## Puzzle Input

Today's input is a list of **stones** with numbers on them, arranged in a single line:

```plaintext
125 7
```

We'll parse the input into an array:

```zig
fn Day11(length: usize) type {
    return struct {
        const Self = @This();

        stones: [length]u32 = undefined,
        allocator: std.mem.Allocator,

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

## Part One

We need to count the number of stones after **25 blinks**. Every time we blink, the stones change following these rules:

1. If the stone is a `0`, it becomes a `1`.
2. If the stone has an even number of digits, it will be split into two stones. E.g. `1234` will be split into `12` and `34`. Leading zeros are ignored.
3. If rules 1 and 2 didn't apply, multiply the stone by `2024`.

We could implement this naively by simulating the stones using a list, but this quickly becomes inefficient, especially when we get to higher blink counts. The puzzle description says that the order of the stones must be preserved, but it doesn't actually matter for counting stones.

Instead of simulating the blinks (this grows exponentially), we keep track of their frequencies using a hash map `std.AutoHashMap`. Each blink, we use the values from the previous blink to compute the current one. 

We'll define a `count_stones` function to count stones given the number of blinks. It's a bit long, so I'll break it down into several parts:

Instead of creating a new map for every blink, we'll pre-allocate two maps and alternate between them each iteration. Doing this significantly reduces the number of allocations required:

```zig
fn count_stones(self: Self, n_blinks: u8) !u64 {
    var frequencies: [2]std.AutoHashMap(u64, u64) = undefined;
    for (0..2) |i| frequencies[i] = std.AutoHashMap(u64, u64).init(self.allocator);
    defer for (0..2) |i| frequencies[i].deinit();

    var id: usize = 0;
    for (self.stones) |stone| try frequencies[id].put(stone, 1);
    
    // ...
}
```

We also insert the initial stones from our input into the first map. I assumed the stones in the puzzle input are unique, so I initialised their frequencies to 1.

Next, we'll run the simulation for the blink count:

```zig
fn count_stones(self: Self, n_blinks: u8) !u64 {
    // ...

    for (0..n_blinks) |_| {
        var old_frequencies = &frequencies[id % 2];
        var new_frequencies = &frequencies[(id + 1) % 2];
        id += 1;

        defer old_frequencies.clearRetainingCapacity();

        var iterator = old_frequencies.iterator();
        while (iterator.next()) |entry| {
            const stone = entry.key_ptr.*;
            const count = entry.value_ptr.*;

            if (stone == 0) {
                const value = try new_frequencies.getOrPutValue(1, 0);
                value.value_ptr.* += count;
                continue;
            }

            const n_digits = std.math.log10(stone) + 1;
            if (n_digits % 2 == 1) {
                const value = try new_frequencies.getOrPutValue(stone * 2024, 0);
                value.value_ptr.* += count;
                continue;
            }

            const ten_power_n = std.math.pow(u64, 10, n_digits / 2);
            const left_value = try new_frequencies.getOrPutValue(stone / ten_power_n, 0);
            left_value.value_ptr.* += count;
            const right_value = try new_frequencies.getOrPutValue(stone % ten_power_n, 0);
            right_value.value_ptr.* += count;
        }
    }
    
    // ...
}
```

We swap maps by using a rolling index. For each stone we insert into the new map, we'll add their previous frequency from the old map.

Finally, all we have to do is get the sum of the frequencies:

```zig
fn count_stones(self: Self, n_blinks: u8) !u64 {
    // ...

    var result: u64 = 0;
    var iterator = frequencies[id % 2].valueIterator();
    while (iterator.next()) |value| {
        result += value.*;
    }
    return result;
}
```

The part one code is just a simple wrapper that calls this function with 25 blinks:

```zig
fn part1(self: Self) !u64 {
    return try self.count_stones(25);
}
```

And here's the full code of `count_stones` for your reference:

```zig
fn count_stones(self: Self, n_blinks: u8) !u64 {
    var frequencies: [2]std.AutoHashMap(u64, u64) = undefined;
    for (0..2) |i| frequencies[i] = std.AutoHashMap(u64, u64).init(self.allocator);
    defer for (0..2) |i| frequencies[i].deinit();

    var id: usize = 0;
    for (self.stones) |stone| try frequencies[id].put(stone, 1);

    for (0..n_blinks) |_| {
        var old_frequencies = &frequencies[id % 2];
        var new_frequencies = &frequencies[(id + 1) % 2];
        id += 1;

        defer old_frequencies.clearRetainingCapacity();

        var iterator = old_frequencies.iterator();
        while (iterator.next()) |entry| {
            const stone = entry.key_ptr.*;
            const count = entry.value_ptr.*;

            if (stone == 0) {
                const value = try new_frequencies.getOrPutValue(1, 0);
                value.value_ptr.* += count;
                continue;
            }

            const n_digits = std.math.log10(stone) + 1;
            if (n_digits % 2 == 1) {
                const value = try new_frequencies.getOrPutValue(stone * 2024, 0);
                value.value_ptr.* += count;
                continue;
            }

            const ten_power_n = std.math.pow(u64, 10, n_digits / 2);
            const left_value = try new_frequencies.getOrPutValue(stone / ten_power_n, 0);
            left_value.value_ptr.* += count;
            const right_value = try new_frequencies.getOrPutValue(stone % ten_power_n, 0);
            right_value.value_ptr.* += count;
        }
    }

    var result: u64 = 0;
    var iterator = frequencies[id % 2].valueIterator();
    while (iterator.next()) |value| {
        result += value.*;
    }
    return result;
}
```

## Part Two

Instead of 25 blinks, we have to count the number of stones after **75 blinks**.

We don't have any new code for part two. Just update the blink count from 25 with 75 and we're done:

```zig
fn part2(self: Self) !u64 {
    return try self.count_stones(75);
}
```

> [!TIP]
> This was my first introduction to the [lanternfish](https://www.reddit.com/r/adventofcode/comments/1hn2osp/note_to_self_always_ask_is_this_lanternfish/). It's a typical Advent of Code puzzle pattern where naive, brute force solutions don't work due to exponential growth. The solutions usually require some form of [memoization](https://en.wikipedia.org/wiki/Memoization).

## Benchmark

All benchmarks were performed on an [Apple M3 Pro](https://en.wikipedia.org/wiki/Apple_M3) with times in microseconds (µs).

| Part/Optimise | Debug (µs)   | ReleaseSafe (µs) | ReleaseFast (µs) | ReleaseSmall (µs) |
|-------------- | -----------: | ---------------: | ---------------: | ----------------: |
| Parsing       | 1.0          | 0.1              | 0.1              | 0.1               |
| Part 1        | 933.6        | 47.8             | 43.8             | 68.2              |
| Part 2        | 32,657.6     | 2,548.1          | 2,115.2          | 2,797.4           |
| **Total**     | **33,592.2** | **2,596.1**      | **2,159.1**      | **2,865.7**       |
