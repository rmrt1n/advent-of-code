const std = @import("std");

fn Day23() type {
    return struct {
        const Self = @This();
        const BitSet = std.StaticBitSet(n_edges);

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
