# Day 19: Linen Layout

[Full solution](../src/days/day19.zig).

## Puzzle Input

Today's input is a list of **towel patterns** and **designs** to create:

```plaintext
r, wr, b, g, bwu, rb, gb, br

brwrr
bggr
gbbr
rrbgbr
ubwu
bwurrg
brgr
bbrgwb
```

The first line is a list of towel patterns separated by commas. Each letter in the pattern is one of these colours: white (`w`), blue (`u`), black (`b`), red (`r`), or green (`g`). The second part is a list of designs to be assembled using the available towel patterns.

We'll parse these into arrays of strings:

```zig
fn Day19(n_patterns: usize, n_designs: usize) type {
    return struct {
        const Self = @This();

        patterns: [n_patterns][]const u8 = undefined,
        designs: [n_designs][]const u8 = undefined,

        fn init(data: []const u8) Self {
            var result = Self{};
            var lexer = std.mem.tokenizeScalar(u8, data, '\n');

            var i: usize = 0;
            var pattern_lexer = std.mem.tokenizeAny(u8, lexer.next().?, ", ");
            while (pattern_lexer.next()) |pattern| : (i += 1) {
                result.patterns[i] = pattern;
            }

            i = 0;
            while (lexer.next()) |design| : (i += 1) {
                result.designs[i] = design;
            }

            return result;
        }
    };
}
```

## Part One

We need to count the number of **possible designs**. A design is considered possible is if it can be created by concatenating one or more patterns in order. The patterns can be reused.

This is combinatorics problem like in day 7. For each design, we'll count the number of different ways to construct it. In other words, we're counting the number of pattern permutations. If the permutation count is 0, the design is impossible to create.

We'll create a function to count the permutations for a design:

```zig
fn count_permutations(self: Self, design: []const u8) u64 {
    // Should fit empty string (0 length) -> longest string (60 in my input).
    const longest_string = 60 + 1;
    var permutations = [_]u64{0} ** longest_string;

    permutations[0] = 1;

    for (1..(design.len + 1)) |i| {
        for (self.patterns) |pattern| {
            if (pattern.len > i) continue;
            if (std.mem.eql(u8, pattern, design[(i - pattern.len)..i])) {
                permutations[i] += permutations[i - pattern.len];
            }
        }
    }

    return permutations[design.len];
}
```

This functions uses a bottom-up, [dynamic programming (DP)](https://en.wikipedia.org/wiki/Dynamic_programming) approach to count the permutations. The DP array `permutations` stores the counts of each unique **substring length**. We count the frequency of substring lengths instead of the individual substrings because it's more efficient, i.e. we don't have to allocate memory for the strings. We're basically doing a lanternfish here.

For part one, we just have to call `count_permutations` and increment the result every time the the permutation count is greater than 0:

```zig
fn part1(self: Self) u64 {
    var result: u64 = 0;
    for (self.designs) |design| {
        result += @intFromBool(self.count_permutations(design) > 0);
    }
    return result;
}
```


## Part Two

We have to find the **sum of ways to create all possible designs**.

We already have a `count_permutations` function, so all we need to do is to go through the designs and sum up the results:

```zig
fn part2(self: Self) u64 {
    var result: u64 = 0;
    for (self.designs) |design| {
        result += self.count_permutations(design);
    }
    return result;
}
```

Another surprisingly easy part two!

## Benchmark

All benchmarks were performed on an [Apple M3 Pro](https://en.wikipedia.org/wiki/Apple_M3) with times in microseconds (µs).

| Part/Optimise | Debug (µs)    | ReleaseSafe (µs) | ReleaseFast (µs) | ReleaseSmall (µs) |
|-------------- | ------------: | ---------------: | ---------------: | ----------------: |
| Parsing       | 127.0         | 11.4             | 10.7             | 21.8              |
| Part 1        | 207,814.8     | 12,983.8         | 11,890.8         | 25,477.8          |
| Part 2        | 207,684.8     | 12,979.9         | 11,908.7         | 25,483.3          |
| **Total**     | **415,626.6** | **25,975.1**     | **23,810.2**     | **50,982.9**      |
