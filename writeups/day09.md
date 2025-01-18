# Day 09: Disk Fragmenter

[Full solution](../src/days/day09.zig).

## Part one

This time, we're given a **disk map** that represents the layout of a disk. The even indexes of the disk map hold the sizes of the **files** while the odd indexes hold the sizes of the **free space**. Here's an example:

```
2333133121414131402
```

When expanded into a disk representation, the above disk map looks like:

```
00...111...2...333.44.5555.6666.777.888899
```

Each number is the **file ID** (based on the order of the files) and the dots are the free spaces.  The task for day nine is to [defragment](https://en.wikipedia.org/wiki/Defragmentation) this disk by reorganizing the files.

Day nine is a cool puzzle that can be solved in many different ways. My original solution was involved creating the disk itself and moving the files, which I then refactored because it was too slow. My new solution (the one in this writeup) doesn't involve creating the disk representation, so the parsing code for this day looks like:

```zig
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
    };
}
```

We'll parse the disk map into their integer representation and also bring in an allocator which we'll need later for part two.

For part one, we have to defragment the disk one file block at a time from the end of the disk into the leftmost free blocks. Here is the algorithm visualized (ran on the sample input above) with each iteration in a separate line:

```
00...111...2...333.44.5555.6666.777.888899
009..111...2...333.44.5555.6666.777.88889.
0099.111...2...333.44.5555.6666.777.8888..
00998111...2...333.44.5555.6666.777.888...
009981118..2...333.44.5555.6666.777.88....
0099811188.2...333.44.5555.6666.777.8.....
009981118882...333.44.5555.6666.777.......
0099811188827..333.44.5555.6666.77........
00998111888277.333.44.5555.6666.7.........
009981118882777333.44.5555.6666...........
009981118882777333644.5555.666............
00998111888277733364465555.66.............
0099811188827773336446555566..............
```

Once the disk is defragmented, we have to calculate the **filesystem checksum**, which is the sum of each file block's index multiplied by its file ID. I'll use the same word "checksum" to refer to the sum of each file block index multiplied by its ID, so that the filesystem checksum is the sum of all the file checksums.


To solve this without creating the disk, we'll use [two pointers](https://neetcode.io/courses/advanced-algorithms/3) to keep track the leftmost and rightmost files. We'll iterate over the disk map, and:

1. If we encounter a file, we'll calculate the file's checksum and add it to the total.
2. If we encounter a free space, we'll keep subtracting from the rightmost file until we fill up all of the free space and also calculate the checksum.

Here's the code which hopefully is easier to understand than the above explanation:

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

We're keeping track of the file block index with the `index` variable, which is incremented by the file size each iteration. To get the file ID, we'll divide the left/right pointer by two. This works because files are always separated by free space. See the visualization below:

```
Disk map : [2, 3, 3, 3, 1, 3, 3, 1, 2, 1, ...]
Indexes  : [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, ...]
File IDs : [0, ., 1, ., 2, ., 3, ., 4, ., ...]
```

And here's the definition of the `file_checksum` function:

```zig
fn file_checksum(id: usize, size: usize, start: usize) u64 {
    return id * size * (2 * start + size - 1) / 2;
}
```

Given a file's ID, size, and the index of its first block, we can get its checksum by multiplying its ID with the sum of all of its indexes. Here's a breakdown with an example using the file with the ID 3 from the sample input above:

1. $checksum = (3 · 6) + (3 · 7) + (3 · 8)$
2. $checksum = 3 · (6 + 7 + 8)
3. The indexes become an arithmetic series $a + (a + 1) + (a + 2) + ... + (a + n)$, where:
    - $a$ is the first term (the file's first block's index).
    - $n$ is the number of terms (the file size).
4. And the formula for the sum of an arithmetic series is:

$$
S_n = n \frac{a_1 + a_n}{2}
$$

5. So to get the checksum we just have to multiply the ID with the sum of the arithmetic series.

## Part two

In part two we have to defragment the disk with a different algorithm. This time, the files cannot be broken up when they are moved, which means that we can only move files to free blocks of the same or larger size.

To do this, we can keep track of all the free space indexes and sizes. Then, we iterate through each file from the end, and for each file we'll search for a free space from the left side of the disk. If we find one that fits the file and is located on the left side of the file, we'll move the file there.

I suck at explaining algorithms with words, so I'll explain each part using sections of code. The first thing we need is a data structure to hold the list of free space metadata (its size and index). We'll also have to sort it using its index so that we can get the leftmost free spaces first. We can use a `std.ArrayList` here, but the algorithm performance will be slow. We'll need to do a lot of insertion and deletion of items, which is slow in a list because we have to iterate through the list and sort it each time.

Instead of a list, we can use a heap data structure. In this case, we'll need a min-heap because our free spaces need to ordered from the smallest indexes first. Heap insertions and deletions keep the order of the items and is usually faster than in lists. In Zig, we can use a `std.PriorityQueue` because it implements a min-heap under the hood.

Free spaces can have ten different sizes (0-9), which means we have to create ten heaps, one for each size. The reason for this is that if we put the different sizes in one heap, we'll still have to iterate through its items to search for a suitable size. This will take away the advantage we have by using the heap in the first place. Okay, enough explanations. Here's the code to initialize the priority queues:

```zig
fn part2(self: Self) !u64 {
    var free_heaps: [10]std.PriorityQueue(usize, void, compare) = undefined;
    for (1..10) |i| {
        free_heaps[i] = std.PriorityQueue(usize, void, compare).init(self.allocator, {});
    }
    defer for (free_heaps[1..]) |heap| heap.deinit();
    // ...
}
```

The `compare` function is used for ordering the items in the priority queue:

```zig
fn compare(_: void, a: usize, b: usize) std.math.Order {
    return std.math.order(a, b);
}
```

We'll skip the initialization of the queue with for the zero-sized free spaces because we won't need it. Next, we'll also keep track of the index and the size of each file. We can use `std.ArrayList` for this since we're just going to iterate over the files in order. Originally I used a list of structs that hold the index and size of the files, but then refactored it to use arrays instead to avoid allocation.

We'll use two arrays here, one to keep track of file sizes and the other for the indexes. My input has exactly 9999 files (and I assume it's the same for other inputs too), so I'll initialize the arrays with a capacity of 10,000. Then, we'll iterate over the disk map again and fill up the heaps and the file arrays:

```zig
fn part2(self: Self) !u64 {
    // ...
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
    // ...
}
```

Next is the main part of the solution. We'll iterate over the files in reverse, and for each file we'll:

1. Get the leftmost free index that fits the current file size.
2. If the free index is on the left side of the file, we can move the file into the free space. We'll remove the free space from its heap.
3. Then we subtract the file size from the free space size and insert the remaining size as well as the new free space index into the heap of the corresponding size.

In code, this looks like:

```zig
fn part2(self: Self) !u64 {
    // ...
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
    // ...
}
```

Finally, we just have to calculate the filesystem checksum, which works the same way as in part one:

```zig
fn part2(self: Self) !u64 {
    // ...
    var result: u64 = 0;
    for (0..(file_count + 1)) |id| {
        result += file_checksum(id, file_sizes[id], file_indexes[id]);
    }
    return result;
    // ...
}
```

And that gets us the answer to part two. Here's the full code for part two:

```zig
fn part2(self: Self) !u64 {
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
```

## Benchmarks
