# Day 05: Print Queue

[Full solution](../src/days/day05.zig).

## Puzzle Input

Today's input is a **sleigh launch safety manual**:

```plaintext
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

75,47,61,53,29
97,61,53,29,13
75,29,13
75,97,47,61,53
61,13,29
97,13,75,29,47
```

It's divided into two sections. The first section is the **page ordering rules** which specify the order pages must follow in the updates, e.g. the rule `47|53` states that `47` must always appear before `53`. The second section is the **updates**. An update is a list of page numbers separated by commas.

The page order rules is essentially a [directed acyclic graph (DAG)](https://en.wikipedia.org/wiki/Directed_acyclic_graph), so we'll parse it into an [adjacency matrix](https://en.wikipedia.org/wiki/Adjacency_matrix). This allows for constant-time lookups of the page order rules. We'll parse the updates into a 2D array with their lengths in a separate array (just like in day two):

```zig
fn Day05(length: usize) type {
    return struct {
        const Self = @This();

        const rule_capacity = 100;
        const update_capacity = 23;

        rules: [rule_capacity][rule_capacity]bool = .{.{false} ** rule_capacity} ** rule_capacity,
        updates: [length][update_capacity]u8 = undefined,
        lengths: [length]u8 = undefined,

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

                var j: u8 = 0;
                var inner_lexer = std.mem.tokenizeScalar(u8, line, ',');
                while (inner_lexer.next()) |number| : (j += 1) {
                    result.updates[i][j] = try std.fmt.parseInt(u8, number, 10);
                }
                result.lengths[i] = j;
            }

            return result;
        }
    };
}
```

Rule capacity is set to 100 because the largest page number is 99, which is the index for the 100th item in an array.

> [!NOTE]
> In my input, the longest update is 23, hence why my `update_capacity` is 23. This value might be different depending on your input.

## Part One

We need to find all of the **correctly-ordered updates** and get the sum of the middle page number of each one.

An update is considered correctly ordered if all of the pages in it follow the page ordering rule. If a page is in the correct order, it means that there must be a rule saying this page comes after the page before it. We only need a single pass over an update to check this. Here's the code:

```zig
fn part1(self: Self) u64 {
    var result: u64 = 0;
    for (self.updates, self.lengths) |update, len| {
        const is_sorted = for (1..len) |i| {
            if (!self.rules[update[i - 1]][update[i]]) break false;
        } else true;
        if (is_sorted) result += update[len / 2];
    }
    return result;
}
```

What we're really checking here is whether each update is sorted in [topological order](https://en.wikipedia.org/wiki/Topological_ordering). The more formal definition of topological ordering is a way to arrange the nodes (vertices) in a DAG so that every directed edge `u -> v`, `u` always comes before `v` in the order.

A cleaner way to do this is by using the helper functions from `std.sort`:

```zig
fn part1(self: Self) u64 {
    var result: u64 = 0;
    for (self.updates, self.lengths) |update, len| {
        if (std.sort.isSorted(u8, update[0..len], &self, sort_topological)) {
            result += update[len / 2];
        }
    }
    return result;
}

fn sort_topological(self: *const Self, a: u8, b: u8) bool {
    return self.rules[a][b];
}
```

## Part Two

Now, we need to find all of the **incorrectly-ordered updates**, fix them using the page ordering rules, and sum their middle numbers.

We know that an update is correctly-ordered if it is sorted topologically. So to fix a incorrectly-ordered update, we just have to sort it topologically. We did most of the hard work in part one, so the code for part two is straightforward:

```zig
fn part2(self: Self) u64 {
    var result: u64 = 0;
    for (self.updates, self.lengths) |update, len| {
        if (!std.sort.isSorted(u8, update[0..len], &self, sort_topological)) {
            var mutable = update;
            std.mem.sort(u8, mutable[0..len], &self, sort_topological);
            result += mutable[len / 2];
        }
    }
    return result;
}
```

> [!NOTE]
> We make a mutable copy `mutable` because `update` is read-only. It's not shown here, but the `Day05` type is initialised to a constant, so we can't modify its fields directly. Since `std.mem.sort` sorts a slice in-place, we'll need a mutable copy to modify.

## Benchmark

All benchmarks were performed on an [Apple M3 Pro](https://en.wikipedia.org/wiki/Apple_M3) with times in microseconds (µs).

| Debug | ReleaseSafe | ReleaseFast | ReleaseSmall |
| ----- | ----------- | ----------- | ------------ |
|       |             |             |              |
