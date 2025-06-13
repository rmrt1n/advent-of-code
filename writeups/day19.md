# Day 19:

[Full solution](../src/days/day19.zig).

## Part one

We're given a list of patterns and designs:

```
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

The first part of the input is a comma-separated list of towel patterns where each character represents a color: white (w), blue (u), black (b), red (r), or green (g). The second part of the input is a list of designs to be constructed from the available patterns.

In part one, we have to count how many of the designs are possible to be created from the available patterns. This is combinatorics problem similar to day seven. For each design, we'll have to generate all permutations of the patterns and check if we can construct the design from it. Before that, let's parse the input:

```zig
fn Day19(n_patterns: usize, n_designs: usize) type {
    return struct {
        patterns: [n_patterns][]const u8 = undefined,
        designs: [n_designs][]const u8 = undefined,

        const Self = @This();

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

Here's the code to count the permutations for a design:

```zig
fn count_permutations(self: Self, design: []const u8) u64 {
    // Initialize an array that will fit the longest string in the data (60 in my case).
    var permutations = [_]u64{0} ** 64;

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

Here I went with a bottom-up dynamic programming (DP) approach. We create a DP array where `permutations[i]` stores the number of ways to build the first `i` characters of the design string. In python, the permutations array can be initialized using `[1] + [0] * len(design)`, but since the length of the design isn't known at compile time and I didn't want to dynamically allocate the array, I used a fixed size that can fit all of the designs by manually inspecting the input file.

The base case is the empty string, with only one way to build it (which is by not using any patterns). Then we loop from `1` to `len(design)`. For each substring, we go through all the patterns and check if the pattern is a suffix of the substring. If it is, we increment `permutations[i]` with the count in `permutations[i - pattern.len]`. Because we have already computed the number of permutations up to `permutations[i]`, we can reuse the count which makes this approach efficient. We're basically doing a lanternfish.

P.s. My first approach was a bit more crude where I store the frequency of substring in a hashmap. This worked but is incredibly inefficient because I was allocating new strings all the time. My original solution took around 2 seconds for both parts, which is way past my desired runtime limit. It was after I looked at other solutions that I realized you can just store the substring length as the key to the map instead of specific substrings.

Anyways, this is all we need for both parts, as they are just light wrappers over the `count_permutations` function. Here's part one:

```zig
fn part1(self: Self) u64 {
    var result: u64 = 0;
    for (self.designs) |design| {
        if (self.count_permutations(design) > 0) {
            result += 1;
        }
    }
    return result;
}
```

## Part two

Part two asked for the total number of ways to build each of the designs, i.e. sum of the number of permutations of each design. We did the heavy lifting already, so here's part two's code:

```zig
fn part2(self: Self) u64 {
    var result: u64 = 0;
    for (self.designs) |design| {
        result += self.count_permutations(design);
    }
    return result;
}
```

## Benchmarks
