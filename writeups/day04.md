# Day 04: Ceres Search

[Full solution](../src/days/day04.zig).

## Puzzle Input

Today's input is **word search** puzzle:

```plaintext
MMMSXXMASM
MSAMXMSMSA
AMXSXMAAMM
MSAMASMSMX
XMASAMXAMM
XXAMMXXAMA
SMSMSASXSS
SAXAMASAAA
MAMMMXMMMM
MXMXAXMASX
```

We'll parse this into a 2D array:

```zig
fn Day04(length: usize) type {
    return struct {
        const Self = @This();

        words: [length][length]u8 = undefined,

        fn init(input: []const u8) Self {
            var result = Self{};

            var i: u8 = 0;
            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                @memcpy(&result.words[i], line);
            }

            return result;
        }
    };
}
```

## Part One

We have to count the occurrences of the word **XMAS** in the word search. This word can be horizontal, vertical, diagonal, or written backwards in the word search.

We'll use a sliding 4x4 window for this. For each window, we'll slice it in the four directions (horizontal, vertical, backwards diagonal, and forwards diagonal). For each slice, we'll check whether it contains either `XMAS` or its reverse `SAMX`.

Here's a visualisation of the indexes of a window for the starting position $i,j$:

```plaintext
┌─────────┬─────────┬─────────┬─────────┐
│   i,j   │  i,j+1  │  i,j+2  │  i,j+3  │
├─────────┼─────────┼─────────┼─────────┤
│  i+1,j  │ i+1,j+1 │ i+1,j+2 │ i+1,j+3 │
├─────────┼─────────┼─────────┼─────────┤
│  i+2,j  │ i+2,j+1 │ i+2,j+2 │ i+2,j+3 │
├─────────┼─────────┼─────────┼─────────┤
│  i+3,j  │ i+3,j+1 │ i+3,j+2 │ i+3,j+3 │
└─────────┴─────────┴─────────┴─────────┘
```

Here's the code to count `XMAS` using sliding windows:

```zig
fn part1(self: Self) u64 {
    var result: u64 = 0;

    for (0..length) |i| { // Horizontal _ and vertical |
        for (0..(length - 4 + 1)) |j| {
            const horizontal = .{
                self.words[i][j],     self.words[i][j + 1],
                self.words[i][j + 2], self.words[i][j + 3],
            };
            const vertical = .{
                self.words[j][i],     self.words[j + 1][i],
                self.words[j + 2][i], self.words[j + 3][i],
            };

            if (matches("XMAS", &horizontal)) result += 1;
            if (matches("XMAS", &vertical)) result += 1;
        }
    }

    for (0..(length - 4 + 1)) |i| { // Backward \ and forward / diagonals
        for (0..(length - 4 + 1)) |j| {
            const diagonal_backward = .{
                self.words[i][j],         self.words[i + 1][j + 1],
                self.words[i + 2][j + 2], self.words[i + 3][j + 3],
            };
            const diagonal_forward = .{
                self.words[i + 3][j],     self.words[i + 2][j + 1],
                self.words[i + 1][j + 2], self.words[i][j + 3],
            };

            if (matches("XMAS", &diagonal_backward)) result += 1;
            if (matches("XMAS", &diagonal_forward)) result += 1;
        }
    }

    return result;
}
```

The `matches` function checks if a given string matches a known string or its reversed:

```zig
fn matches(comptime word: []const u8, slice: []const u8) bool {
    var reversed: [word.len]u8 = undefined;
    @memcpy(&reversed, word);
    std.mem.reverse(u8, &reversed);
    return std.mem.eql(u8, word, slice) or std.mem.eql(u8, &reversed, slice);
}
```

The known string `word` must be compile-time known so Zig can statically allocate the array to store its reverse. If the string to find is only known at runtime, we'll have to dynamically allocate the array based on the string's length.

## Part Two

Instead of the word `XMAS`, we have to find all of the **X-MAS**. This is two `MAS` in an X shape, like so:

```plaintext
M.S
.A.
M.S
```

Just like in part one, the word can be written in reverse too. We can reuse most of our part one code for part two. Now, we just have to check the two diagonals for the word `MAS`:

```zig
fn part2(self: Self) u64 {
    var result: u64 = 0;
    for (0..(length - 3 + 1)) |i| {
        for (0..(length - 3 + 1)) |j| {
            const diagonal_backward = .{
                self.words[i][j], self.words[i + 1][j + 1], self.words[i + 2][j + 2],
            };
            const diagonal_forward = .{
                self.words[i + 2][j], self.words[i + 1][j + 1], self.words[i][j + 2],
            };

            if (matches("MAS", &diagonal_backward) and matches("MAS", &diagonal_forward)) {
                result += 1;
            }
        }
    }
    return result;
}
```

> [!TIP]
> There are two unique strings passed to `matches`. Under the hood, Zig will create two functions. Each function is a version of `match` specifically for each word.
> ```zig
> // This is the original function.
> fn matches(comptime word: []const u8, slice: []const u8) bool {}
>
> // Gets compiled to:
> fn matches__anon_1(comptime word: []const u8, slice: []const u8) bool {
>   var reversed: [4]u8 = undefined; // "SAMX"
>   // ...
> }
> fn matches__anon_2(comptime word: []const u8, slice: []const u8) bool {
>   var reversed: [3]u8 = undefined; // "SAM"
>   // ...
> }
> ```

## Benchmark

All benchmarks were performed on an [Apple M3 Pro](https://en.wikipedia.org/wiki/Apple_M3) with times in microseconds (µs).

| Debug | ReleaseSafe | ReleaseFast | ReleaseSmall |
| ----- | ----------- | ----------- | ------------ |
|       |             |             |              |
