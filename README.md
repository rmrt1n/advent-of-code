# Advent of Code

This repo contains my solutions for [Advent of Code](https://adventofcode.com). Each solution includes a short write-up explaining my approach.

So far I've only done 2024, in Zig. I might do other years in other languages later, or I might not.

Also see the accompanying [blog post](https://ryanmartin.me/articles/aoc2024-zig).

## Solutions

Each day links to the source code and the accompanying write-up.


| Day | Title                                                          | Solution                     | Write up                        | Benchmark (ReleaseFast, µs) |
| --- | -------------------------------------------------------------- | ---------------------------- | ------------------------------- |---------------------------: |
|  1  | [Historian Hysteria](https://adventofcode.com/2024/day/1)      | [Code](./src/days/day01.zig) | [Write up](./writeups/day01.md) | 41.8                        |
|  2  | [Red-Nosed Reports](https://adventofcode.com/2024/day/2)       | [Code](./src/days/day02.zig) | [Write up](./writeups/day02.md) | 54.4                        |
|  3  | [Mull it Over](https://adventofcode.com/2024/day/3)            | [Code](./src/days/day03.zig) | [Write up](./writeups/day03.md) | 23.2                        |
|  4  | [Ceres Search](https://adventofcode.com/2024/day/4)            | [Code](./src/days/day04.zig) | [Write up](./writeups/day04.md) | 5.9                         |
|  5  | [Print Queue](https://adventofcode.com/2024/day/5)             | [Code](./src/days/day05.zig) | [Write up](./writeups/day05.md) | 26.9                        |
|  6  | [Guard Gallivant](https://adventofcode.com/2024/day/6)         | [Code](./src/days/day06.zig) | [Write up](./writeups/day06.md) | 24,370.7                    |
|  7  | [Bridge Repair](https://adventofcode.com/2024/day/7)           | [Code](./src/days/day07.zig) | [Write up](./writeups/day07.md) | 10,014.7                    |
|  8  | [Resonant Collinearity](https://adventofcode.com/2024/day/8)   | [Code](./src/days/day08.zig) | [Write up](./writeups/day08.md) | 19.4                        |
|  9  | [Disk Fragmenter](https://adventofcode.com/2024/day/9)         | [Code](./src/days/day09.zig) | [Write up](./writeups/day09.md) | 151.7                       |
| 10  | [Hoof It](https://adventofcode.com/2024/day/10)                | [Code](./src/days/day10.zig) | [Write up](./writeups/day10.md) | 59.9                        |
| 11  | [Plutonian Pebbles](https://adventofcode.com/2024/day/11)      | [Code](./src/days/day11.zig) | [Write up](./writeups/day11.md) | 2,159.1                     |
| 12  | [Garden Groups](https://adventofcode.com/2024/day/12)          | [Code](./src/days/day12.zig) | [Write up](./writeups/day12.md) | 420.3                       |
| 13  | [Claw Contraption](https://adventofcode.com/2024/day/13)       | [Code](./src/days/day13.zig) | [Write up](./writeups/day13.md) | 14.7                        |
| 14  | [Restroom Redoubt](https://adventofcode.com/2024/day/14)       | [Code](./src/days/day14.zig) | [Write up](./writeups/day14.md) | 13.7                        |
| 15  | [Warehouse Woes](https://adventofcode.com/2024/day/15)         | [Code](./src/days/day15.zig) | [Write up](./writeups/day15.md) | 701.5                       |
| 16  | [Reindeer Maze](https://adventofcode.com/2024/day/16)          | [Code](./src/days/day16.zig) | [Write up](./writeups/day16.md) | 11,504.1                    |
| 17  | [Chronospatial Computer](https://adventofcode.com/2024/day/17) | [Code](./src/days/day17.zig) | [Write up](./writeups/day17.md) | 44.8                        |
| 18  | [RAM Run](https://adventofcode.com/2024/day/18)                | [Code](./src/days/day18.zig) | [Write up](./writeups/day18.md) | 85.2                        |
| 19  | [Linen Layout](https://adventofcode.com/2024/day/19)           | [Code](./src/days/day19.zig) | [Write up](./writeups/day19.md) | 23,810.2                    |
| 20  | [Race Condition](https://adventofcode.com/2024/day/20)         | [Code](./src/days/day20.zig) | [Write up](./writeups/day20.md) | 157.4                       |
| 21  | [Keypad Conundrum](https://adventofcode.com/2024/day/21)       | [Code](./src/days/day21.zig) | [Write up](./writeups/day21.md) | 24.2                        |
| 22  | [Monkey Market](https://adventofcode.com/2024/day/22)          | [Code](./src/days/day22.zig) | [Write up](./writeups/day22.md) | 11,248.4                    |
| 23  | [LAN Party](https://adventofcode.com/2024/day/23)              | [Code](./src/days/day23.zig) | [Write up](./writeups/day23.md) | 38.2                        |
| 24  | [Crossed Wires](https://adventofcode.com/2024/day/24)          | [Code](./src/days/day24.zig) | [Write up](./writeups/day24.md) | 60.7                        |
| 25  | [Code Chronicle](https://adventofcode.com/2024/day/25)         | [Code](./src/days/day25.zig) | [Write up](./writeups/day25.md) | 24.9                        |

## Benchmarks

Benchmarks are done on a [Apple M3 Pro](https://en.wikipedia.org/wiki/Apple_M3) using [this bash script](./bench.sh). Each puzzle has separate measurements for parsing, part 1, and part 2.

### Optimize mode: Debug

**Total runtime**: 1,242.9 ms.

<details>
<summary>Benchmarks</summary>

| Day | Title                  | Parsing (µs) | Part 1 (µs) | Part 2 (µs) | Total (µs)     |
| --- | ---------------------- | -----------: | ----------: | ----------: | -------------: |
|  1  | Historian Hysteria     | 361.4        | 256.9       | 8.1         | **626.4**      |
|  2  | Red-Nosed Reports      | 598.2        | 33.8        | 91.2        | **723.2**      |
|  3  | Mull it Over           | 0.0          | 110.3       | 119.7       | **230.1**      |
|  4  | Ceres Search           | 67.7         | 4,849.7     | 1,093.7     | **6,011.2**    |
|  5  | Print Queue            | 361.5        | 8.8         | 95.1        | **465.4**      |
|  6  | Guard Gallivant        | 124.8        | 77.3        | 104,955.0   | **105,157.1**  |
|  7  | Bridge Repair          | 730.0        | 2,921.5     | 140,020.8   | **143,672.3**  |
|  8  | Resonant Collinearity  | 54.2         | 90.3        | 383.5       | **528.0**      |
|  9  | Disk Fragmenter        | 49.1         | 125.1       | 1,434.8     | **1,609.1**    |
| 10  | Hoof It                | 25.1         | 409.9       | 252.0       | **686.9**      |
| 11  | Plutonian Pebbles      | 1.0          | 933.6       | 32,657.6    | **33,592.2**   |
| 12  | Garden Groups          | 67.6         | 1,224.6     | 1,794.9     | **3,087.2**    |
| 13  | Claw Contraption       | 256.6        | 7.1         | 7.1         | **270.8**      |
| 14  | Restroom Redoubt       | 247.0        | 9.9         | 114,785.9   | **115,042.7**  |
| 15  | Warehouse Woes         | 311.0        | 634.5       | 1,103.9     | **2,049.4**    |
| 16  | Reindeer Maze          | 153.9        | 15,397.6    | 48,751.2    | **64,302.7**   |
| 17  | Chronospatial Computer | 1.6          | 1.2         | 290.5       | **293.3**      |
| 18  | RAM Run                | 592.9        | 326.8       | 437.6       | **1,357.3**    |
| 19  | Linen Layout           | 127.0        | 207,814.8   | 207,684.8   | **415,626.6**  |
| 20  | Race Condition         | 325.1        | 2,164.6     | 93,134.5    | **95,624.2**   |
| 21  | Keypad Conundrum       | 0.7          | 41.4        | 566.2       | **608.2**      |
| 22  | Monkey Market          | 319.0        | 79,065.1    | 168,422.9   | **247,807.0**  |
| 23  | LAN Party              | 143.4        | 523.9       | 11.4        | **678.7**      |
| 24  | Crossed Wires          | 79.3         | 1,615.4     | 262.1       | **1,956.9**    |
| 25  | Code Chronicle         | 696.7        | 189.1       | 0.0         | **885.9**      |

</details>

### Optimize mode: ReleaseSafe

**Total runtime**: 146.1 ms.

<details>
<summary>Benchmarks</summary>

| Day | Title                  | Parsing (µs) | Part 1 (µs) | Part 2 (µs) | Total (µs)     |
| --- | ---------------------- | -----------: | ----------: | ----------: | -------------: |
|  1  | Historian Hysteria     | 24.5         | 18.5        | 2.9         | **46.0**       |
|  2  | Red-Nosed Reports      | 55.4         | 4.5         | 15.5        | **75.4**       |
|  3  | Mull it Over           | 0.0          | 9.4         | 14.2        | **23.6**       |
|  4  | Ceres Search           | 6.7          | 41.8        | 21.4        | **69.9**       |
|  5  | Print Queue            | 22.5         | 1.2         | 6.0         | **29.7**       |
|  6  | Guard Gallivant        | 20.2         | 12.3        | 13,156.5    | **13,189.0**   |
|  7  | Bridge Repair          | 67.4         | 437.4       | 12,760.7    | **13,265.5**   |
|  8  | Resonant Collinearity  | 3.3          | 4.5         | 18.5        | **26.3**       |
|  9  | Disk Fragmenter        | 6.8          | 25.4        | 234.3       | **266.5**      |
| 10  | Hoof It                | 3.4          | 42.7        | 37.7        | **83.8**       |
| 11  | Plutonian Pebbles      | 0.1          | 47.8        | 2,548.1     | **2,596.1**    |
| 12  | Garden Groups          | 6.9          | 258.1       | 368.4       | **633.5**      |
| 13  | Claw Contraption       | 18.8         | 0.9         | 0.9         | **20.5**       |
| 14  | Restroom Redoubt       | 15.2         | 2.0         | 20,863.8    | **20,881.1**   |
| 15  | Warehouse Woes         | 77.5         | 212.3       | 461.0       | **750.7**      |
| 16  | Reindeer Maze          | 49.2         | 4,676.7     | 15,408.5    | **20,134.4**   |
| 17  | Chronospatial Computer | 0.1          | 0.2         | 42.0        | **42.3**       |
| 18  | RAM Run                | 43.3         | 23.5        | 62.6        | **129.4**      |
| 19  | Linen Layout           | 11.4         | 12,983.8    | 12,979.9    | **25,975.1**   |
| 20  | Race Condition         | 56.0         | 427.5       | 25,316.8    | **25,800.4**   |
| 21  | Keypad Conundrum       | 0.1          | 2.7         | 33.0        | **35.7**       |
| 22  | Monkey Market          | 22.7         | 5,660.8     | 16,055.8    | **21,739.4**   |
| 23  | LAN Party              | 16.6         | 25.3        | 2.6         | **44.5**       |
| 24  | Crossed Wires          | 8.4          | 91.7        | 16.8        | **116.9**      |
| 25  | Code Chronicle         | 45.2         | 66.8        | 0.0         | **112.1**      |

</details>

### Optimize mode: ReleaseFast

**Total runtime**: 85.1 ms.

<details open>
<summary>Benchmarks</summary>

| Day | Title                  | Parsing (µs) | Part 1 (µs) | Part 2 (µs) | Total (µs)     |
| --- | ---------------------- | -----------: | ----------: | ----------: | -------------: |
|  1  | Historian Hysteria     | 23.5         | 15.5        | 2.8         | **41.8**       |
|  2  | Red-Nosed Reports      | 42.9         | 0.0         | 11.5        | **54.4**       |
|  3  | Mull it Over           | 0.0          | 7.2         | 16.0        | **23.2**       |
|  4  | Ceres Search           | 5.9          | 0.0         | 0.0         | **5.9**        |
|  5  | Print Queue            | 22.3         | 0.0         | 4.6         | **26.9**       |
|  6  | Guard Gallivant        | 14.0         | 25.2        | 24,331.5    | **24,370.7**   |
|  7  | Bridge Repair          | 72.6         | 321.4       | 9,620.7     | **10,014.7**   |
|  8  | Resonant Collinearity  | 2.7          | 3.3         | 13.4        | **19.4**       |
|  9  | Disk Fragmenter        | 0.8          | 12.9        | 137.9       | **151.7**      |
| 10  | Hoof It                | 2.2          | 29.9        | 27.8        | **59.9**       |
| 11  | Plutonian Pebbles      | 0.1          | 43.8        | 2,115.2     | **2,159.1**    |
| 12  | Garden Groups          | 6.8          | 164.4       | 249.0       | **420.3**      |
| 13  | Claw Contraption       | 14.7         | 0.0         | 0.0         | **14.7**       |
| 14  | Restroom Redoubt       | 13.7         | 0.0         | 0.0         | **13.7**       |
| 15  | Warehouse Woes         | 14.6         | 228.5       | 458.3       | **701.5**      |
| 16  | Reindeer Maze          | 12.6         | 2,480.8     | 9,010.7     | **11,504.1**   |
| 17  | Chronospatial Computer | 0.1          | 0.2         | 44.5        | **44.8**       |
| 18  | RAM Run                | 35.6         | 15.8        | 33.8        | **85.2**       |
| 19  | Linen Layout           | 10.7         | 11,890.8    | 11,908.7    | **23,810.2**   |
| 20  | Race Condition         | 48.7         | 54.5        | 54.2        | **157.4**      |
| 21  | Keypad Conundrum       | 0.0          | 1.7         | 22.4        | **24.2**       |
| 22  | Monkey Market          | 20.7         | 0.0         | 11,227.7    | **11,248.4**   |
| 23  | LAN Party              | 13.6         | 22.0        | 2.5         | **38.2**       |
| 24  | Crossed Wires          | 5.0          | 41.3        | 14.3        | **60.7**       |
| 25  | Code Chronicle         | 24.9         | 0.0         | 0.0         | **24.9**       |

</details>

### Optimize mode: ReleaseSmall

**Total runtime**: 139.35 ms.

<details>
<summary>Benchmarks</summary>

| Day | Title                  | Parsing (µs) | Part 1 (µs) | Part 2 (µs) | Total (µs)     |
| --- | ---------------------- | -----------: | ----------: | ----------: | -------------: |
|  1  | Historian Hysteria     | 30.1         | 17.8        | 2.6         | **50.6**       |
|  2  | Red-Nosed Reports      | 59.2         | 3.3         | 14.4        | **76.8**       |
|  3  | Mull it Over           | 0.0          | 15.4        | 20.7        | **36.1**       |
|  4  | Ceres Search           | 6.8          | 634.8       | 118.4       | **760.0**      |
|  5  | Print Queue            | 30.5         | 1.0         | 6.1         | **37.5**       |
|  6  | Guard Gallivant        | 14.8         | 34.1        | 26,542.4    | **26,591.4**   |
|  7  | Bridge Repair          | 93.2         | 886.4       | 26,021.9    | **27,001.5**   |
|  8  | Resonant Collinearity  | 4.5          | 6.7         | 28.2        | **39.3**       |
|  9  | Disk Fragmenter        | 6.2          | 15.6        | 149.0       | **170.8**      |
| 10  | Hoof It                | 3.0          | 51.9        | 37.7        | **92.6**       |
| 11  | Plutonian Pebbles      | 0.1          | 68.2        | 2,797.4     | **2,865.7**    |
| 12  | Garden Groups          | 7.8          | 189.2       | 252.5       | **449.4**      |
| 13  | Claw Contraption       | 20.5         | 0.0         | 0.0         | **20.5**       |
| 14  | Restroom Redoubt       | 39.1         | 0.1         | 1,358.3     | **1,397.5**    |
| 15  | Warehouse Woes         | 16.6         | 257.4       | 503.1       | **777.1**      |
| 16  | Reindeer Maze          | 46.9         | 2,665.8     | 9,338.2     | **12,050.9**   |
| 17  | Chronospatial Computer | 0.2          | 0.3         | 69.1        | **69.6**       |
| 18  | RAM Run                | 71.7         | 25.2        | 43.0        | **139.9**      |
| 19  | Linen Layout           | 21.8         | 25,477.8    | 25,483.3    | **50,982.9**   |
| 20  | Race Condition         | 60.2         | 65.2        | 66.2        | **191.7**      |
| 21  | Keypad Conundrum       | 0.1          | 2.1         | 27.9        | **30.1**       |
| 22  | Monkey Market          | 23.6         | 0.0         | 15,141.3    | **15,164.8**   |
| 23  | LAN Party              | 11.2         | 42.8        | 2.6         | **56.6**       |
| 24  | Crossed Wires          | 10.4         | 204.6       | 23.2        | **238.1**      |
| 25  | Code Chronicle         | 60.3         | 0.0         | 0.0         | **60.4**       |

</details>

## Self-imposed constraints

To make things a little more interesting, I set a few constraints and rules for myself:

1. **The code must be readable**.
    By "readable", I mean the code should be straightforward and easy to follow. No unnecessary abstractions. I should be able to come back to the code months later and still understand (most of) it.
2. **Solutions must be a single file**.
    No external dependencies. No shared utilities module. Everything needed to solve the puzzle should be visible in that one solution file.
3. **The total runtime of all solutions must be under one second**.[^2]
    I want to improve my performance engineering.
4. **Both parts of the puzzle should be solved separately**.
    This means: (1) no solving both parts simultaneously, and (2) no doing extra work in part one that make part two faster. This was to get a clear idea of how long each part takes on its own.
5. **No concurrency or parallelism**.
    Solutions must run sequentially on a single thread. This keeps the focus on the efficiency of the algorithm. I can't speed up slow solutions by using multiple CPU cores.
6. **No ChatGPT. No Claude. No AI help**.
    I want to train myself, not the LLM. I can look at other people's solutions, but only after I have given my best effort at solving the problem.
7. **Follow the constraints of the input file**.
    The solution doesn't have to work for all possible scenarios, but it should work for all AoC inputs. E.g., if the input file only contains 8-bit unsigned integers, the solution doesn't have to handle cases with larger integer types. 
8. **Hardcoding is allowed**.
    E.g. size of the input, number of rows and columns, etc. The code doesn't have to parse the input at runtime since it's known at compile-time. We can embed the input directly into the program using Zig's `@embedFile`.


## Local development setup

To run the solutions, you'll first need to place your input files in the `src/days/data/` directory with the format `dayXX.txt` (add leading zeros for days 1-9). This project uses the [Zig build system](https://ziglang.org/learn/build-system/) to run the commands.

Below are a list of the available commands. For the run and bench steps, you can also pass the optimize mode with the `-Doptimize` flag.

### Building

- `zig build` - Builds all of the binaries. This is useful if you just want to compile without running the programs.

### Running

- `zig build run` - Runs all solution sequentially.
- `zig build run -Day=XX` - Runs the solution for a single day.

### Benchmarking

- `zig build bench` - Benchmarks all solutions sequentially.
- `zig build bench -Day=XX` - Benchmarks the solution for a single day.

### Testing

- `zig build test` - Tests all solutions sequentially.
- `zig build test -Day=XX` - Tests the solution for a single day.
