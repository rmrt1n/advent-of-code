# Day 07: Bridge Repair

[Full solution](../src/days/day07.zig).

## Puzzle Input

Today's input is a list of **calibration equations** with their operators removed:

```plaintext
190: 10 19
3267: 81 40 27
83: 17 5
156: 15 6
7290: 6 8 6 15
161011: 16 10 13
192: 17 8 14
21037: 9 7 18 13
292: 11 6 16 20
```

Each line represents an equation with the **test value** on the left of the colon `:` and the **operands** on the right. We'll parse the test values and the operands into separate arrays. Since each equation can have different numbers of operands, we'll parse the values into a fixed-capacity 2D array and store the lengths in a separate array (just like in day five).

```zig
fn Day07(length: usize) type {
    return struct {
        const Self = @This();

        const operand_capacity = 12;

        test_values: [length]u64 = undefined,
        operands: [length][operand_capacity]u16 = undefined,
        lengths: [length]u8 = undefined,

        fn init(input: []const u8) !Self {
            var result = Self{};

            var i: usize = 0;
            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                var inner_lexer = std.mem.tokenizeScalar(u8, line, ' ');

                const left = inner_lexer.next().?;
                result.test_values[i] = try std.fmt.parseInt(u64, left[0..(left.len - 1)], 10);

                var j: u8 = 0;
                while (inner_lexer.next()) |number| : (j += 1) {
                    result.operands[i][j] = try std.fmt.parseInt(u16, number, 10);
                }
                result.lengths[i] = j;
            }

            return result;
        }
    };
}
```

> [!NOTE]
> The longest equation operands in my input is 12. This value might be different depending on your input. Please adjust the value of your `operand_capacity` accordingly.

## Part One

For part one we have to count the **total calibration result**. This is the sum of the test values of the equations that could possibly be true.

An equation can be true if by adding the missing operators, the resulting equation would result in the actual test value. There are two types of operators: addition `+` and multiplication `*`. Operators are always evaluated from left to right.

What we have to do here is to try every permutation of operators on an equation and check if any permutation results in the test value. First, we'll define a type for the operators:

```zig
const Operator = enum {
    add, mul,

    fn apply(operator: Operator, x: u64, y: u64) u64 {
        return switch (operator) {
            .add => x + y,
            .mul => x * y,
        };
    }
};
```

The `apply` method returns the result of applying an operator to two operands.

Next, we'll write a function to check if a given equation is valid:

```zig
fn is_valid_equation(
    permutations: []u64,
    test_value: u64,
    operands: []const u16,
    comptime operators: []const Operator,
) bool {
    permutations[0] = operands[0];

    var left: usize = 0;
    var right: usize = 1;
    for (operands[1..]) |operand| {
        const permutations_length = right;
        while (left < permutations_length) : (left += 1) {
            for (operators) |operator| {
                const applied = operator.apply(permutations[left], operand);

                if (applied == test_value) return true;

                // Skip numbers larger than the test value.
                if (applied > test_value) continue;

                permutations[right] = applied;
                right += 1;
            }
        }
    }

    return false;
}
```

`is_valid_equation` tries all possible ways to combine the operators from `operators` and keeps track of the intermediate results in `permutations`.  The `permutations` array acts like a pseudo-queue by using a two-pointers technique to process only the "active" window.

`permutations` must have enough capacity to store all intermediate results for a given operands list. We create this array once in the caller and reuse it for subsequent calls. This is safe because we overwrite the contents each time. This avoids the overhead of recreating the array inside `is_valid_equation` every time we call it.

Here's the code for part one:

```zig
fn part1(self: Self) u64 {
    const operators = [_]Operator{ .add, .mul };
    const n = operators.len;
    var permutations: [(std.math.pow(u64, n, operand_capacity) - 1) / (n - 1)]u64 = undefined;

    var result: u64 = 0;
    for (self.test_values, self.operands, self.lengths) |test_value, operands, len| {
        if (is_valid_equation(&permutations, test_value, operands[0..len], &operators)) {
            result += test_value;
        }
    }
    return result;
}
```

> [!TIP]
> The minimum capacity of the `permutations` is the sum of the geometric series $a + ar + ar^2 + ... + ar^n$:
>
> $$ \sum_{k=0}^{n-1} a r^k = a \frac{r^n - 1}{r - 1}, \quad r \neq 1 $$
>
> Where:
>
> - $a$ is the first term (1).
> - $r$ is the common ratio, which in this case is the number of operators (2).
> - $n$ is the number of terms (11). In my input, the longest operands sequence is 12, which means the longest combination of operators is 11.
>
> In other words, the minimum capacity is (the number of permutations of $r$ operators for 1 operand) + (the number of permutations of $r$ operators for 2 operands) + ... + (the number of permutations of $r$ operators for `operand_capacity - 1` operands).

## Part Two

For part two we still have to find the total calibration result, but now we have a new operator, the **concatenation operator** `||`. This operator concatenates its operands together, e.g. `12 || 34 = 1234`.

We structured our part one code in a way that we can reuse almost all of it for part two. All we need to do is to add the new operator to the `Operator` type and implement its behaviour in `apply`:

```zig
const Operator = enum {
    add, mul, cat,

    fn apply(operator: Operator, x: u64, y: u64) u64 {
        return switch (operator) {
            .add => x + y,
            .mul => x * y,
            .cat => x * std.math.pow(u64, 10, std.math.log10(y) + 1) + y,
        };
    }
};
```

The part two code is almost identical to part one's:

```zig
fn part2(self: Self) u64 {
    const operators = [_]Operator{ .add, .mul, .cat };
    const n = operators.len;
    var permutations: [(std.math.pow(u64, n, operand_capacity) - 1) / (n - 1)]u64 = undefined;

    var result: u64 = 0;
    for (self.test_values, self.operands, self.lengths) |test_value, operands, len| {
        if (is_valid_equation(&permutations, test_value, operands[0..len], &operators)) {
            result += test_value;
        }
    }
    return result;
}
```

> [!TIP]
> You can concatenate two numbers $x$ and $y$ by shifting $x$ by the number of digits in y, then adding $y$. You can get the number of digits of a base 10 number $y$ by getting its $log_{10}(y) + 1$.
>
> $$cat(x,y) = x \cdot 10^{\lfloor \log_{10}(y) \rfloor + 1} + y$$

## Benchmark

All benchmarks were performed on an [Apple M3 Pro](https://en.wikipedia.org/wiki/Apple_M3) with times in microseconds (µs).

| Debug | ReleaseSafe | ReleaseFast | ReleaseSmall |
| ----- | ----------- | ----------- | ------------ |
|       |             |             |              |
