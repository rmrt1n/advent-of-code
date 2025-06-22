const std = @import("std");

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
    };
}

pub const title = "Day 23: LAN Party";

pub fn run(allocator: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    const input = @embedFile("./data/day23.txt");
    var puzzle = Day23().init(input, allocator);
    const time0 = timer.read();

    const result1 = try puzzle.part1();
    const time1 = timer.read();

    const result2 = try puzzle.part2(13);
    const time2 = timer.read();

    if (is_run) {
        std.debug.print("Part 1: {d}\nPart 2: {d}\n", .{ result1, result2 });
    }

    return .{ time0, time1, time2 };
}

const sample_input =
    \\kh-tc
    \\qp-kh
    \\de-cg
    \\ka-co
    \\yn-aq
    \\qp-ub
    \\cg-tb
    \\vc-aq
    \\tb-ka
    \\wh-tc
    \\yn-cg
    \\kh-ub
    \\ta-co
    \\de-co
    \\tc-td
    \\tb-wq
    \\wh-td
    \\ta-ka
    \\td-qp
    \\aq-cg
    \\wq-ub
    \\ub-vc
    \\de-ta
    \\wq-aq
    \\wq-vc
    \\wh-yn
    \\ka-de
    \\kh-ta
    \\co-tc
    \\wh-qp
    \\tb-vc
    \\td-yn
;

test "day 23 part 1 sample 1" {
    var puzzle = Day23().init(sample_input, std.testing.allocator);
    const result = try puzzle.part1();
    try std.testing.expectEqual(7, result);
}

test "day 23 part 2 sample 1" {
    var puzzle = Day23().init(sample_input, std.heap.page_allocator);
    const result = try puzzle.part2(4);
    defer puzzle.allocator.free(result);
    try std.testing.expectEqualSlices(u8, "codekata", result);
}
