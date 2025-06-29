# Day 01: Historian Hysteria

[Full solution](../src/days/day01.zig).

## Puzzle input

Today's input is a two-column list of **location IDs**:

```plaintext
3   4
4   3
2   5
1   3
3   9
3   3
```

We'll parse the input into two arrays using the tokeniser `std.TokenIterator` from Zig's standard library.

```zig
fn Day01(comptime length: usize) type {
    return struct {
        const Self = @This();

        left: [length]u32 = undefined,
        right: [length]u32 = undefined,

        fn init(input: []const u8) !Self {
            var result = Self{};

            var i: usize = 0;
            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                var inner_lexer = std.mem.tokenizeScalar(u8, line, ' ');
                result.left[i] = try std.fmt.parseInt(u32, inner_lexer.next().?, 10);
                result.right[i] = try std.fmt.parseInt(u32, inner_lexer.next().?, 10);
            }

            return result;
        }
    };
}
```

## Part One

We're asked to find the **total distance** between the two lists. The total distance is the sum of the absolute difference of each pair of location IDs from the two lists sorted.

This is simple enough to implement, here's the code for part one:

```zig
fn part1(self: *Self) u64 {
    std.mem.sort(u32, &self.left, {}, std.sort.asc(u32));
    std.mem.sort(u32, &self.right, {}, std.sort.asc(u32));

    var result: u64 = 0;
    for (self.left, self.right) |x, y| {
        result += @abs(@as(i64, x) - y);
    }
    return result;
}
```

> [!NOTE]
> We cast `x` into a `i64` before calculating the difference or else it will overflow and give us the wrong answer. The return type of `@abs` is the unsigned version of the integer type passed to it. In the code above, since the input is `i64`, the output is a `u64`.

## Part Two

Now we're asked to find the **similarity score**, which is the sum of each location ID from the left list multiplied by how many times it appears in the right list (its frequency).

We'll keep track of the frequency using an array where each index is a location ID from the left list and the value is its frequency in the right list. We use an array for the mapping instead of something like a hash map `std.AutoHashMap` to avoid dynamic allocation.

Once we have the frequencies, we just have to sum them:

```zig
fn part2(self: Self) u64 {
    // Allocate enough space for 10_000 up to 99_999.
    const frequencies_capacity = 100_000;
    var frequencies = [_]u8{0} ** frequencies_capacity;

    var result: u64 = 0;
    for (self.left) |id| {
        result += id * frequencies[id];
    }
    return result;
}
```

We allocated space for 100,000 entries because the location IDs in the puzzle input are all five-digit integers. We're wasting a tiny bit of space here as there are only 90,000 five digit numbers (from 10,000 to 99,999), but it lets us index directly using the location ID and keeps the code simpler.

> [!TIP]
> Whenever possible, prefer static allocation (allocating on the stack) over dynamic allocation (allocating on the heap). Static allocation doesn't have allocator overhead, has better [cache locality](https://stackoverflow.com/questions/12065774/why-does-cache-locality-matter-for-array-performance#12065801), and keeps memory usage predictable. 

## Benchmark

All benchmarks were performed on an [Apple M3 Pro](https://en.wikipedia.org/wiki/Apple_M3) with times in microseconds (µs).

| Debug | ReleaseSafe | ReleaseFast | ReleaseSmall |
| ----- | ----------- | ----------- | ------------ |
|       |             |             |              |
