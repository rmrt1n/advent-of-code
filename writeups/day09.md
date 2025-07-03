# Day 09: Disk Fragmenter

[Full solution](../src/days/day09.zig).

## Puzzle Input

Today's input is a computer's **disk map**:

```plaintext
2333133121414131402
```

Each character represents alternating segments of **file spaces** and **free space**. The numeric value of the character is the size of space. Files also have a **file ID** which is their order in the disk map. This is a dense format; when expanded into its disk representation we'll get:

```plaintext
00...111...2...333.44.5555.6666.777.888899
```

We'll convert the character digits into its numeric value as we parse it:

```zig
fn Day09(length: usize) type {
    return struct {
        const Self = @This();

        disk_map: [length]u8 = undefined,
        allocator: std.mem.Allocator,

        fn init(input: []const u8, allocator: std.mem.Allocator) Self {
            var result = Self{ .allocator = allocator };

            const trimmed = std.mem.trim(u8, input, "\n");
            for (trimmed, 0..) |c, i| result.disk_map[i] = c - '0';

            return result;
        }
    };
}
```

## Part One

We need to compute the **filesystem checksum** after compressing the disk. Compression works by moving files one block at a time from the end of the disk to the leftmost free spaces. The filesystem checksum is the sum of multiplying each file block's position (its index in the array) with its file ID.

For brevity, I'll refer "multiplying a file block's position by its ID" as the file checksum. The filesystem checksum is the sum of all file checksums.

We can compress the disk and calculate the filesystem checksum in a single pass by using the [two-pointers technique](https://neetcode.io/courses/advanced-algorithms/3). We'll iterate through the disk map from the left:

- If we find a file segment, we'll calculate its file checksum and add it to the total.
- If we find a free segment, we'll move the blocks from the right until we have filled the remaining free space. Then, we calculate the file checksum for the file blocks we just moved.

Here is the implementation:

```zig
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
```

And here's the definition of `file_checksum`:

```zig
fn file_checksum(id: usize, size: usize, start: usize) u64 {
    return id * size * (2 * start + size - 1) / 2;
}
```

This function calculates a file segment's checksum given its file ID, the segment size, and the position (the index) of the first block in the segment. The checksum is the file ID multiplied by the sum of its block's indexes.

> [!TIP]
> The block's indexes is the arithmetic series $a + ar + ar^2 + ... + ar^n$. We can get its sum by using this formula:
>
> $$S_n = n \frac{a_1 + a_n}{2}$$
> 
> Where:
> - $a$ is the first term (the file segment's first block's index).
> - $n$ is the number of terms (the file segment size).

## Part Two

We still have to calculate the filesystem checksum, but with a slightly different compression algorithm. Instead of moving files one block at a time, we have to move **whole files** instead.

To do the compression efficiently, we'll keep a list of the free and the file segments. Then, we'll iterate through the file segments in reverse and try to move each file to the leftmost free segment that fits it. The whole function is a bit long, so I'll explain it in sections.

First, we initialise ten free heaps to store the free segments, one for each possible free segment size 0-9. We're not going to initialise the zero-sized heap as it's not used. We'll use Zig's `std.PriorityQueue` as our [min heap](https://en.wikipedia.org/wiki/Heap_(data_structure)) data structure:

```zig
fn part2(self: Self) !u64 {
    const free_heap_capacity = 10;
    var free_heaps: [10]std.PriorityQueue(usize, void, compare) = undefined;
    for (1..free_heap_capacity) |i| {
        free_heaps[i] = std.PriorityQueue(usize, void, compare).init(self.allocator, {});
    }
    defer for (free_heaps[1..]) |heap| heap.deinit();
    
    // ...
}
```

The reason we use a min heap is because we want the free segments to always be ordered by its index in the disk map. When we get the top item from the heap, it should be the leftmost free segment of its size. Here's the `compare` function that orders the node by its index in the disk map:

```zig
fn compare(_: void, a: usize, b: usize) std.math.Order {
    return std.math.order(a, b);
}
```

Next, we'll initialise the files list and store each file segment's starting index and size:

```zig
fn part2(self: Self) !u64 {
    // ...
    
    const file_count = try std.math.divCeil(comptime_int, self.disk_map.len, 2);
    var file_indexes: [file_count]u32 = undefined;
    var file_sizes: [file_count]u8 = undefined;

    var disk_index: u32 = 0;
    for (0..file_count) |i| {
        const file_size = self.disk_map[i * 2];
        const free_size = self.disk_map[i * 2 + 1];

        file_indexes[i] = disk_index;
        file_sizes[i] = file_size;
        disk_index += file_size;

        if (free_size > 0) try free_heaps[free_size].add(disk_index);
        disk_index += free_size;
    }
    
    // ...
}
```

> [!NOTE]
> We apply the ceiling function `std.math.divCeil` to ensure we get the last file when the disk map length is odd. By default, regular division rounds the result towards zero.

Next, we iterate through the files starting from the end. For each file, find the leftmost free segment that fits it. If we find one, we "move" the file to the free segment. If there is remaining free space, we add it to the free heap of its size:

```zig
fn part2(self: Self) !u64 {
    // ...
    
    for (0..file_count) |i| {
        const file_index = file_indexes[file_count - 1 - i];
        const file_size = file_sizes[file_count - 1 - i];

        // Get the leftmost free index that fits the current file.
        var leftmost_free_index = file_index;
        var leftmost_free_size: usize = 0;
        for (file_size..free_heap_capacity) |size| {
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
            file_indexes[file_count - 1 - i] = @intCast(free_index);
        }
    }
    
    // ...
}
```

Finally, we calculate the filesystem checksum using the updated file list:

```zig
fn part2(self: Self) !u64 {
    // ...
    
    var result: u64 = 0;
    for (file_sizes, file_indexes, 0..) |size, index, id| {
        result += file_checksum(id, size, index);
    }
    return result;
}
```

Here's the full `part2` function for your reference:

```zig
fn part2(self: Self) !u64 {
    // This is a 100x time speedup than using a regular ArrayList.
    const free_heap_capacity = 10;
    var free_heaps: [10]std.PriorityQueue(usize, void, compare) = undefined;
    for (1..free_heap_capacity) |i| {
        free_heaps[i] = std.PriorityQueue(usize, void, compare).init(self.allocator, {});
    }
    defer for (free_heaps[1..]) |heap| heap.deinit();

    const file_count = try std.math.divCeil(comptime_int, self.disk_map.len, 2);
    var file_indexes: [file_count]u32 = undefined;
    var file_sizes: [file_count]u8 = undefined;

    var disk_index: u32 = 0;
    for (0..file_count) |i| {
        const file_size = self.disk_map[i * 2];
        const free_size = self.disk_map[i * 2 + 1];

        file_indexes[i] = disk_index;
        file_sizes[i] = file_size;
        disk_index += file_size;

        if (free_size > 0) try free_heaps[free_size].add(disk_index);
        disk_index += free_size;
    }

    for (0..file_count) |i| {
        const file_index = file_indexes[file_count - 1 - i];
        const file_size = file_sizes[file_count - 1 - i];

        // Get the leftmost free index that fits the current file.
        var leftmost_free_index = file_index;
        var leftmost_free_size: usize = 0;
        for (file_size..free_heap_capacity) |size| {
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
            file_indexes[file_count - 1 - i] = @intCast(free_index);
        }
    }

    var result: u64 = 0;
    for (file_sizes, file_indexes, 0..) |size, index, id| {
        result += file_checksum(id, size, index);
    }
    return result;
}
```

## Benchmark

All benchmarks were performed on an [Apple M3 Pro](https://en.wikipedia.org/wiki/Apple_M3) with times in microseconds (µs).

| Debug | ReleaseSafe | ReleaseFast | ReleaseSmall |
| ----- | ----------- | ----------- | ------------ |
|       |             |             |              |
