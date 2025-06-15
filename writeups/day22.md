# Day 22: Monkey Market

[Full solution](../src/days/day22.zig).

## Part one

Day 22 was pretty straightforward, a bit unexpected after I spent hours on day 21 but didn't get the solution until a few days later. We're given a list of numbers:

```
1
10
100
2024
```

Each line of the input is a banana buyer's initial **secret number**. For part one, we have to generate the 2000th secret number for each of the initial secret number in the input, then get the sum. The solution is pretty straightforward so let's parse the input first:

```zig
fn Day22(length: usize) type {
    return struct {
        numbers: [length]u64 = undefined,

        const Self = @This();

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

The formula to get the next secret number is:

1. Multiply the secret number by 64. Then, mix this result into the secret number. Finally, prune the secret number.
2. Divide the secret number by 32. Round the result down to the nearest integer. Then, mix this result into the secret number. Finally, prune the secret number.
3. Multiply the secret number by 2048. Then, mix this result into the secret number. Finally, prune the secret number.

Where:

1. To mix a value into the secret number is to set the secret number to the XOR of the given value with the secret number.
2. To prune the secret number is to modulo it with 16777216.

Translated to Zig:

```zig
fn next(secret_number: u64) u64 {
    var result = secret_number;
    result ^= (result * 64) % 16777216;
    result ^= (result / 32) % 16777216;
    result ^= (result * 2048) % 16777216;
    return result;
}
```

Then, we just have to call this function 2000 times and sum all of them to get the answer to part one:

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

## Part two

In part two, we have to read the puzzle description a little more carefully.

Now:

1. We have a monkey that have to sell bananas to each buyer.
2. For each secret number, the price the buyer offers is the last digit of the secret number.
3. From the 2000 iterations of the secret number, the monkey only sees the changes in price, e.g. with an initial secret number of 123, the buyer's first ten secret numbers, prices, and the associated changes would be:

    ```
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

    The monkey sees in sequences of four price changes. We want to sell with the highest price possible (which is 6 here), we have to tell the monky to sell on the sequence `-1,-1,0,2`.
4. The monkey has to sell at the first occurence of the given sequence.
4. The monkey can only remember 1 sequence across all of the buyers in the puzzle input.

For part two, we have to find the most bananas we can get. The number of bananas we get per buyer is the price we sold at. To do this, we have to find the one sequence that will result in the most profit.

The approach I took here was to use a mapping of sequence to the total bananas received across all buyers. Then, get the max number from all of the sequences.

My original solution uses a `std.AutohashMap([4]i16, u32)` to store this mapping. This works but is not very efficient. We can improve this by changing how we represent the sequence. There are only 19 possible values of the price change from -9 to 9. A cool trick here is that we can store the sequence as a base 19 integer.

This combines the bitmask trick from day 6 and the base 8 trick from day 17. We'll represent each price change as a digit in the base 19 number. `-1` is `0`, `-2` is `1`, all the way to `9` which is `i`. I modified the base 16 (hexadecimal ) representation for base 19, with the added characters `g`, `h`, `i`.

Here's an example to illustrate. I'll use the sequence `-2, 0, 3, 9`. In base 19 this becomes `19ci`. In base 19, digit-related operations like division and modulo uses 19 instead of the usual 10 in base 10. Note, if the sequence starts with `-1`, it becomes a 3 digit base 19 number since it has a leading zero.

Okay, now let's get to the solution:

```zig
fn part2(self: Self) u64 {
    var sequences = [_]u32{0} ** std.math.pow(u32, 19, 4);
    var seen_sequences: [std.math.pow(u32, 19, 4)]u16 = undefined;

    for (self.numbers, 0..) |secret_number, i| {
        var prices: [2001]u8 = undefined;
        prices[0] = @intCast(secret_number % 10);
        var next_secret_number = secret_number;
        for (1..2001) |j| {
            next_secret_number = next(next_secret_number);
            prices[j] = @intCast(next_secret_number % 10);
        }

        var j: usize = 1;
        while (j < 2001 - 3) : (j += 1) {
            var key: u32 = 0;
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

    return std.mem.max(u32, &sequences);
}
```

There's the sequence -> banana count mapping `sequences`. I used an array with a size of $19^4$, which is `10000` in base 19. This is just enough to store the largest sequence possible `9,9,9,9`, which is `iiii` in base 19.

For each buyer, the first thing we do is to store the prices for every iteration of the secret number. We'll do this first since we need to calculate the difference between two prices.

We also have another array `seen_sequences` to keep track of whether we have seen the sequence previously in the current buyer. We need this because the monkey will sell at the first instance of a sequence, so if we encounter it again we have to skip it. This is a bit less straightforward than a regular approach, so here's an explanation:

Instead of doing something like this where we create a new `seen_sequences` each iteration:

```zig
for (self.numbers, 0..) |secret_number, i| {
    var seen_sequences = [_]bool{ false } ** std.math.pow(u32, 19, 4);
    while (j < 2001 - 3) : (j += 1) {
        if (seen_sequences[key]) continue;
        seen_sequences[key] = true;
    }
}
```

We can use a "global" `seen_sequences` where each iteration we just set it to `i`. If the current value is `seen_sequences` is the same as our current iteration, it means we have seen it before so we just continue:

```zig
var seen_sequences: [std.math.pow(u32, 19, 4)]u16 = undefined;
for (self.numbers, 0..) |secret_number, i| {
    while (j < 2001 - 3) : (j += 1) {
        if (seen_sequences[key]) continue;
        seen_sequences[key] = true;
    }
}
```

This removes the need to zero out the array each time which adds up to the compute time. The rest of the function just follows the puzzle instructions to get sequence banana counts. After we get the price list, we iterate over it in windows of four. Here's the part where we convert the window into a base 19 number:

```zig
while (j < 2001 - 3) : (j += 1) {
    var key: u32 = 0;
    for (0..4) |k| {
        const diff = @as(i16, prices[j + k]) - prices[j + k - 1];
        key = key * 18 + @as(u8, @intCast(diff + 9));
    }
    // ...
}
```

If we haven't seen the sequence before, we get the banana count (`prices[j + 3]`) and add it to the total banana count for that particular sequence. After we went through all buyers, we find the max banana count from `sequences` as the answer for part two.

## Benchmarks
