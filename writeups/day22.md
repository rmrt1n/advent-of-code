# Day 22: Monkey Market

[Full solution](../src/days/day22.zig).

## Puzzle Input

Today's input is a list of buyers' **secret numbers**:

```plaintext
1
10
100
2024
```

We'll parse this into an array:

```zig
fn Day22(length: usize) type {
    return struct {
        const Self = @This();

        numbers: [length]u64 = undefined,

        fn init(data: []const u8) !Self {
            var result = Self{};

            var i: usize = 0;
            var lexer = std.mem.tokenizeScalar(u8, data, '\n');
            while (lexer.next()) |line| : (i += 1) {
                result.numbers[i] = try std.fmt.parseInt(u64, line, 10);
            }

            return result;
        }
    };
}
```

## Part One

We need to calculate the sum of the **2000th secret number** of each buyer. A secret number "evolves" through a series of transformations. Each transformation follows these steps:

1. Multiply the secret number by 64, mix the result into it, then prune the result.
2. Divide the secret number by 32, round the result down, mix it into the secret number, then prune the result.
3. Multiply the secret number by 2048, mix the result into the secret number, then prune the result.

Where:

1. **Mixing** a value into the secret number means setting it to the XOR of the given value and the current secret number.
2. **Pruning** the secret number means to modulo it with 16,777,216.

We'll translate these steps into a function to compute the next secret number:

```zig
fn next(secret_number: u64) u64 {
    var result = secret_number;
    result ^= (result * 64) % 16777216;
    result ^= (result / 32) % 16777216;
    result ^= (result * 2048) % 16777216;
    return result;
}
```

Now we'll call this 2000 times for each secret number in the input and sum them all up:

```zig
fn part1(self: Self) u64 {
    var result: u64 = 0;
    for (self.numbers) |secret_number| {
        var next_secret_number = secret_number;
        for (0..2000) |_| {
            next_secret_number = next(next_secret_number);
        }
        result += next_secret_number;
    }
    return result;
}
```

## Part Two

We need to count the **maximum number of bananas** we can get.

There are new rules to this puzzle that we have to keep in mind:

1. We have a monkey that sells hiding spots in exchange for bananas.
2. For each secret number, the price (bananas) a buyer offers is the last digit of the secret number.
3. Across 2000 iterations of the secret number, the monkey only sees the changes in price, e.g. with an initial secret number of 123, here are the buyer's first ten secret numbers, prices, and associated changes:

    ```plaintext
             123: 3
        15887950: 0 (-3)
        16495136: 6 (6)
          527345: 5 (-1)
          704524: 4 (-1)
         1553684: 4 (0)
        12683156: 6 (2)
        11100544: 4 (-2)
        12249484: 4 (0)
         7753432: 2 (-2)
    ```

    The monkey sees in sequences of four price changes. We want to sell at the highest price (6 in this case), so we tell the monkey to sell on the sequence `-1,-1,0,2`.
4. The monkey must sell at the first occurrence of the given sequence.
5. The monkey can only remember 1 sequence, and must use it for all buyers in the input.



To get the best sequence, we'll find all possible sequences and build a mapping from each sequence to its total number of bananas across all buyers. In the end, the sequence with the most bananas is our answer.

We could represent a sequence using an array `[4]i8`, which works but isn’t very efficient. Instead, we'll use a more compact representation. A price change can have only 19 possible values, from -9 to 9.  We can represent a sequence as a 4-digit base 19 number. The largest possible value is `iiii` (130,320 in decimal), which fits inside a 24-bit integer `u24`.

Now for the solution. We'll iterate over every secret number. For each, we'll create a price list for every secret number evolution. Then we'll iterate over this price list using a sliding window of 4 elements (the size of a sequence). If we have seen the sequence before, we'll skip it. Else, we add the price to the map. In the end, we'll take the largest count in the map.

Here's the code:

```zig
fn part2(self: Self) u64 {
    const sequences_capacity = comptime std.math.pow(u32, 19, 4);
    var sequences = [_]u24{0} ** sequences_capacity;
    var seen_sequences: [sequences_capacity]u16 = undefined;

    var prices: [2001]u8 = undefined; // 1 original + 2000 generations

    for (self.numbers, 0..) |secret_number, i| {
        prices[0] = @intCast(secret_number % 10);

        var next_secret_number = secret_number;
        for (1..2001) |j| {
            next_secret_number = next(next_secret_number);
            prices[j] = @intCast(next_secret_number % 10);
        }

        var j: usize = 1;
        while (j < 2001 - 3) : (j += 1) {
            var key: u24 = 0;
            for (0..4) |k| {
                const diff = @as(i16, prices[j + k]) - prices[j + k - 1];
                key = key * 18 + @as(u8, @intCast(diff + 9));
            }

            // Saves around 15ms by not zeroing out the array.
            if (seen_sequences[key] == i) continue;

            seen_sequences[key] = @intCast(i);
            sequences[key] += prices[j + 3];
        }
    }

    return std.mem.max(u24, &sequences);
}
```

> [!NOTE]
> `seen_sequences` is a set that tracks whether a sequence has already been used by a buyer, since the monkey only sells at the first occurrence. The above uses a not-so-straightforward optimisation, so I'll explain here.
>
> The straightforward thing to do here is to create a separate set for each buyer, e.g.:
>
> ```zig
> for (self.numbers, 0..) |secret_number, i| {
>     var seen_sequences = [_]bool{ false } ** sequences_capacity;
>     while (j < 2001 - 3) : (j += 1) {
>         if (seen_sequences[key]) continue;
>         seen_sequences[key] = true;
>     }
> }
> ```
> Instead, we keep a map of each sequence to the last iteration it was seen. If the stored value matches the current iteration, it means we've already seen it so we can skip it:
> 
> ```zig
> var seen_sequences: [sequences_capacity]u16 = undefined;
> for (self.numbers, 0..) |secret_number, i| {
>     while (j < 2001 - 3) : (j += 1) {
>         if (seen_sequences[key]) continue;
>         seen_sequences[key] = true;
>     }
> }
> ```
> This improves performance by not having to recreate the array each iteration.

> [!TIP]
> The capacity of `sequence` is `iiii + 1`, so that we can index by `iiii`. In general, for any base $b$ and digit count $d$, the total number of representable values is $b^d$. In our case, this value is $19^4$.

## Benchmark

All benchmarks were performed on an [Apple M3 Pro](https://en.wikipedia.org/wiki/Apple_M3) with times in microseconds (µs).

| Debug | ReleaseSafe | ReleaseFast | ReleaseSmall |
| ----- | ----------- | ----------- | ------------ |
|       |             |             |              |
