const std = @import("std");
const puzzle = @import("day"); // Injected by build.zig

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var mean_results: [3]f64 = .{0} ** 3;

    const iterations = 100;
    for (1..(iterations + 1)) |i| {
        const results = try puzzle.run(allocator, false);
        mean_results[0] += (to_f32(results[0]) - mean_results[0]) / to_f32(i);
        mean_results[1] += (to_f32(results[1] - results[0]) - mean_results[1]) / to_f32(i);
        mean_results[2] += (to_f32(results[2] - results[1]) - mean_results[2]) / to_f32(i);
    }

    const total_time = mean_results[0] + mean_results[1] + mean_results[2];

    std.debug.print("{s}\n", .{puzzle.title});
    std.debug.print("| Parsing     | Part 1      | Part 2      | Total       |\n", .{});
    std.debug.print("| ----------- | ----------- | ----------- | ----------- |\n", .{});
    std.debug.print("|{d: >9.0} ns |{d: >9.0} ns |{d: >9.0} ns |{d: >9.0} ns |\n", .{
        mean_results[0], mean_results[1], mean_results[2], total_time,
    });
    std.debug.print("|{d: >9.3} µs |{d: >9.3} µs |{d: >9.3} µs |{d: >9.3} µs |\n", .{
        mean_results[0] / std.time.ns_per_us, mean_results[1] / std.time.ns_per_us, mean_results[2] / std.time.ns_per_us, total_time / std.time.ns_per_us,
    });
    std.debug.print("|{d: >9.3} ms |{d: >9.3} ms |{d: >9.3} ms |{d: >9.3} ms |\n", .{
        mean_results[0] / std.time.ns_per_ms, mean_results[1] / std.time.ns_per_ms, mean_results[2] / std.time.ns_per_ms, total_time / std.time.ns_per_ms,
    });
    std.debug.print("\n", .{});
}

fn to_f32(x: anytype) f64 {
    return @floatFromInt(x);
}
