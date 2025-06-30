# Day 02: Red-Nosed Reports

[Full solution](../src/days/day02.zig).

## Puzzle Input

Today's input is a list of **reports**:

```plaintext
7 6 4 2 1
1 2 7 8 9
9 7 6 2 1
1 3 2 4 5
8 6 4 4 1
1 3 6 7 9
```

Each line represents a report and a report is a list of numbers called **levels**. Unlike the example above, the actual input reports can have different numbers of levels.

We'll parse the reports into a 2D array and store the lengths in a separate array of the same length. The backing array needs enough capacity to hold the longest report in the input. In my case, the longest report is eight so that is also my report capacity.

```zig
fn Day02(comptime length: usize) type {
    return struct {
        const Self = @This();

        const report_capacity = 8;

        reports: [length][report_capacity]u8 = undefined,
        lengths: [length]u8 = undefined,

        fn init(input: []const u8) !Self {
            var result = Self{};

            var i: usize = 0;
            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                var j: u8 = 0;
                var inner_lexer = std.mem.tokenizeScalar(u8, line, ' ');
                while (inner_lexer.next()) |number| : (j += 1) {
                    result.reports[i][j] = try std.fmt.parseInt(u8, number, 10);
                }
                result.lengths[i] = j;
            }

            return result;
        }

    };
}
```

> [!NOTE]
> Your `report_capacity` might be different than mine. Please adjust this according to your input file.

## Part One

For part one, we have to count the number of **safe reports**. A report is considered safe if both of these conditions are true:

1. The levels are either strictly increasing or strictly decreasing.
2. Any two adjacent levels differ by at least one and at most three.

First, we'll create a function to check whether a report is safe based on the above rules:

```zig
fn is_valid_report(report: []const u8) bool {
    const is_increasing = report[0] < report[1];

    for (0..(report.len - 1)) |i| {
        const larger = if (is_increasing) report[i + 1] else report[i];
        const lesser = if (is_increasing) report[i] else report[i + 1];

        const difference = @as(i16, larger) - lesser;
        if (difference < 1 or difference > 3) return false;
    }

    return true;
}
```

This function uses a sliding window to check pairs of adjacent levels. First it determines the direction (increasing or decreasing) based on the first two elements. Then, it checks if every adjacent level follows the same direction and that the difference is within the allowed range. If any pair violates this rule, we have found an unsafe report.

Now we just have to iterate over all reports and count the safe levels:

```zig
fn part1(self: Self) u64 {
    var result: u64 = 0;
    for (self.reports, self.lengths) |report, len| {
        result += @intFromBool(is_valid_report(report[0..len]));
    }
    return result;
}
```

> [!NOTE]
> Unlike C, Zig doesn't automatically convert `true` to `1` and `false` to `0`. We have to cast it to an integer using `@intFromBool`.

## Part Two

Part two introduced the **problem dampener**, which slightly changed the requirement for a safe level. Now, a report is considered safe if it's either already safe, or if removing a single level from it would result in a safe report.

There might be a more elegant way to solve this, but the simplest solution here is to brute force it. For each unsafe report, try removing every level and check if the new report is safe.

```zig
fn part2(self: Self) u64 {
    var result: u64 = 0;
    for (self.reports, self.lengths) |report, len| {
        if (is_valid_report(report[0..len])) {
            result += 1;
            continue;
        }

        var dampened = report;
        for (0..len) |i| {
            @memcpy(dampened[(len - 1 - i)..(len - 1)], report[(len - i)..len]);
            if (is_valid_report(dampened[0..(len - 1)])) {
                result += 1;
                break;
            }
        }
    }
    return result;
}
```

For the brute force, we start by copying the original report from `self.reports[i]`. Then we remove the item at index `i` by copying the rest of the slice starting from index `i+1` using `@memcpy`. This effectively removes the item at index `i`. The reason we do this from the end is to avoid overwriting data we need for future iterations.

Here's an example to help you visualise:

```plaintext
Original: [1, 2, 3, 4, 5, 6]
Remove 6: [1, 2, 3, 4, 5, 6]
Remove 5: [1, 2, 3, 4, 6, 6]
Remove 4: [1, 2, 3, 5, 6, 6]
Remove 3: [1, 2, 4, 5, 6, 6]
Remove 2: [1, 3, 4, 5, 6, 6]
Remove 1: [2, 3, 4, 5, 6, 6]
```

We slice the array before passing it to `is_valid_report`, so it doesn't matter if there are extra items in the array.

## Benchmarks

All benchmarks were performed on an [Apple M3 Pro](https://en.wikipedia.org/wiki/Apple_M3) with times in microseconds (µs).

| Debug | ReleaseSafe | ReleaseFast | ReleaseSmall |
| ----- | ----------- | ----------- | ------------ |
|       |             |             |              |
