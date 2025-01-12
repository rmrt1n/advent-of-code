# Day 05: Print Queue

[Full solution](../src/days/day05.zig).

## Part one

The first day when the difficulty spiked. The input consists of two parts, **page ordering rules** and **updates**. Page order rules indicate which page must come before another page in an update, with a frmat of `X|Y` where `X` must always come before `Y`. An update is a list of page numbers, like so:

```md
# First part is the page order rules (These comments don't exist in the actual input)
47|53
97|13
97|61
97|47
75|29
61|13
75|53
29|13
97|29
53|29
61|53
97|53
61|29
47|13
75|47
97|75
47|61
75|61
47|29
75|13
53|13

# Second part is the updates
75,47,61,53,29
97,61,53,29,13
75,29,13
75,97,47,61,53
61,13,29
97,13,75,29,47
```


The input is parsed into two parts, a `rules` lookup table and `updates`, the list of updates. Page numbers are limited to two digit integers, so we can represent this with a `[100][100]bool` type in Zig. E.g., for the rule `47|53`, it will be parsed into `rules[47][53] = true`. If we want to check if Y comes after X, we can do `if (rules[X][Y]) // ...`.

We'll use the same trick we used in day two to parse the updates, which have different lengths. My input has a max length of 23 page numbers in an update, so any number above that is fine to use. Here's the parsing code:

```zig
fn Day05(length: usize) type {
    return struct {
        rules: [100][100]bool = .{.{false} ** 100} ** 100,
        updates: [length][30]u8 = undefined,

        const Self = @This();

        fn init(input: []const u8) !Self {
            var result = Self{};

            var lexer = std.mem.splitScalar(u8, input, '\n');
            while (lexer.next()) |line| {
                if (line.len == 0) break; // Last newline
                const before = try std.fmt.parseInt(u8, line[0..2], 10);
                const after = try std.fmt.parseInt(u8, line[3..], 10);
                result.rules[before][after] = true;
            }

            var i: usize = 0;
            while (lexer.next()) |line| : (i += 1) {
                if (line.len == 0) break; // Last newline
                var j: usize = 1;
                var inner_lexer = std.mem.tokenizeScalar(u8, line, ',');
                while (inner_lexer.next()) |number| : (j += 1) {
                    result.updates[i][j] = try std.fmt.parseInt(u8, number, 10);
                }
                result.updates[i][0] = @intCast(j - 1);
            }

            return result;
        }
    };
}
```

For part one we have to find all of the **correctly-ordered updates** following the page rules, e.g. a 47 must never go after a 53. We can do this by checking if every page in an update follows the rule. Then, we have to get the **middle page number** and add them all up to get the answer to part one. We can get the middle page by getting the item at index N/2 where N is the length of the update.

My original solution uses a more bruteforce-ish way and is slower and more complicated compared to the one in this writeup. The way I checked if an update has a correct order looked like:

```zig
fn is_correct_update(self: Self, update: []u8) bool {
    for (update, 0..) |before, i| {
        for (updage[(i + 1)..]) |after| {
            if (!self.rules[before][after]) return false;
        }
    }
    return true;
}
```

This works but doesn't help much in part two. After reading other people's solution I learned this day was a sorting problem. The page order rules forms a [directed acyclic graph (DAG)](https://en.wikipedia.org/wiki/Directed_acyclic_graph), which can be sorted in a [topological order](https://en.wikipedia.org/wiki/Topological_ordering). For example, given the two rules `47|53` and `75|47`, the topological ordering of these becomes `75 -> 47 -> 53`.

We can replace the `is_correct_update` with the `std.sort.isSorted` from the Zig standard library that checks if a slice is sorted according to a `lessThan` function. The `lessThan` function is also used for sorting. We can use the `rules` lookup table as the `lessThan` function:

```zig
fn sort_topological(self: *const Self, a: u8, b: u8) bool {
    return self.rules[a][b];
}
```

If the update is sorted correctly, it means that every item in it follows the page order rules. Turns out this function is all we need to solve both parts. Here's the solution to part one:

```zig
fn part1(self: Self) u64 {
    var result: u64 = 0;
    for (self.updates) |update| {
        if (std.sort.isSorted(u8, update[1..(update[0] + 1)], &self, sort_topological)) {
            result += update[update[0] / 2 + 1];
        }
    }
    return result;
}
```

Because `update` has extra bytes, we have to slice it to get just the items we need by checking `update[0]`, which contains the length of the used page numbers.

## Part two

In part two, instead of the correctly-ordered updates, we have to find all of the **incorrectly-order udpates**, sort it, and sum the middle numbers. Since we already have a sort function, implementing part two's solution becomes much easier.

```zig
fn part2(self: Self) u64 {
    var result: u64 = 0;
    for (self.updates) |update| {
        if (!std.sort.isSorted(u8, update[1..(update[0] + 1)], &self, sort_topological)) {
            var mutable = update;
            std.mem.sort(u8, mutable[1..(mutable[0] + 1)], &self, sort_topological);
            result += mutable[mutable[0] / 2 + 1];
        }
    }
    return result;
}
```

## Benchmarks
