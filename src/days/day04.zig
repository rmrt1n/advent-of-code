const std = @import("std");

fn Day04(length: usize) type {
    return struct {
        const Self = @This();

        words: [length][length]u8 = undefined,

        fn init(input: []const u8) Self {
            var result = Self{};

            var i: u8 = 0;
            var lexer = std.mem.tokenizeScalar(u8, input, '\n');
            while (lexer.next()) |line| : (i += 1) {
                @memcpy(&result.words[i], line);
            }

            return result;
        }

        fn part1(self: Self) u64 {
            var result: u64 = 0;

            for (0..length) |i| { // Horizontal _ and vertical |
                for (0..(length - 4 + 1)) |j| {
                    const horizontal = .{
                        self.words[i][j],     self.words[i][j + 1],
                        self.words[i][j + 2], self.words[i][j + 3],
                    };
                    const vertical = .{
                        self.words[j][i],     self.words[j + 1][i],
                        self.words[j + 2][i], self.words[j + 3][i],
                    };

                    if (matches("XMAS", &horizontal)) result += 1;
                    if (matches("XMAS", &vertical)) result += 1;
                }
            }

            for (0..(length - 4 + 1)) |i| { // Backward \ and forward / diagonals
                for (0..(length - 4 + 1)) |j| {
                    const diagonal_backward = .{
                        self.words[i][j],         self.words[i + 1][j + 1],
                        self.words[i + 2][j + 2], self.words[i + 3][j + 3],
                    };
                    const diagonal_forward = .{
                        self.words[i + 3][j],     self.words[i + 2][j + 1],
                        self.words[i + 1][j + 2], self.words[i][j + 3],
                    };

                    if (matches("XMAS", &diagonal_backward)) result += 1;
                    if (matches("XMAS", &diagonal_forward)) result += 1;
                }
            }

            return result;
        }

        fn part2(self: Self) u64 {
            var result: u64 = 0;
            for (0..(length - 3 + 1)) |i| {
                for (0..(length - 3 + 1)) |j| {
                    const diagonal_backward = .{
                        self.words[i][j], self.words[i + 1][j + 1], self.words[i + 2][j + 2],
                    };
                    const diagonal_forward = .{
                        self.words[i + 2][j], self.words[i + 1][j + 1], self.words[i][j + 2],
                    };

                    if (matches("MAS", &diagonal_backward) and matches("MAS", &diagonal_forward)) {
                        result += 1;
                    }
                }
            }
            return result;
        }

        fn matches(comptime word: []const u8, slice: []const u8) bool {
            var reversed: [word.len]u8 = undefined;
            @memcpy(&reversed, word);
            std.mem.reverse(u8, &reversed);
            return std.mem.eql(u8, word, slice) or std.mem.eql(u8, &reversed, slice);
        }
    };
}

pub const title = "Day 04: Ceres Search";

pub fn run(_: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    const input = @embedFile("./data/day04.txt");
    const puzzle = Day04(140).init(input);
    const time0 = timer.read();

    const result1 = puzzle.part1();
    const time1 = timer.read();

    const result2 = puzzle.part2();
    const time2 = timer.read();

    if (is_run) {
        std.debug.print("Part 1: {d}\nPart 2: {d}\n", .{ result1, result2 });
    }

    return .{ time0, time1, time2 };
}

const sample_input =
    \\MMMSXXMASM
    \\MSAMXMSMSA
    \\AMXSXMAAMM
    \\MSAMASMSMX
    \\XMASAMXAMM
    \\XXAMMXXAMA
    \\SMSMSASXSS
    \\SAXAMASAAA
    \\MAMMMXMMMM
    \\MXMXAXMASX
;

test "day 04 part 1 sample 1" {
    const puzzle = Day04(10).init(sample_input);
    const result = puzzle.part1();
    try std.testing.expectEqual(18, result);
}

test "day 04 part 2 sample 1" {
    const puzzle = Day04(10).init(sample_input);
    const result = puzzle.part2();
    try std.testing.expectEqual(9, result);
}
