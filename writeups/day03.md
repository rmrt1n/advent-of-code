# Day 03: Mull it Over

[Full solution](../src/days/day03.zig).

## Puzzle Input

Today's input is a computer program's **corrupted memory**:

```plaintext
xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))
```

There isn't anything more we have to do to parse the input, so we'll just copy it into a field in our puzzle type:

```zig
fn Day03() type {
    return struct {
        const Self = @This();

        memory: []const u8,

        fn init(input: []const u8) Self {
            return Self{ .memory = input };
        }
    };
}
```

## Part One

We have to find all uncorrupted **multiplication instructions**, evaluate them, and sum up the results. A multiplication instruction follows the format `mul(x,y)` where `x` and `y` are integers. There cannot be any extra characters in it, even whitespace.

We can find all of the multiplication instructions using only regex, but Zig doesn't have regex in its standard library. You could use the [POSIX regex.h](https://www.openmymind.net/Regular-Expressions-in-Zig/), but I don't want to do this so we'll write a parser instead.

Here's an overview of the parsing logic:

1. Scan every character in the input string.
2. If we find a `m` character, see if it is the first character of the string `mul(`.
3. If it is, attempt to parse two integers, separated by a comma `,`, and ending with a right parenthesis `)`.
4. If everything matches, multiply the two numbers and add the result to the total.
5. If at any point we encounter an unexpected character, skip to the next character.

Here's the implementation in Zig:

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

> [!WARNING]
> Some of the slicing code above (and in part two), e.g. `self.memory[i..(i + 4)]`, is technically unsafe, but this works for my input and the sample inputs, so I'll just leave this as is and assume the other inputs are well-formed enough not to trigger this. If it doesn't work for your input, consider this an an exercise for the reader.

## Part Two

Part two introduced two instructions: the **enable instruction** `do()` and the **disable instruction** `don't()`. `do()` enables future multiplication instructions and `don't` disables them. By default the multiplication instructions are enabled.

We'll keep track of the enabled state using a boolean state and update the parsing logic. We can reuse the logic from part one and add the logic for parsing enable/disable instructions before parsing the multiplication instructions. Here's the code:

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

> [!TIP]
> Just for fun, here's the [EBNF grammar](https://en.wikipedia.org/wiki/Extended_Backus%E2%80%93Naur_form) for this puzzle's program language:
> ```ebnf
> program         = { instruction | garbage } ;
> instruction     = enable | disable | multiplication ;
> enable          = "do()" ;
> disable         = "don't()" ;
> multiplication  = "mul(" , integer , "," , integer , ")" ;
> integer         = digit , { digit } ;
> digit           = "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" ;
> garbage         = ? any unexpected or malformed character ? ;
> ```
## Benchmark

All benchmarks were performed on an [Apple M3 Pro](https://en.wikipedia.org/wiki/Apple_M3) with times in microseconds (µs).

| Part/Optimise | Debug (µs) | ReleaseSafe (µs) | ReleaseFast (µs) | ReleaseSmall (µs) |
|-------------- | ---------: | ---------------: | ---------------: | ----------------: |
| Parsing       | 0.0        | 0.0              | 0.0              | 0.0               |
| Part 1        | 110.3      | 9.4              | 7.2              | 15.4              |
| Part 2        | 119.7      | 14.2             | 16.0             | 20.7              |
| **Total**     | **230.1**  | **23.6**         | **23.2**         | **36.1**          |
