const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const run_all = b.step("run", "Run all days");
    const bench_all = b.step("bench", "Benchmark all days");
    const test_all = b.step("test", "Test all days");

    const day_option = b.option(usize, "ay", "");

    for (1..26) |day| {
        const day_zig_file = b.path(b.fmt("src/days/day{d:0>2}.zig", .{day}));

        const run_exe = b.addExecutable(.{
            .name = b.fmt("run-day{d:0>2}-Debug", .{day}),
            .root_source_file = b.path("src/run.zig"),
            .target = target,
            .optimize = optimize, // Defaults to Debug
        });
        run_exe.root_module.addAnonymousImport("day", .{ .root_source_file = day_zig_file });
        b.installArtifact(run_exe);

        const bench_exe = b.addExecutable(.{
            .name = b.fmt("bench-day{d:0>2}-Debug", .{day}),
            .root_source_file = b.path("src/bench.zig"),
            .target = target,
            .optimize = optimize, // Defaults to Debug
        });
        bench_exe.root_module.addAnonymousImport("day", .{ .root_source_file = day_zig_file });
        b.installArtifact(bench_exe);

        for ([_]std.builtin.OptimizeMode{ .ReleaseSafe, .ReleaseFast, .ReleaseSmall }) |other_optimize| {
            const other_run_exe = b.addExecutable(.{
                .name = b.fmt("run-day{d:0>2}-{s}", .{ day, @tagName(other_optimize) }),
                .root_source_file = b.path("src/run.zig"),
                .target = target,
                .optimize = other_optimize,
            });
            other_run_exe.root_module.addAnonymousImport("day", .{ .root_source_file = day_zig_file });
            b.installArtifact(other_run_exe);

            const other_bench_exe = b.addExecutable(.{
                .name = b.fmt("bench-day{d:0>2}-{s}", .{ day, @tagName(other_optimize) }),
                .root_source_file = b.path("src/bench.zig"),
                .target = target,
                .optimize = other_optimize,
            });
            other_bench_exe.root_module.addAnonymousImport("day", .{ .root_source_file = day_zig_file });
            b.installArtifact(other_bench_exe);
        }

        const unit_test = b.addTest(.{ .root_source_file = day_zig_file, .target = target });

        if (day_option == null or day_option == day) {
            const run_cmd = b.addRunArtifact(run_exe);
            run_all.dependOn(&run_cmd.step);

            const bench_cmd = b.addRunArtifact(bench_exe);
            bench_all.dependOn(&bench_cmd.step);

            const test_cmd = b.addRunArtifact(unit_test);
            test_all.dependOn(&test_cmd.step);
        }
    }
}
