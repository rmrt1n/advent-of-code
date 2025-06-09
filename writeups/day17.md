# Day 17:

[Full solution](../src/days/day17.zig).

## Part one

Day 17 is a VM puzzle. We have a fictional 3-bit computer with three registers and eight instruction types. The puzzle input looks like this:

```
Register A: 729
Register B: 0
Register C: 0

Program: 0,1,5,4,3,0
```

The program is a list of instructions, each followed by its operand. There are two types of operands:

1. **Literal operands**: the value of the operand is the operand itself.
2. **Combo operands**: the value of the operand follows this rule:
    - Operand 0-3 represent literal values 0 through 3.
    - Operand 4 represents the value of register A.
    - Operand 5 represents the value of register B.
    - Operand 6 represents the value of register C.
    - Operand 7 is reserved and will not appear in valid programs.

And these are the instruction types:

0. `adv`: Calculates the division of the value in register A with 2 raised to the power of its combo operand.
1. `bxl`: Calculates the bitwise XOR of register B and it's literal operand, stores the result in register B.
2. `bst`: Calculates the value of its combo operand modulo 8, stores the result in the B register.
3. `jnz`: No-op if register A is 0. Else, it sets the instruction pointer to the value of its literal operand.
4. `bxc`: Calculates the bitwise XOR of register B and register C, stores the result in register B. This instruction reads an operand but ignores it.
5. `out`: Calculates the value of its combo operand modulo 8, then outputs that value.
6. `bdv`: Same as `adv` but the result is stored in register B. The numerator is still read from register A.
7. `cdv`: Same as `adv` but the result is stored in register C. The numerator is still read from register A.

Part one is straightforward enough, we just have to create a VM and run the program from our input file. First, we'll parse the input:

```zig
fn Day17(length: usize) type {
    return struct {
        registers: struct {
            a: u64,
            b: u64,
            c: u64,
        } = undefined,
        instructions: [length]u3 = undefined,
        ip: usize = 0,
        allocator: std.mem.Allocator = undefined,

        const Self = @This();

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

Then, we'll create a function to run the VM program:

```zig
fn run(self: *Self) !std.ArrayList(u3) {
    var output = std.ArrayList(u3).init(self.allocator);
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
    return output;
}
```

This is a straightforward function, we process the instructions one at a time and update the VM's state and capture any output in an array list. `get_operand` is a helper function to handle the combo operand logic:

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

Finally, we just have to call the `run` function:

```zig
fn part1(self: Self) !std.ArrayList(u3) {
    var simulation = self;
    return simulation.run();
}
```

## Part two

Part two is where the fun's at. This one might be my favorite puzzle from the whole challenge. Now, we have to find the lowest value that when set in register A will make the program output itself.

There are many different ways to solve this (another reason why this puzzle is so cool). I went with the reverse engineering approach and tried to understand what my program was doing first. I'm pretty sure the other puzzle inputs also follow this structure, but I haven't tested with other inputs, so I'll just assume this will work with most other inputs. Here's my puzzle input translated into python:

```python
while a > 0:
    b = (a % 8) ^ x
    c = a // 2**b
    b ^= c ^ y

    print(b % 8)

    a = a // 8
```

The `x` and `y` vars are literal operands that I think will be different accross inputs, but the program logic should still be the same as above. This program:

1. Starts with the answer for part two as the value in register A.
2. Loop while `a` is not zero:
    - Calculate values of `b` and `c` with `a % 8`.
    - Output the value of `b` after some more instructions.
    - Divide `a` by 8.

What is actually happening here is that each iteration, we're removing the last digit from `a` in base 8 (octal) representation. We know that in base 10 (decimal) number system, if we divide a number by 10 (integer division), we remove the last digit of the number, e.g.:

```
12345 / 10 = 1234
```

The logic is the same in octal, but instead of 10 we divide by 8. In essence what this loop does is get the last digit of `a`, does calculations with it, then outputs a value, then keep doing this until `a` is zero. From this, we can infer that the number of digits of the answer (in base 8) is the same as the length of the program instructions, which is 16 (at least in my input).

At this point, if you have understood the logic of your program, you can just write a script to reverse the program logic and get the value of `a`. I want a solution that will work accross input, so my solution is more of a limited bruteforce.

I'll paste the code first, then I'll explain what it does:

```zig
fn part2(self: Self) !u64 {
    var simulation = self;

    var queue = std.ArrayList(u64).init(self.allocator);
    defer queue.deinit();

    try queue.append(0);

    var i: usize = 1;
    while (i <= length) : (i += 1) {
        var candidates_set = std.AutoHashMap(u64, void).init(self.allocator);
        defer candidates_set.deinit();

        while (queue.items.len > 0) {
            const candidate = queue.pop().? * 8;
            for (candidate..(candidate + 8)) |next_candidate| {
                simulation.reset();
                simulation.registers.a = next_candidate;

                const result = try simulation.run();
                defer result.deinit();

                if (std.mem.eql(u3, result.items[0..], simulation.instructions[(length - i)..])) {
                    try candidates_set.put(next_candidate, {});
                }
            }
        }

        var iterator = candidates_set.keyIterator();
        while (iterator.next()) |key| {
            try queue.append(key.*);
        }
    }

    std.mem.sort(u64, queue.items, {}, std.sort.asc(u64));
    return queue.items[0];
}
```

So what this function does is it's trying to reconstruct the value of register A one digit at a time, starting from the last digit. We start with `a = 0`, then keep appending digits (prefix) to the front until we get the program to output itself.

We used a queue to keep track of the possible answers. Everytime we pop an item `x` from the queue, we run the program using the values of `x` until `x+7` (inclusive) as the value for register A. Here, we're basically checking all possible next prefix of the current number. After each iteration, we have to reset the state of the VM:

```zig
fn reset(self: *Self) void {
    self.registers.a = 0;
    self.registers.b = 0;
    self.registers.c = 0;
    self.ip = 0;
}
```

We know that the length of the program output depends on the number of digits in register A, so to check if the output matches the program itself, we do:

```zig
std.mem.eql(u3, result.items[0..], simulation.instructions[(length - i)..])
```

The program output at N digits must match with the last N instructions of the program. This is because we add digits to the front, not to the back of the current number. After we have tried all possible values, we just sort the queue and get the smallest value.


## Benchmarks
