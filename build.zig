const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const httpz = b.dependency("httpz", .{
        .target = target,
        .optimize = optimize,
    });

    const exe = b.addExecutable(.{
        .name = "rmc",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "httpz", .module = httpz.module("httpz") },
            },
        }),
    });

    const configure_hooks_cmd = b.addSystemCommand(&.{ "git", "config", "core.hooksPath", ".githooks" });

    b.installArtifact(exe);
    b.getInstallStep().dependOn(&configure_hooks_cmd.step);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const e2e_cmd = b.addSystemCommand(&.{"scripts/test_e2e.sh"});
    e2e_cmd.step.dependOn(b.getInstallStep());

    const e2e_step = b.step("e2e", "Run the black-box end-to-end test");
    e2e_step.dependOn(&e2e_cmd.step);

    const fmt_cmd = b.addSystemCommand(&.{ "zig", "fmt", "build.zig", "build.zig.zon", "src" });

    const fmt_step = b.step("fmt", "Format source files");
    fmt_step.dependOn(&fmt_cmd.step);
}
