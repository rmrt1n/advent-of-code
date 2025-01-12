# Day 01: Historian Hysteria

[Full solution](../src/days/day01.zig).

## Part one

We're asked to find the **total distance** from two lists of location IDs that are placed side-by-side in our puzzle input, which looks like:

```
3   4
4   3
2   5
1   3
3   9
3   3
```

The total distance is the sum of the absolute difference of each pair of location IDs from the two lists sorted. It doesn't matter which direction the lists are sorted as long as both of them are sorted in the same direction.

To get started, we'll parse the input into two arrays `left` and `right`. We'll be using Zig's builtin tokenizer for this:

```zig
fn Day01(comptime length: usize) type {
    return struct {
        left: [length]u32 = undefined,
        right: [length]u32 = undefined,

        const Self = @This();

        fn init(input: []const u8) !Self {
            var result = Self{};

            var i: usize = 0;
            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                var inner_lexer = std.mem.tokenizeScalar(u8, line, ' ');
                result.left[i] = try std.fmt.parseInt(u32, inner_lexer.next().?, 10);
                result.right[i] = try std.fmt.parseInt(u32, inner_lexer.next().?, 10);
            }

            std.mem.sort(u32, &result.left, {}, std.sort.asc(u32));
            std.mem.sort(u32, &result.right, {}, std.sort.asc(u32));

            return result;
        }
    };
}
```

We'll sort the arrays in the parsing function in case both parts needed them sorted. Next we'll iterate over both arrays, calculate the absolute difference of each pair, and sum them all up to get the answer for part one.

```zig
fn part1(self: Self) u64 {
    var result: u64 = 0;
    for (self.left, self.right) |x, y| {
        result += @intCast(@abs(@as(i64, x) - y));
    }
    return result;
}
```

## Part two

For part two, we're asked for the **similarity score**, which is the sum of each number (location ID) in the left list multiplied by its frequency in the right list. In other words, we have to count how many times a number in the left list appears in the right list.

We can do this with a hashmap, e.g. Zig's `std.AutoHashmap`, but since the location IDs have at most five digits (from inspecting the input file) we can just use a regular array of size 100,000 (to hold all five digit numbers). `std.AutoHashmap` does dynamic allocation, which will slow down our solution a bit, though the difference is negligible in day one.

```zig
fn part2(self: Self) u64 {
    var frequencies = [_]u8{0} ** 100_000;
    for (self.right) |id| {
        frequencies[id] += 1;
    }
    var result: u64 = 0;
    for (self.left) |id| {
        result += id * frequencies[id];
    }
    return result;
}
```

Once we have the frequencies in the array, we can iterate over each number in the `left` array and calculate the similarity score. Sum it all up to get the answer for part two.

## Benchmarks
