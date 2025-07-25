const std = @import("std");

// Generic function that creates a day-specific struct type. It can accept
// parameters which allows compile-time sizing of arrays/maps based on the input
// constraints.
fn DayNN(length: usize) type {
    return struct {
        // Fields used to store the parsed input or other helpers.
        words: [length][length]u8 = undefined,
        allocator: std.mem.Allocator,

        const Self = @This();

        // Constructor: parses the raw input string into structured data. This part is also included
        // in the total runtime of the solution benchmarks.
        fn init(input: []const u8) Self {
            // Input parsing logic here...
        }

        // Optional cleanup function. Some days require dynamic memory allocation.
        fn deinit(self: *Self) void {
            // Cleanup logic here...
        }

        // Part 1 solution.
        fn part1(self: Self) u64 {}

        // Part 2 solution.
        fn part2(self: Self) u64 {}

        // Miscellaneous helper functions.
        fn helper_function() bool {}
        fn another_helper_function() bool {}
    };
}

// Title of the puzzle (see the puzzle page).
pub const title = "Day NN: Puzzle Title";

// Main entry point called by the build system. Runs the solution and measures the time taken.
pub fn run(_: std.mem.Allocator, is_run: bool) ![3]u64 {
    var timer = try std.time.Timer.start();

    // Embeds the day's input file directly into the program.
    const input = @embedFile("./data/dayNN.txt");

    // Create puzzle instance, parse the input, and measure time.
    const puzzle = DayNN(128).init(input);
    const time0 = timer.read();

    // Solve Part 1 and measure time.
    const result1 = puzzle.part1();
    const time1 = timer.read();

    // Solve Part 2 and measure time.
    const result2 = puzzle.part2();
    const time2 = timer.read();

    if (is_run) {
        std.debug.print("Part 1: {d}\nPart 2: {d}\n", .{ result1, result2 });
    }

    return .{ time0, time1, time2 };
}

// Sample input used for testing. Can be copied directly from the puzzle description.
const sample_input =
    \\Sample input from the puzzle description...
;

// Unit tests for part 1.
test "day NN part 1 sample 1" {
    // Create puzzle instance with sample input size
    const puzzle = DayNN(10).init(sample_input);
    const result = puzzle.part1();
    // Use expected result from puzzle description
    try std.testing.expectEqual(18, result);
}

// Unit tests for part 2.
test "day NN part 2 sample 1" {
    const puzzle = DayNN(10).init(sample_input);
    const result = puzzle.part2();
    try std.testing.expectEqual(9, result);
}

