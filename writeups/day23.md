# Day 23: LAN Party

[Full solution](../src/days/day23.zig).

## Part one

On day 23 we're given list of computer connections, e.g.:

```
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
```

Where each line represents a connection between two computers. These connections aren't directional. We have an undirected graph of computers.

For part one, we have to find all sets of three computers, where each computer is connected to each other. A twist here is that we have to find all the sets where at least one computer starts with the letter `t`. First, let's parse the input:

```zig
fn Day23() type {
    return struct {
        graph: [26 * 26][16]u16 = .{.{0} ** 16} ** (26 * 26),
        allocator: std.mem.Allocator,

        const Self = @This();

        fn init(data: []const u8, allocator: std.mem.Allocator) Self {
            var result = Self{ .allocator = allocator };

            var i: usize = 0;
            var lexer = std.mem.tokenizeScalar(u8, data, '\n');
            while (lexer.next()) |line| : (i += 1) {
                const from = 26 * @as(u16, @intCast(line[0] - 'a')) + (line[1] - 'a');
                const to = 26 * @as(u16, @intCast(line[3] - 'a')) + (line[4] - 'a');

                result.graph[from][0] += 1;
                result.graph[from][result.graph[from][0]] = to;

                result.graph[to][0] += 1;
                result.graph[to][result.graph[to][0]] = from;
            }

            return result;
        }
    };
}
```

Here I parse the input into an adjacency list, which in this case is a `(26 * 26)x16` matrix. The computers have a sset format `[a-z][a-z]`, which makes the number of unique computers 26 * 26 = 676. I used a `[16]u16` to store the list instead of a `std.ArrayList` to avoid allocation. 16 is a safe number because **spoilers**: the maximum number of edges a node can have is 13. This isn't meant to be a general solution so it's okay to hardcode this number.

The computers are encoded as `u16` by encoding the characters according to their alphabetical order, e.g. `a = 0`, `b = 1`, and so on. This is effectively a base 26 encoding, so you can concatenate them by multiplying the first digit with 26 and adding the second digit. E.g., after encoding `aa` becomes 0 (0 * 26 + 0), `bc` becomes 28 (1 * 26 + 2), etc.

Now for the solution. I opted for the simplest solution:

1. For each node in the graph,
2. For each pair (node A and node B) of node in the graph's neighbors,
3. if node B is in node A's neighbors list, then we have a triangle.

Since this is a undirected graph, order doesn't matter so we have to keep track of the triangles in a set. To minimize computation, we can just search the nodes that start with `t`, which is stored in the indexes 494 (19 * 26) to 520 (19 * 26 + 26). (`t` is the 19th alphabet).

Here's the code for part one:

```zig
fn part1(self: Self) !u64 {
    var sets = std.AutoHashMap([3]u16, void).init(self.allocator);
    defer sets.deinit();

    const from = 26 * ('t' - 'a');
    const to = 26 * ('t' - 'a') + ('z' - 'a');

    for (from..(to + 1)) |first| {
        if (self.graph[first][0] == 0) continue;
        for (1..self.graph[first][0]) |i| {
            for (i + 1..self.graph[first][0] + 1) |j| {
                const second = self.graph[first][i];
                const third = self.graph[first][j];

                if (self.graph[second][0] == 0) continue;
                for (1..self.graph[second][0] + 1) |k| {
                    const item = self.graph[second][k];
                    if (item == third) {
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

## Part two

In part two, now we have to find the largest set of computers that are all connected to each other. I didn't know this when solving it during the day itself, but what we have to find is the [maximum clique](https://en.wikipedia.org/wiki/Clique_problem). A clique is when every node in a subgraph is connected to each other just like the triangle in part one. The maximum clique is the largest clique in the graph.

There's also the concept called a maximal clique, which is a clique that can't be extended anymore. A maximum clique is the largest maximal clique, but a maximal clique isn't necessarily the maximum.

The input for this day is specially crafted where each node has exactly 13 neighbors (edges). This makes the largest maximal clique we can get is 13. The sample input is also specially crafted where each node has exactly 4 neighbors and the maximum clique size is 4.

A "well-known" algorithm for finding all maximal cliques in a graph is the [Bron-Kerbosch algorithm](https://en.wikipedia.org/wiki/Bron%E2%80%93Kerbosch_algorithm). We can use this to get all the maximal cliques, and when we find a maximal clique of size 13, then we have found the answer. Here's the Bron-kerbosch algorithm implemented in Zig:

```zig
const BitSet = std.StaticBitSet(26 * 26);

const StackItem = struct {
    current: BitSet,
    candidate: BitSet,
    excluded: BitSet,
};

fn bron_kerbosch(self: Self, max_clique_size: usize) !BitSet {
    var stack = std.ArrayList(StackItem).init(self.allocator);
    defer stack.deinit();

    var first = StackItem{
        .current = BitSet.initEmpty(),
        .candidate = BitSet.initEmpty(),
        .excluded = BitSet.initEmpty(),
    };
    for (self.graph, 0..) |connections, i| {
        if (connections[0] > 0) first.candidate.set(i);
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

            var neighbors = BitSet.initEmpty();
            if (self.graph[vertex][0] > 0) {
                for (1..self.graph[vertex][0] + 1) |i| {
                    neighbors.set(self.graph[vertex][i]);
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

It's an iterative version of the pseudocode from the Bron-Kerbosch Wikipedia page. I used Zig's `std.StaticBitSet` to represent the set of nodes because it is more efficient than a `std.AutoHashmap(T, void)` for this particular use case. The items are represented as `u1` in arrays and it doesn't do any dynamic memory allocation.

After getting the maximum clique from this function, we just have to sort the nodes and convert them back to regular characters:

```zig
fn part2(self: Self, comptime max_clique_size: usize) ![]const u8 {
    var cliques = std.ArrayList(BitSet).init(self.allocator);
    defer cliques.deinit();

    var candidates = BitSet.initEmpty();
    for (self.graph, 0..) |connections, i| {
        if (connections[0] > 0) candidates.set(i);
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

**Disclaimer**: I have never heard of the Bron-Kerborsch algorithm before in my life. I found it after I gave up and started looking at other people's solution. Then I just translated the pseudocode from the Wikipedia page and called it a day. My original solution was a slow recursive solution. It's only just now that I converted it to iterative to speed it up.

## Benchmarks
