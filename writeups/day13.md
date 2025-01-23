# Day 13: Claw Contraption

[Full solution](../src/days/day13.zig).

## Part one

Day 13 looks like a lanternfish puzzle but it is actually math problem in disguise. We're given a list of claw machine configuration as our puzzle input:

```
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

There are two buttons, A and B. Each button requires **tokens** to push, with A requiring three tokens and B one token. Each section of the input describes the machine configuration. For example, the first machine's button A moves 94 units in the X axis and 34 unit in the Y axis when pushed. The prize is located at the coordinates (8400, 5400).

For part one, we have to find the cheapest way to get the prize (using the fewest number of tokens). There are also machines where it's not possible to get the prize, which we'll just ignore.

To solve this, we can do a bit of maths. For each claw machine, we can write these equations:

1. $nX_a + mX_b = X_p$
2. $nY_a + mY_b = Y_p$

Where $n$ is the number of button A presses and $m$ is the number of button B presses. $X_p$ and $Y_p$ are the coordinates of the prize. With these, we have to find the equations for $n$ and $m$, since if we know the number of presses needed for each button we'll also know how many tokens is needed. We can get $n$ by:

1. Start with the equations for $m$:

$$
m = \frac{X_p - nX_a}{X_b} = \frac{Y_p - nY_a}{Y_b}
$$

2. Simplify into:

$$
X_pY_b - nX_aY_b = Y_pX_b - nY_aX_b
$$

3. Which can be rewritten as:

$$
nY_aX_b - nX_aY_b = Y_pX_b - X_pY_b
$$

4. Simplify into:

$$
n \cdot (Y_aX_b - X_aY_b) = Y_pX_b - X_pY_b
$$

5. And finally we get:

$$
n = \frac{Y_pX_b - X_pY_b}{Y_aX_b - X_aY_b}
$$

We can do the same with $m$ to get:

$$
m = \frac{Y_pX_a - X_pY_a}{X_aY_b - Y_aX_b}
$$

We can implement this as a `count_tokens` function that will return either $n$ or $m$. We don't have to implement two different functions here because if you swap the A coordinates in the eqation for $n$, you'll get the equation for $m$. There are also cases where it is not possible to get the prize. We can detect this by checking if $n$ or $m$ is an integer.

```zig
fn count_tokens(a: [2]u8, b: [2]u8, p: [2]i64) ?u64 {
    const numerator = @abs(p[0] * b[1] - p[1] * b[0]);
    const denumerator = @abs(@as(i32, a[0]) * b[1] - @as(i32, a[1]) * b[0]);
    return if (numerator % denumerator != 0) null else numerator / denumerator;
}
```

Here, we'll return `null` if the result isn't an integer by checking the remainder of the division. To solve part one, we just have to apply this function to every machine in the puzzle input and count the number of tokens:

```zig
fn part1(self: Self) u64 {
    var result: usize = 0;
    for (0..self.prizes.len) |i| {
        const prize = .{ self.prizes[i][0], self.prizes[i][1] };
        const tokens_a = count_tokens(self.buttons_a[i], self.buttons_b[i], prize);
        const tokens_b = count_tokens(self.buttons_b[i], self.buttons_a[i], prize);
        if (tokens_a == null or tokens_b == null) continue;
        result += tokens_a.? * 3 + tokens_b.?;
    }
    return result;
}
```

## Part two

There isn't big twist for part two. Now, the position of the prizes is actually higher by 10,000,000,000,000. We can reuse almost all of our part one code. The one change we'll need is to increment the prize coordinates by 10,000,000,000,000 in each iteration. Since we used `u64` in the `count_tokens` function, we don't have to refactor it to avoid integer overflows:

```zig
fn part2(self: Self) u64 {
    var result: u64 = 0;
    for (0..self.prizes.len) |i| {
        const prize = .{
            self.prizes[i][0] + 10_000_000_000_000,
            self.prizes[i][1] + 10_000_000_000_000,
        };
        const tokens_a = count_tokens(self.buttons_a[i], self.buttons_b[i], prize);
        const tokens_b = count_tokens(self.buttons_b[i], self.buttons_a[i], prize);
        if (tokens_a == null or tokens_b == null) continue;
        result += tokens_a.? * 3 + tokens_b.?;
    }
    return result;
}
```

## Benchmarks
