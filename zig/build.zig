const std = @import("std");

fn build_day(comptime name : []const u8, b: *std.build.Builder, target: std.zig.CrossTarget, mode: std.builtin.Mode) !void {
    const path = "src/" ++ name ++ ".zig";

    var exe = b.addExecutable(name, path);
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    var run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    var run_step = b.step("run " ++ name, "Run " ++ name);
    run_step.dependOn(&run_cmd.step);

    var exe_tests = b.addTest(path);
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    var test_step = b.step("test " ++ name, "Run unit tests for " ++ name);
    test_step.dependOn(&exe_tests.step);
}

pub fn build(b: *std.build.Builder) !void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardReleaseOptions();

    try build_day("day01", b, target, mode);
}
