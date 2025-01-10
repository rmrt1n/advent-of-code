# Day 03: Mull it Over

[Full solution](../src/days/day03.zig).

## Part one

Day three is a parsing puzzle, one of my favorites. In part one, we have to find and **evaluate all `mul`** (arithmetic multiplication) instructions in the puzzle input. E.g., for this input:

```
xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))
```

The result will be the sum of `mul(2,4)`, `mul(5,5)`, `mul(11,8)`, and `mul(8,5)`. Instructions with whitespaces in it doesn't count, e.g. `mul(2, 4)` or `mul (2,4)`. The format is simple enough that you can solve it with regex alone. Zig doesn't have regex built-in to its standard library, so we'll parse it manually.

Just for fun, here's an [EBNF grammar](https://en.wikipedia.org/wiki/Extended_Backus%E2%80%93Naur_form) for the `mul` instruction that we have to search:

```
mul = "mul(" integer  "," integer ")"
integer = digit+
digit = "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9"
```

For this day, there is no input parsing logic and we can work directly on the puzzle input string.

```zig
fn Day03() type {
    return struct {
        memory: []const u8,

        const Self = @This();

        fn init(input: []const u8) Self {
            return Self{ .memory = input };
        }
    };
}
```

The actual parsing logic looks like this:

1. Iterate through every character in the input string.
2. If the prefix string `"mul("` is found, attempt to parse the two integers separated by a comma and ending in a left parenthesis.
3. If at any point in the parsing a wrong character is found, skip this iteration.
4. If we successfully parsed the two integers, multiply them and add the result to the total result.

Here's the code for part one:

```zig
fn part1(self: Self) u64 {
    var result: u64 = 0;
    var i: usize = 0;
    while (i < self.memory[0..].len) : (i += 1) {
        if (self.memory[i] == 'm') {
            if (std.mem.eql(u8, self.memory[i..(i + 4)], "mul(")) {
                i += 4;

                var x: u64 = 0;
                while (self.memory[i] >= '0' and self.memory[i] <= '9') : (i += 1) {
                    x = x * 10 + self.memory[i] - '0';
                }

                if (self.memory[i] != ',') continue;
                i += 1;

                var y: u64 = 0;
                while (self.memory[i] >= '0' and self.memory[i] <= '9') : (i += 1) {
                    y = y * 10 + self.memory[i] - '0';
                }

                if (self.memory[i] != ')') continue;

                result += x * y;
            }
        }
    }
    return result;
}
```

This code will fail in some cases though, e.g. if the input string ends with `"mu"`. Because we're optimistically checking the next N characters of the input without checking if we're already at the end of the input string. I've manually confirmed that the puzzle input file doesn't contain these cases, so the code is safe to use.

## Part two

Part two introduced two new instructions, `do()` and `don't()`. `do()` **enables** future `mul` and `don't()` **disables** them. `mul` instructions are enabled by default. Since the `mul` instruction can only be either enabled or disabled, we can use a boolean flag to keep track of this state.

The updated grammar looks like this:

```
mul = "mul(" integer  "," integer ")"
integer = digit+
digit = "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9"
do = "do()"
dont = "don't()"
```

We can keep the parsing logic from part one, but with a slight modification. In each iteration, before looking for the `"mul("` prefix, we first check if the current character is a part of either a `do()` or `don't()` instruction. If it's a `don't()`, we'll skip parsing any future `mul` instructions until it's enabled again. Putting this in code: 

```zig
fn part2(self: Self) u64 {
    var result: u64 = 0;
    var mul_enabled = true;
    var i: usize = 0;
    while (i < self.memory[0..].len) : (i += 1) {
        if (self.memory[i] == 'd') {
            if (std.mem.eql(u8, self.memory[i..(i + 4)], "do()")) {
                mul_enabled = true;
                i += 4;
            }
            if (std.mem.eql(u8, self.memory[i..(i + 7)], "don't()")) {
                mul_enabled = false;
                i += 7;
            }
        }
        if (mul_enabled and self.memory[i] == 'm') {
            if (std.mem.eql(u8, self.memory[i..(i + 4)], "mul(")) {
                // This is the same as in part one.
                // ...
            }
        }
    }
    return result;
}
```

## Benchmarks
