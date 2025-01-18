const std = @import("std");

fn Day09(length: usize) type {
    return struct {
        disk_map: [length]u8 = undefined,
        allocator: std.mem.Allocator,

        const Self = @This();

        fn init(input: []const u8, allocator: std.mem.Allocator) Self {
            var result = Self{ .allocator = allocator };

            const trimmed = std.mem.trim(u8, input, "\n");
            for (trimmed, 0..) |c, i| result.disk_map[i] = c - '0';

            return result;
        }

        fn part1(self: Self) u64 {
            var result: u64 = 0;
            var mutable_disk_map = self.disk_map;

            var left: usize = 0;
            var right: usize = length - 1;
            var index = left;
            while (left <= right) : (left += 1) {
                var size = mutable_disk_map[left];
                if (left % 2 == 0) {
                    result += file_checksum(left / 2, size, index);
                    // result += left / 2 * (size * (2 * index + size - 1) / 2);
                } else {
                    var right_size = mutable_disk_map[right];
                    while (size >= right_size) : (right_size = mutable_disk_map[right]) {
                        result += file_checksum(right / 2, right_size, index);
                        size -= right_size;
                        index += right_size;
                        right -= 2;
                    }

                    result += file_checksum(right / 2, size, index);
                    mutable_disk_map[right] -= size;
                }
                index += size;
            }
            return result;
        }

        fn part2(self: Self) !u64 {
            // This is a 100x time speedup than using a regular ArrayList.
            var free_heaps: [10]std.PriorityQueue(usize, void, compare) = undefined;
            for (1..10) |i| {
                free_heaps[i] = std.PriorityQueue(usize, void, compare).init(self.allocator, {});
            }
            defer for (free_heaps[1..]) |heap| heap.deinit();

            var file_indexes: [10_000]u32 = undefined;
            var file_sizes: [10_000]u8 = undefined;

            var disk_index: u32 = 0;
            var i: usize = 0;
            while (i < self.disk_map.len - 1) : (i += 2) {
                const file_size = self.disk_map[i];
                file_indexes[i / 2] = @intCast(disk_index);
                file_sizes[i / 2] = file_size;
                disk_index += file_size;

                const free_size = self.disk_map[i + 1];
                if (free_size > 0) try free_heaps[free_size].add(disk_index);
                disk_index += free_size;
            }
            file_indexes[i / 2] = disk_index;
            file_sizes[i / 2] = self.disk_map[i];

            const file_count = i / 2;
            for (0..(file_count + 1)) |j| {
                const file_index = file_indexes[file_count - j];
                const file_size = file_sizes[file_count - j];

                // Get the leftmost free index that fits the current file.
                var leftmost_free_index = file_index;
                var leftmost_free_size: usize = 0;
                for (file_size..10) |size| {
                    if (free_heaps[size].peek()) |free_index| {
                        if (free_index < leftmost_free_index) {
                            leftmost_free_index = @intCast(free_index);
                            leftmost_free_size = size;
                        }
                    }
                }

                // Move the file into the free space. Update the free space size.
                if (leftmost_free_index < file_index) {
                    const new_size = leftmost_free_size - file_size;
                    const free_index = free_heaps[leftmost_free_size].remove();
                    if (new_size > 0) try free_heaps[new_size].add(free_index + file_size);
                    file_indexes[file_count - j] = @intCast(free_index);
                }
            }

            var result: u64 = 0;
            for (0..(file_count + 1)) |id| {
                result += file_checksum(id, file_sizes[id], file_indexes[id]);
            }
            return result;
        }

        fn file_checksum(id: usize, size: usize, start: usize) u64 {
            return id * size * (2 * start + size - 1) / 2;
        }

        fn compare(_: void, a: usize, b: usize) std.math.Order {
            return std.math.order(a, b);
        }
    };
}

pub const title = "Day 09: Disk Fragmenter";

pub fn run(allocator: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    const input = @embedFile("./data/day09.txt");
    const puzzle = Day09(19_999).init(input, allocator);
    const time0 = timer.read();

    const result1 = puzzle.part1();
    const time1 = timer.read();

    const result2 = try puzzle.part2();
    const time2 = timer.read();

    if (is_run) {
        std.debug.print("Part 1: {d}\nPart 2: {d}\n", .{ result1, result2 });
    }

    return .{ time0, time1, time2 };
}

const sample_input = "2333133121414131402";

test "day 09 part 1 sample 1" {
    const puzzle = Day09(19).init(sample_input, std.testing.allocator);
    const result = puzzle.part1();
    try std.testing.expectEqual(1928, result);
}

test "day 09 part 2 sample 1" {
    const puzzle = Day09(19).init(sample_input, std.testing.allocator);
    const result = try puzzle.part2();
    try std.testing.expectEqual(2858, result);
}
