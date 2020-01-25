const std = @import("std");
const path = std.fs.path;
const Builder = std.build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("dodger", "src/main.zig");
    exe.setBuildMode(mode);
    exe.linkSystemLibrary("SDL2");
    exe.linkSystemLibrary("SDL2_image");
    exe.linkSystemLibrary("c");

    b.default_step.dependOn(&exe.step);
    exe.install();

    const run_step = b.step("run", "Run the game");
    const run_cmd = exe.run();
    run_step.dependOn(&run_cmd.step);
}
