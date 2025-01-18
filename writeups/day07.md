# Day 07: Bridge Repair

[Full solution](../src/days/day07.zig).

## Part one

Day seven is a combinatorics problem, which means there'll be backtracking, recursion, or dynamic programming. At least that's how it is in LeetCode. We're given a list of equations with their **operators removed**:

```
190: 10 19
3267: 81 40 27
83: 17 5
156: 15 6
7290: 6 8 6 15
161011: 16 10 13
192: 17 8 14
21037: 9 7 18 13
292: 11 6 16 20`
```

Each line is an equation, with the result being the first number in each line. After the colon are the operands used in the equation to equal the result. There are two types of operators, **add `+`** and **multiply `*`**. **Operators are always evaluated from left-to-right**, so we don't have to worry about precedence.

We'll start by parsing the input:

```zig
fn Day07(length: usize) type {
    return struct {
        results: [length]u64 = undefined,
        operands: [length][16]u16 = .{.{0} ** 16} ** length,

        const Self = @This();

        fn init(input: []const u8) !Self {
            var result = Self{};

            var i: usize = 0;
            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                var inner_lexer = std.mem.tokenizeScalar(u8, line, ' ');

                const left = inner_lexer.next().?;
                result.results[i] = try std.fmt.parseInt(u64, left[0..(left.len - 1)], 10);

                var j: usize = 1;
                while (inner_lexer.next()) |number| : (j += 1) {
                    result.operands[i][j] = try std.fmt.parseInt(u16, number, 10);
                }
                result.operands[i][0] = @intCast(j - 1);
            }

            return result;
        }
    };
}
```

We'll use two arrays, one to store the results and another one to store the operands. We'll use the same technique as day two and day five to parse the operands.

For part one (and spoilers, part two too), we have to find only the equations that can be made true using the given operators. We'll do this by computing all the possible combination and permutation of the operators for each equation. We'll implement a `is_valid_equation` for this, but before that we'll first define a type for the operators.

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

The `Operator` enum has a `apply` method that for applying the operator on two operands. As for the `is_valid_equation` function, it'll follow a similar pattern as backtracking/DFS functions:

1. Initialize a buffer to hold the intermediate results.
2. For each item in the buffer, apply the operator on the next operand and push it into the buffer.
3. Repeat until we have no more operands left.

Here's a visualization of the algorithm in pseudocode, with `60` as the result and `[3, 4, 5]` as the operands:

```python
# We start with the first operand in the buffer (queue).
buffer = [3]

# Iteration 1, next operand is 4.
buffer = [3]
# For each item in the buffer and each operator, apply it and insert the result into the buffer.
buffer.push(3 + 4)
buffer.push(3 * 4)

# Iteration 2, next operand is 5.
buffer = [7, 12]
# For each item in the buffer and each operator apply it and insert the result into the buffer.
buffer.push(7 + 5)
buffer.push(7 * 5)
buffer.push(12 + 5)
buffer.push(12 * 5)

# We're done, the buffer is now:
buffer = [12, 35, 17, 60]

# Since it contains the result `60`, it's valid equation. Of course we don't have to make it until the end of the operands. If we find it early, we'll just return early from the function.
```

Here is the algorithm translated to Zig code:

```zig
fn is_valid_equation(result: u64, operands: []const u16, comptime operators: []const Operator) bool {
    const n = operators.len;
    var permutations: [(std.math.pow(u64, n, 12) - 1) / (n - 1)]u64 = undefined;
    permutations[0] = operands[1];

    var left: usize = 0;
    var right: usize = 1;
    for (operands[2..(operands[0] + 1)]) |operand| {
        const old_right = right;
        while (left < old_right) : (left += 1) {
            for (operators) |operator| {
                const applied = operator.apply(permutations[left], operand);

                if (applied == result) return true;

                // Don't include numbers larger than the result, it is a waste of computation.
                // Adding this line results in a roughly 1.3x speedup.
                if (applied > result) continue;

                permutations[right] = applied;
                right += 1;
            }
        }
    }

    return false;
}
```

Okay, this looks a bit different than the pseudocode. The pseudocode from before uses a queue as the buffer, which can be implemented using `std.ArrayList` in Zig. It uses dynamic allocation though, which I wanted to avoid. There's also `std.PriorityDequeue` which could work, but I haven't tried it yet so I don't have much to say about it.

Here, instead of `std.ArrayList` I used a make-shift queue using an array with a big enough capacity to hold all of the permutations. Then, I keep track of the start and end of the "queue" using the `left` and `right` variables which holds the first and last index of the "queue". Here's a visualization based on the previous example:

```python
# Starting state
buffer = [3, ..........extra space]
left = 0
right = 1

# First iteration with the operand 4.
buffer = [3, 7, 12, ..........extra space]
left = 1
right = 3

# Last iteration with the operand 5.
buffer = [3, 7, 12, 12, 35, 17, 60, ..........extra space]
left = 3
right = 7
```

This code is a bit more complex, but results in around 4x speed up on my machine because we don't dynamically allocate memory. Here, I used `(std.math.pow(u64, n, 12) - 1) / (n - 1)` as the size of the array. This is the minimum capacity of the array to be able to hold all permutations from my puzzle input. Here's how this number is derrived:

1. Each iteration, the number of "active" items in the queue becomes $r^k$, where $r$ is the number of operators and $k$ is the current number of operands processed.
2. Therefore the minimum size needed is the sum of the geometric series $a + ar + ar^2 + ... + ar^n$, where:
    - $a$ is the first term (1).
    - $r$ is the common ratio, which in this case is the number of operators (2).
    - $n$ is the number of terms (11). In my input, the longest operands sequence is 12, which means the longest combination of operators is 11.
3. The formula for the sum of the series until term $n$ is:

$$ \sum_{k=0}^{n-1} a r^k = a \frac{r^n - 1}{r - 1}, \quad r \neq 1 $$

At this point it's just me nerding out sorry.., let's get back to the main point, the solution to part one. The heavy lifting is already done by `is_valid_equation`, the code for part one is simple:

```zig
fn part1(self: Self) u64 {
    var result: u64 = 0;
    for (self.results, 0..) |answer, i| {
        const operators = [_]Operator{ .add, .mul };
        if (is_valid_equation(answer, &self.operands[i], &operators)) {
            result += answer;
        }
    }
    return result;
}
```

## Part two

Part two introduced **cat `||`**, a new operator that concatenates two numbers together, e.g. `12 || 2 = 122`. Because we structured the code for part one to work for both parts (through some refactoring before writing this), we only have to add the new operator and it's `apply` method to the `Operator` enum:

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

This is yet another math trick: $x \cdot 10^{\lfloor \log_{10}(y) \rfloor + 1} + y$, which can be translated into:

```zig
var result = x;
var old_y = y;
while (y > 0) : (y /= 10) {
    result *= 10;
}
result += old_y;
```

Both has around the same performance, so I opted for the ~cooler~ shorter one. The code for part two itself is almost the same as part one, with the only difference being the addition of `.cat` in the `operators` array. Just like in the previous day, an optional optimization here is to check the equations in parallel.

```zig
fn part2(self: Self) u64 {
    var result: u64 = 0;
    for (self.results, 0..) |answer, i| {
        const operators = [_]Operator{ .add, .mul, .cat };
        if (is_valid_equation(answer, &self.operands[i], &operators)) {
            result += answer;
        }
    }
    return result;
}
```

## Benchmarks
