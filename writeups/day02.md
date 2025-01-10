# Day 02: Red-Nosed Reports

[Full solution](../src/days/day02.zig).

## Part one

For day two we're given a list of reports, where each report is a list of levels separated by a space:

```
7 6 4 2 1
1 2 7 8 9
9 7 6 2 1
1 3 2 4 5
8 6 4 4 1
1 3 6 7 9
```

The task for part one is to count the number of **safe levels**. A level is safe if it satisfies two properties:

1. The levels are either all increasing or all decreasing.
2. Any two adjacent levels differ by at least one and at most three.

We'll start by parsing the input. Reports can have different numbers of levels. To parse each report, we can use Zig's `std.ArrayList` which is similar to vector types in other languages (not to be confused with SIMD vector types). Since we're avoiding dynamic allocations unless it's necessary, we'll not use `std.ArrayList` and instead we'll store it in another way.

In the case of my input, the number of levels range between five and eight. Because the max number of levels is known, we can use regular arrays to store them with length prefixes. Each report will be parsed into an array with a capacity of at least N+1, where N is the max number of levels. Then, we'll store the count of the levels in the first element, and store the levels in the rest of the array.

E.g., for the report `[7, 6, 4, 2, 1]`, we'll store it like:

```text
┌────────┬───┬───┬───┬───┬───┬───┬───┬─────┐
│ Array: │ 5 │ 7 │ 6 │ 4 │ 2 │ 1 │ 0 │ ... │
└────────┴─┬─┴─┬─┴───┴───┴───┴─┬─┴─┬─┴─────┘
   length ─┘   └───────┬───────┘   └─ padding / unused bytes
                     levels
```

Here's the parsing function:

```zig
fn Day02(comptime length: usize) type {
    return struct {
        reports: [length][10]u8 = .{.{0} ** 10} ** length,

        const Self = @This();

        fn init(input: []const u8) !Self {
            var result = Self{};

            var i: usize = 0;
            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                var j: usize = 1;
                var inner_lexer = std.mem.tokenizeScalar(u8, line, ' ');
                while (inner_lexer.next()) |number| : (j += 1) {
                    result.reports[i][j] = try std.fmt.parseInt(u8, number, 10);
                }
                result.reports[i][0] = @intCast(j - 1);
            }

            return result;
        }
    };
}
```

Here I used 10 as the array size (because it looks better), but nine works as well. Next, we'll need a function to check whether a given report is safe following the two rules outline earlier.

```zig
fn is_valid_report(report: []const u8) bool {
    const is_increasing = report[1] < report[2];
    for (1..(report[0])) |i| {
        const larger = if (is_increasing) report[i + 1] else report[i];
        const lesser = if (is_increasing) report[i] else report[i + 1];

        const diff = @as(i16, larger) - lesser;
        if (diff < 1 or diff > 3) return false;
    }
    return true;
}
```

We determine if the levels should be in increasing or decreasing order by checking the first two elements. If it's increasing, the "right" level (`report[i + 1]`) must be larger than the "left" level (`report[i]`), and vice versa. Next, we calculate the difference between these two numbers. If the difference is negative, it means that the order is wrong so we return false. If the difference is not between one and three, it is also wrong and we return false.

With this, we can iterate over all the reports and count the number of safe reports to get the answer for part one.

```zig
fn part1(self: Self) u64 {
    var result: u64 = 0;
    for (self.reports) |report| {
        if (is_valid_report(&report)) result += 1;
    }
    return result;
}
```

A slight optimization here is to remove branch (the if check) inside the for loop by casting the return value into an integer, one for true and zero for false. The part one solution now becomes:

```zig
fn part1(self: Self) u64 {
    var result: u64 = 0;
    for (self.reports) |report| {
        result += @intFromBool(is_valid_report(&report));
    }
    return result;
}
```

## Part two

Part two introcuded the problem dampener, which slightly changed the requirement for a safe level. Now, if a single level in a report is removed results in a safe level, that report is also considered safe. 

There might be a better way, but for this day we can simply bruteforce all possible variations of each unsafe report with one item removed. In later days, bruteforcing is usually not feasible as some of the problems are designed to take a very long time to bruteforce.

Here's the code for part two:

```zig
fn part2(self: Self) u64 {
    var result: u64 = 0;
    for (self.reports) |report| {
        if (is_valid_report(&report)) {
            result += 1;
            continue;
        }
        for (1..(report[0] + 1)) |i| {
            var dampened = report;
            dampened[0] -= 1;
            @memcpy(dampened[i..9], report[(i + 1)..]);

            if (is_valid_report(&dampened)) {
                result += 1;
                break;
            }
        }
    }
    return result;
}
```

Here, to remove an item at index `i` from the array, we can move the rest of the items of the array from index `i + 1` to `i` using the `@memcpy` function. The length is set the the original length minus one.

## Benchmarks
