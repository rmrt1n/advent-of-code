const std = @import("std");
const puzzle = @import("day"); // Injected by build.zig

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    std.debug.print("{s}\n", .{puzzle.title});
    _ = try puzzle.run(allocator, true);
    std.debug.print("\n", .{});
}
