# Day 17: Chronospatial Computer

[Full solution](../src/days/day17.zig).

## Puzzle Input

Today's input is a program for a **3-bit computer**:

```plaintext
Register A: 729
Register B: 0
Register C: 0

Program: 0,1,5,4,3,0
```

The first section of the input describes the three **registers** and the second section lists the program's instructions.

We'll parse the registers into a struct type with one field for each register and parse the instructions into an array. We'll need to simulate the program later, so we'll also add an `ip` field (instruction pointer) to keep track of the current instruction:

```zig
fn Day17(length: usize) type {
    return struct {
        const Self = @This();
        const Registers = struct {
            a: u64,
            b: u64,
            c: u64,
        };

        registers: Registers = undefined,
        instructions: [length]u3 = undefined,
        ip: usize = 0,
        allocator: std.mem.Allocator = undefined,

        fn init(input: []const u8, allocator: std.mem.Allocator) !Self {
            var result = Self{ .allocator = allocator };

            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            result.registers.a = try std.fmt.parseInt(u64, lexer.next().?[12..], 10);
            result.registers.b = try std.fmt.parseInt(u64, lexer.next().?[12..], 10);
            result.registers.b = try std.fmt.parseInt(u64, lexer.next().?[12..], 10);

            var i: usize = 0;
            lexer = std.mem.tokenizeScalar(u8, lexer.next().?[9..], ',');
            while (lexer.next()) |line| : (i += 1) {
                result.instructions[i] = try std.fmt.parseInt(u3, line, 10);
            }

            return result;
        }
    };
}
```

## Part One

We need to find the **output of the program**. We can do this by simulating the computer and running its instructions. Each instruction in the program is followed by its **operand**. There are two types of operands:

1. **Literal operands**: the value of the operand is the operand itself.
2. **Combo operands**: the value of the operand follows this rule:
    - Operand 0-3 represent literal values 0 through 3.
    - Operand 4 represents the value of register A.
    - Operand 5 represents the value of register B.
    - Operand 6 represents the value of register C.
    - Operand 7 is reserved and will not appear in valid programs.

The computer supports 8 different types of instructions:

| Opcode | Instruction | Description |
| ------ | ----------- | ----------- |
| 0      | `adv`       | Calculates the division of the value in register A with 2 raised to the power of its combo operand. |
| 1      | `bxl`       | Calculates the bitwise XOR of register B and its literal operand, stores the result in register B. |
| 2      | `bst`       | Calculates the value of its combo operand modulo 8, stores the result in the B register. |
| 3      | `jnz`       | No-op if register A is 0. Else, it sets the instruction pointer to the value of its literal operand. |
| 4      | `bxc`       | Calculates the bitwise XOR of register B and register C, stores the result in register B. This instruction reads an operand but ignores it. |
| 5      | `out`       | Calculates the value of its combo operand modulo 8, then outputs that value. |
| 6      | `bdv`       | Same as `adv` but the result is stored in register B. The numerator is still read from register A. |
| 7      | `cdv`       | Same as `adv` but the result is stored in register C. The numerator is still read from register A. |

We'll create a function to run the program and capture the output:

```zig
fn run(self: *Self, output: *std.ArrayList(u3)) !void {
    while (self.ip < self.instructions.len) {
        const opcode: Opcode = @enumFromInt(self.instructions[self.ip]);
        switch (opcode) {
            .adv => {
                const operand = self.get_operand(true);
                const numerator = self.registers.a;
                const denumerator = std.math.pow(u64, 2, operand);
                self.registers.a = numerator / denumerator;
            },
            .bxl => {
                const operand = self.get_operand(false);
                self.registers.b ^= operand;
            },
            .bst => {
                const operand = self.get_operand(true);
                self.registers.b = operand % 8;
            },
            .jnz => {
                if (self.registers.a != 0) {
                    self.ip = self.instructions[self.ip + 1];
                } else {
                    self.ip += 2;
                }
            },
            .bxc => {
                self.registers.b ^= self.registers.c;
                self.ip += 2;
            },
            .out => {
                const operand = self.get_operand(true);
                try output.append(@intCast(operand % 8));
            },
            .bdv => {
                const operand = self.get_operand(true);
                const numerator = self.registers.a;
                const denumerator = std.math.pow(u64, 2, operand);
                self.registers.b = numerator / denumerator;
            },
            .cdv => {
                const operand = self.get_operand(true);
                const numerator = self.registers.a;
                const denumerator = std.math.pow(u64, 2, operand);
                self.registers.c = numerator / denumerator;
            },
        }
    }
}
```

The caller is responsible for managing the output list `std.ArrayList`, so we pass it by reference instead of making `run` return a new list. This makes it clear who owns the list and makes it easier to reuse the list across multiple runs.

We also create a `get_operand` function to return the correct value based on the operand type:

```zig
fn get_operand(computer: *Self, is_combo: bool) u64 {
    defer computer.ip += 1;
    computer.ip += 1;

    const operand = computer.instructions[computer.ip];
    if (!is_combo) return operand;

    return switch (operand) {
        0, 1, 2, 3 => operand,
        4 => computer.registers.a,
        5 => computer.registers.b,
        6 => computer.registers.c,
        7 => unreachable, // reserved
    };
}
```

Then, in our `part1` function, we just have to allocate the list and call the `run` function:

```zig
fn part1(self: *Self) !std.ArrayList(u3) {
    var result = std.ArrayList(u3).init(self.allocator);
    try self.run(&result);
    return result;
}
```

> [!TIP]
> The `is_combo` parameter in `get_operand` isn't [the "right" place for a boolean](https://matt.diephouse.com/2020/05/you-might-not-want-a-boolean/). It's usually better to encode it as a "operand type" enum so it's clear what we're doing at the call site, e.g.:
>
> ```
> // Instead of this:
> const operand = self.get_operand(true); // What does true mean?
> 
> // The intent is clearer here:
> const operand = self.get_operand(.literal); // We're getting the literal operand here
> const operand = self.get_operand(.combo); // We're getting the combo operand here
> ```
>
> In this case, the problem scope is small (just this puzzle), so I’m leaving it as-is. I just wanted to point out a better approach for writing this type of code.

## Part Two

We need to find the lowest positive value for register A that results in the **program outputting itself**. This one is as cool as day 14's part two about finding the Christmas tree!

The program in the puzzle input has a distinct structure to it. We can reverse engineer it and translate the instructions into Zig code:

```zig
while (a > 0) : (a /= 8){
    b = (a % 8) ^ x;
    c = a / std.math.pow(u32, 2, b);
    b ^= c ^ y

    std.debug.print("{}", .{b & 8});
}
```

As you can see, the program is a simple while loop. In each iteration, we mod `a` by 8, use the result to compute `b` and `c`, output a value, and then divide `a` by 8. This continues until `a` becomes 0. Here, `a`, `b`, and `c` refer to the values in their corresponding registers.

What is actually happening here is the program processes one digit at a time from the base 8 (octal) representation of `a`. This works the same as processing digits in regular base 10 (decimal) numbers, but instead of dividing and modding by 10, we use 8.

From this, we can also infer the length, i.e. the number of digits, of `a` (in base 8). It must match the length of the program, since we output as many times as the number of digits in `a`. In my case, this number is 16. This is actually the minimum length, not the exact length. Larger digits can still output the same program, which is why we're finding the lowest valid value.

Now that we know this, we can write a solution to find possible values of the A register. We'll start with `a` as 0, then build it up one digit at a time. We'll use a queue to hold the intermediate values of `a` as we're building it:

```zig
fn part2(self: *Self) !u64 {
    var queue = std.ArrayList(u64).init(self.allocator);
    defer queue.deinit();

    try queue.append(0);

    var output = std.ArrayList(u3).init(self.allocator);
    defer output.deinit();

    for (1..(length + 1)) |i| {
        const queue_length = queue.items.len;
        for (0..queue_length) |_| {
            const candidate = queue.pop().? * 8;
            for (candidate..(candidate + 8)) |next_candidate| {
                // Clear output array and reset computer state.
                output.clearRetainingCapacity();
                self.reset();
                self.registers.a = next_candidate;

                try self.run(&output);

                // We build a in a reverse order, so compare against the end of the program.
                if (std.mem.eql(u3, output.items[0..], self.instructions[(length - i)..])) {
                    try queue.insert(0, next_candidate);
                }
            }
        }
    }

    std.mem.sort(u64, queue.items, {}, std.sort.asc(u64));
    return queue.items[0];
}
```

For each digit position (up to 16), we try adding another digit (0-7) to the end of each candidate value in the queue. For each of those, we run the program and check if the output matches the last `i` digits of the original program. If it is, we append it the queue.

> [!NOTE]
> We check the first `i` digit of the output with the last `i` digits of the actual program. This is because we're building `a` from front digits first, while the program process the last digits first.

After we've processed each digit, what's left in the queue is the candidate values with at least 16 digits. We just have to sort the queue and return the smallest value.

At each run, we reset the computer's state. This is done by a helper function:

```zig
fn reset(self: *Self) void {
    self.registers.a = 0;
    self.registers.b = 0;
    self.registers.c = 0;
    self.ip = 0;
}
```

> [!TIP]
> This solution won't work with the sample inputs, because it assumes the program follows the same structure as the puzzle input. There are other ways to solve this, which doesn't make this assumption. Checkout these other solutions in the [Advent of Code subreddit](https://www.reddit.com/r/adventofcode/comments/1hg38ah/2024_day_17_solutions/). Some of them are generalised and might work with any program configuration.

## Benchmark

All benchmarks were performed on an [Apple M3 Pro](https://en.wikipedia.org/wiki/Apple_M3) with times in microseconds (µs).

| Debug | ReleaseSafe | ReleaseFast | ReleaseSmall |
| ----- | ----------- | ----------- | ------------ |
|       |             |             |              |
