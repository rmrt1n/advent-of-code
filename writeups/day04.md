# Day 04: Ceres Search

[Full solution](../src/days/day04.zig).

## Part one

Day four's puzzle is a word search. For part one, we have to count the occurence of the word **`XMAS`** in our puzzle input. The word can be horizontal, vertical, diagonal, and written backwards, for example:

```
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

To get started we'll parse this input into a matrix or a 2D grid.

```zig
fn Day04(length: usize) type {
    return struct {
        words: [length][length]u8 = undefined,

        const Self = @This();

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

The appoach we'll take for this solution is to iterate over the matrix in all possible directions (horizontal `-`, vertical `|`, backward diagonal `\`, and forward diagonal `/`) in windows of four (the length of `XMAS`). For each window, we'll check if it matches `XMAS` or its reverse `SAMX`.

To illustrate, here are the windows for the index `i, j`:

```
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

1. The horizontal window is: `i, j`, `i, j+1`, `i, j+2`, `i, j+3`.
2. The vertical window is: `i, j`, `i+1, j`, `i+2, j`, `i+3, j`.
3. The backward diagonal window is: `i, j`, `i+1, j+1`, `i+2, j+2`, `i+3, j+3`.
4. The forward diagonal window is: `i+3, j`, `i+2, j+1`, `i+1, j+2`, `i, j+3`.

Now to put it in code:

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

Because we're doing unsafe indexing (with index arithmetics), we have to make sure not to go out of bounds. For the horizontal and vertical windows, we can do this by limiting `j` to be at most N-4. For the diagonals, we have to limit both `i` and `j` to be less then M-4 and N-4 respectively. M is the number of rows, N is the number of columns, and 4 is the length of `XMAS`.

The `matches` function checks if a string matches either `XMAS` or `SAMX`:

```zig
fn matches(comptime word: []const u8, slice: []const u8) bool {
    var reversed: [word.len]u8 = undefined;
    @memcpy(&reversed, word);
    std.mem.reverse(u8, &reversed);
    return std.mem.eql(u8, word, slice) or std.mem.eql(u8, &reversed, slice);
}
```

Some notes about the `matches` function. Usually, to reverse an arbitrary string you need to dynamically allocate a buffer with the same size as the string which happens at runtime, because the size of the string is unknown at compile time. However, the `XMAS` string is compile-time known, so we can initialize an array with the length of the string. The downside of this is that it'll only work for strings that are the same length as `XMAS`. If we have another string with a different length that we want to check (which we do in part two), we'll have to write another function just to handle that other string.

With Zig's comptime, we can write just one function to do this, and Zig will generate the corresponding functions for every string we want to check. The `matches` function above takes in a `word` that is compile-time known (marked by `comptime`). Under the hood, the Zig compiler will create a separate function for every different `word` passed to it.

E.g. if your code contains `matches("XMAS", slice)` and `matches("A", slice)`, zig will create two functions `matches_anon_random_id1` and `matches_anon_random_id2`. `matches_anon_random_id1` contains a buffer of length four, while `matches_anon_random_id2`'s buffer has a length of one.


## Part two

In part two, instead of searching for the word `XMAS`, we have to find **two `MAS` in an "X" shape**, like so:

```
M S
 A
M S
```

Just like in part one, the `MAS` string can be in reversed order too. Here, we can actually reuse part one's solution with slight tweaks. Now, we only have to check the diagonal windows and check that if both of them contain `MAS`.

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

## Benchmarks
