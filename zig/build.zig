const std = @import("std");

const packages = struct {
    const aoc = std.build.Pkg {
        .name = "aoc",
        .source = .{ .path = "./lib/aoc/aoc.zig" },
    };
};

const days = [_][] const u8 {
    "day01", "day02", "day03", "day04", "day05",
    "day06", "day07", "day08", "day09", "day10",
    "day11", "day12", "day13", "day14", "day15",
    "day16", "day17", "day18", "day19", "day20",
    "day21", "day22", "day23", "day24", "day25",
};

pub fn build(b: *std.build.Builder) !void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    inline for (days) |name| {
        const path = "./src/" ++ name ++ ".zig";

        var exe = b.addExecutable(name, path);
        exe.addPackage(packages.aoc);
        exe.setTarget(target);
        exe.setBuildMode(mode);
        exe.install();

        var exe_tests = b.addTest(path);
        exe_tests.addPackage(packages.aoc);
        exe_tests.setTarget(target);
        exe_tests.setBuildMode(mode);

        var test_step = b.step(name ++ "-test", "Run unit tests for " ++ name);
        test_step.dependOn(&exe_tests.step);
    }
}
