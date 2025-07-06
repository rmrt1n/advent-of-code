# Day 13: Claw Contraption

[Full solution](../src/days/day13.zig).

## Puzzle Input

Today's input is a list of **claw machines**:

```plaintext
Button A: X+94, Y+34
Button B: X+22, Y+67
Prize: X=8400, Y=5400

Button A: X+26, Y+66
Button B: X+67, Y+21
Prize: X=12748, Y=12176

Button A: X+17, Y+86
Button B: X+84, Y+37
Prize: X=7870, Y=6450

Button A: X+69, Y+23
Button B: X+27, Y+71
Prize: X=18641, Y=10279
```

Each claw machine has two buttons, **A** and **B**, which move the claw in the directions specified, and a prize with its location given.

We'll parse the input into three arrays, two for each button and one for the prizes:

```zig
fn Day13(length: usize) type {
    return struct {
        const Self = @This();

        buttons_a: [length][2]u8 = undefined,
        buttons_b: [length][2]u8 = undefined,
        prizes: [length][2]i64 = undefined,

        fn init(input: []const u8) !Self {
            var result = Self{};

            var i: usize = 0;
            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                result.buttons_a[i][0] = try std.fmt.parseInt(u8, line[12..14], 10);
                result.buttons_a[i][1] = try std.fmt.parseInt(u8, line[18..], 10);

                var new_line = lexer.next().?;
                result.buttons_b[i][0] = try std.fmt.parseInt(u8, new_line[12..14], 10);
                result.buttons_b[i][1] = try std.fmt.parseInt(u8, new_line[18..], 10);

                new_line = lexer.next().?;
                var inner_lexer = std.mem.tokenizeScalar(u8, new_line, ' ');
                _ = inner_lexer.next().?; // Skip 'Prize: '

                new_line = inner_lexer.next().?;
                result.prizes[i][0] = try std.fmt.parseInt(i64, new_line[2 .. new_line.len - 1], 10);

                new_line = inner_lexer.next().?;
                result.prizes[i][1] = try std.fmt.parseInt(i64, new_line[2..new_line.len], 10);
            }

            return result;
        }
    };
}
```

## Part One

We need to count the **fewest tokens** needed to win all possible prizes. Button A requires 3 tokens to press while button B requires only 1.

We can use basic algebra to solve today's problem. First, we'll define some variables. Let:

- $(X_A, Y_A)$ be the vector for button A.
- $(X_B, Y_B)$ be the vector for button B.
- $(X_P, Y_P)$ be the coordinate of the prize.
- $n$ be the number of times button A is pressed.
- $m$ be the number of times button B is pressed.

Each claw machine can be described by these two equations:

1. $nX_A + mX_B = X_P$
2. $nY_A + mY_B = Y_P$

Then, we'll find the equations for $n$ and $m$. We'll do $n$ first as an example:

1. We'll start with the equations for $m$:
    $$m = \frac{X_P - nX_A}{X_B} = \frac{Y_P - nY_A}{Y_B}$$
2. Cross-multiply to eliminate the denominators:
    $$X_PY_P - nX_AY_B = Y_PX_B - nY_AX_B$$
3. This can be rearranged into:
    $$nY_aX_b - nX_aY_b = Y_pX_b - X_pY_b$$
4. Factor out $n$:
    $$n \cdot (Y_AX_B - X_AY_B) = Y_PX_B - X_PY_B$$
5. Solve for $n$:
    $$n = \frac{Y_PX_B - X_PY_B}{Y_AX_B - X_AY_B}$$

You can derive the equation for $m$ in the same way. You should end up with:

$$m = \frac{Y_PX_A - X_PY_A}{X_AY_B - Y_AX_B}$$

We'll implement this into a function that computes the minimum presses needed to reach a prize. Since the formulas for $n$ and $m$ are symmetrical, we don't need separate functions—we can simply swap the button order passed to the function:

```zig
fn count_tokens(a: [2]u8, b: [2]u8, p: [2]i64) ?u64 {
    const numerator = @abs(p[0] * b[1] - p[1] * b[0]);
    const denumerator = @abs(@as(i32, a[0]) * b[1] - @as(i32, a[1]) * b[0]);
    return if (numerator % denumerator != 0) null else numerator / denumerator;
}
```

There are cases where it's not possible to reach a prize. In such cases, we'll return a `null`.

Now for the solution. We'll iterate over all of the claw machines, calculate the minimum presses for each button, and convert these into tokens (button A costs 3 tokens). We'll add this to the total to get the answer:

```zig
fn part1(self: Self) u64 {
    var result: usize = 0;
    for (self.buttons_a, self.buttons_b, self.prizes) |button_a, button_b, prize| {
        const tokens_a = count_tokens(button_a, button_b, prize);
        const tokens_b = count_tokens(button_b, button_a, prize);
        if (tokens_a == null or tokens_b == null) continue;
        result += tokens_a.? * 3 + tokens_b.?;
    }
    return result;
}
```

## Part Two

We still need to count the minimum tokens, but this time the prize locations are shifted by **10,000,000,000,000** along both axes.

Our part one logic still works for part two. We only have to adjust the prize locations:

```zig
fn part2(self: Self) u64 {
    var result: u64 = 0;
    for (self.buttons_a, self.buttons_b, self.prizes) |button_a, button_b, old_prize| {
        const prize = .{ old_prize[0] + 10_000_000_000_000, old_prize[1] + 10_000_000_000_000 };
        const tokens_a = count_tokens(button_a, button_b, prize);
        const tokens_b = count_tokens(button_b, button_a, prize);
        if (tokens_a == null or tokens_b == null) continue;
        result += tokens_a.? * 3 + tokens_b.?;
    }
    return result;
}
```

## Benchmark

All benchmarks were performed on an [Apple M3 Pro](https://en.wikipedia.org/wiki/Apple_M3) with times in microseconds (µs).

| Debug | ReleaseSafe | ReleaseFast | ReleaseSmall |
| ----- | ----------- | ----------- | ------------ |
|       |             |             |              |
