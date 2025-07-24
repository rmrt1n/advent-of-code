# Day 23: LAN Party

[Full solution](../src/days/day23.zig).

## Puzzle Input

Today's input is a network map which provides a list of **computer connections**:

```plaintext
kh-tc
qp-kh
de-cg
ka-co
yn-aq
qp-ub
cg-tb
vc-aq
tb-ka
wh-tc
yn-cg
kh-ub
```

Each line describes an undirected edge between two computers, so we'll parse the input into an adjacency list. Since nodes can have different numbers of neighbours, so we'll store their lengths in a separate array:

```zig
fn Day23() type {
    return struct {
        const Self = @This();

        const n_edges = 26 * 26;
        const list_capacity = 13;

        graph: [n_edges][list_capacity]u16 = undefined,
        lengths: [n_edges]u8 = .{0} ** n_edges,
        allocator: std.mem.Allocator,

        fn init(data: []const u8, allocator: std.mem.Allocator) Self {
            var result = Self{ .allocator = allocator };

            var i: usize = 0;
            var lexer = std.mem.tokenizeScalar(u8, data, '\n');
            while (lexer.next()) |line| : (i += 1) {
                const from = 26 * @as(u16, @intCast(line[0] - 'a')) + (line[1] - 'a');
                const to = 26 * @as(u16, @intCast(line[3] - 'a')) + (line[4] - 'a');

                var index = &result.lengths[from];
                result.graph[from][index.*] = to;
                index.* += 1;

                index = &result.lengths[to];
                result.graph[to][index.*] = from;
                index.* += 1;
            }

            return result;
        }
    };
}
```

Each computer is represented by a pair of lowercase characters. Instead of storing them directly as strings, we convert them into a unique integer ID using a 2-digit base-26 encoding (same trick as in previous days).

A computer is represented by a pair of lowercase character. Instead of storing them an array `[2]u8`, we'll convert these into an integer representation just like in the day 22. There are 26 possible characters, so we'll represent a computer as a 2-digit base 26 integer `u16`.

> [!NOTE]
> We'll get to why the list capacity is 13 in part two.

## Part One

We have to count the sets of **three inter-connected computers** that contains at least one computer that **starts with a `t`**. In graph terms, what we have to find are triangles, or more formally, [cliques](https://en.wikipedia.org/wiki/Clique_(graph_theory)) of size 3. A clique is a set of nodes where every node is connected to every other node.

We'll go with the simplest approach here. For every node, we'll check all pairs of its neighbours to see if they are also connected to each other. We'll use a set to keep track of the triangles. Since the graph is undirected, we'll sort the triangles first to make sure we don't have duplicates in the set.

At the end, we just have to return the number of items in the set. Here's the code:

```zig
fn part1(self: Self) !u64 {
    var sets = std.AutoHashMap([3]u16, void).init(self.allocator);
    defer sets.deinit();

    const from = 26 * ('t' - 'a');
    const to = 26 * ('t' - 'a') + ('z' - 'a');

    for (from..(to + 1)) |first| {
        if (self.lengths[first] == 0) continue;

        for (self.graph[first], 0..) |second, i| {
            if (self.lengths[second] == 0) continue;

            for (self.graph[first][i..]) |third| {
                if (self.lengths[third] == 0) continue;

                for (self.graph[second]) |neighbor| {
                    if (neighbor == third) {
                        var set = [3]u16{ @as(u16, @intCast(first)), second, third };
                        std.mem.sort(u16, &set, {}, std.sort.asc(u16));
                        try sets.put(set, {});
                    }
                }
            }
        }
    }

    return sets.count();
}
```

## Part Two

We have to find the **password** to the LAN party. The LAN party is the **maximum clique** in the graph, and the password is list of computers names in the clique sorted alphabetically.

The [maximum clique](https://en.wikipedia.org/wiki/Clique_problem) of a graph is the clique with the largest number of nodes. There's also the concept of a maximal clique, which is a clique that cannot be extended by an adjacent node. The maximum clique is also the largest maximal clique.

The input for this day is specially crafted where each node a degree of 13, i.e. every node has exactly 13 neighbours. This is why `list_capacity` is 13. This means the largest possible **maximal clique** size is 14. We're not guaranteed a maximal clique of size 14 (as we'll soon see), but it's the theoretical limit.

We can use a we a "well-known" algorithm for finding all maximal cliques in a graph called the [Bron-Kerbosch algorithm](https://en.wikipedia.org/wiki/Bron%E2%80%93Kerbosch_algorithm). I won't explain the algorithm because I'm bad at it, so here's the algorithm implemented iteratively in Zig:

```zig
const BitSet = std.StaticBitSet(n_edges);

fn bron_kerbosch(self: Self, max_clique_size: usize) !BitSet {
    const StackItem = struct { current: BitSet, candidate: BitSet, excluded: BitSet };
    var stack = std.ArrayList(StackItem).init(self.allocator);
    defer stack.deinit();

    var first = StackItem{
        .current = BitSet.initEmpty(),
        .candidate = BitSet.initEmpty(),
        .excluded = BitSet.initEmpty(),
    };
    for (self.lengths, 0..) |len, i| {
        if (len > 0) first.candidate.set(i);
    }
    try stack.append(first);

    return while (stack.items.len > 0) {
        var item = &stack.items[stack.items.len - 1];
        if (item.candidate.count() == 0 and item.excluded.count() == 0) {
            if (item.current.count() == max_clique_size) {
                break item.current;
            }
            _ = stack.pop();
            continue;
        }

        if (item.candidate.findFirstSet()) |vertex| {
            item.candidate.unset(vertex);

            const n_neighbors = self.lengths[vertex];

            var neighbors = BitSet.initEmpty();
            if (n_neighbors > 0) {
                for (self.graph[vertex]) |neighbor| {
                    neighbors.set(neighbor);
                }
            }

            var new_item = item.*;
            new_item.current.set(vertex);
            new_item.candidate.setIntersection(neighbors);
            new_item.excluded.setIntersection(neighbors);

            try stack.append(new_item);

            item.excluded.set(vertex);
        } else {
            _ = stack.pop();
        }
    } else unreachable;
}
```

We used Zig's `std.StaticBitSet` instead of `std.AutoHashMap(T,void)` because it's more efficient for this particular use case. It also doesn't do any dynamic memory allocation.

> [!NOTE]
> I cheated a bit here. Instead of finding all maximal cliques like a traditional Bron-Kerbosch, I pass a `max_clique_size` and return early when a clique of the same size is found.
>
> We can do this because the inputs are well structured enough that the maximum clique size is always the same as the node degree. The same logic applies to the sample inputs. Each node has a degree of 4 and the maximum clique size is also "coincidentally" 4.

All that’s left is to call `bron_kerbosch`, sort the result, and convert the nodes back to their character representations:

```zig
fn part2(self: Self, comptime max_clique_size: usize) ![]const u8 {
    var cliques = std.ArrayList(BitSet).init(self.allocator);
    defer cliques.deinit();

    var candidates = BitSet.initEmpty();
    for (self.lengths, 0..) |len, i| {
        if (len > 0) candidates.set(i);
    }

    const max_clique = try self.bron_kerbosch(max_clique_size);
    var nodes: [max_clique_size]u16 = undefined;

    var i: usize = 0;
    var iterator = max_clique.iterator(.{});
    while (iterator.next()) |entry| : (i += 1) {
        nodes[i] = @intCast(entry);
    }

    std.mem.sort(u16, &nodes, {}, std.sort.asc(u16));

    var result = try self.allocator.alloc(u8, max_clique_size * 2);
    for (nodes, 0..) |node, j| {
        result[j * 2] = @intCast(node / 26 + 'a');
        result[j * 2 + 1] = @intCast(node % 26 + 'a');
    }
    return result;
}
```

## Benchmark

All benchmarks were performed on an [Apple M3 Pro](https://en.wikipedia.org/wiki/Apple_M3) with times in microseconds (µs).

| Debug | ReleaseSafe | ReleaseFast | ReleaseSmall |
| ----- | ----------- | ----------- | ------------ |
|       |             |             |              |
