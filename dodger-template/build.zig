const std = @import("std");
const fs = std.fs;
const Builder = @import("std").build.Builder;
const Step = @import("std").build.Step;
const LibExeObjStep = @import("std").build.LibExeObjStep;

pub fn build(b: *Builder) void {
    std.debug.warn("{}\n", b.build_root);
    std.debug.warn("{}\n", b.cache_root);
    const file2c = buildFile2c(b);
    const file2c_output_dir = fs.path.join(b.allocator, &[_][]const u8{ b.build_root, b.cache_root, FILE2C_OUTPUT_SUBDIR }) catch unreachable;
    const resources = buildResources(b, file2c, file2c_output_dir);

    const libpd_project_path = fs.path.join(b.allocator, &[_][]const u8{ b.build_root, LIBPD_PROJECT_PATH }) catch unreachable;
    const make_libpd = b.addSystemCommand(&[_][] const u8{"make"});
    make_libpd.cwd = libpd_project_path;

    const make_libpd_step = b.step("build_libpd", "Build libpd dependency");
    make_libpd_step.dependOn(&make_libpd.step);

    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("template", "src/main.zig");
    exe.setBuildMode(mode);
    exe.linkSystemLibrary("SDL2");
    exe.linkSystemLibrary("SDL2_image");
    exe.linkSystemLibrary("SDL2_ttf");
    exe.linkSystemLibrary("SDL2_gpu");
    exe.linkSystemLibrary("c");
    exe.addIncludeDir(KIWI_SOURCE_PATH);
    exe.addIncludeDir(file2c_output_dir);

    exe.addIncludeDir(PD_INCLUDE_PATH);
    exe.addIncludeDir(LIBPD_INCLUDE_PATH);
    exe.addObjectFile(LIBPD_LIB_PATH ++ fs.path.sep_str ++ "libpd.so");

    exe.step.dependOn(make_libpd_step);
    exe.step.dependOn(resources);

    const lib_cflags = [_][]const u8{};
    const resource_c_path = fs.path.join(b.allocator, &[_][]const u8{ file2c_output_dir, "resources.c" }) catch unreachable;
    exe.addCSourceFile(resource_c_path, lib_cflags);
    inline for (KIWI_SOURCES) |src| {
        exe.addCSourceFile(KIWI_SOURCE_PATH ++ "/" ++ src, lib_cflags);
    }
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the game");
    run_step.dependOn(&run_cmd.step);
}

fn buildFile2c(b: *Builder) *LibExeObjStep {
    const exe = b.addExecutable("file2c", "src/_blank.zig");
    exe.linkSystemLibrary("c");
    exe.addCSourceFile(KIWI_SOURCE_PATH ++ fs.path.sep_str ++ FILE2C_SOURCE, [_][]const u8{});
    return exe;
}

/// Build the resources.(c|h) files using `file2c`
fn buildResources(b: *Builder, file2c: *LibExeObjStep, output_dir: []const u8) *Step {
    b.makePath(output_dir) catch unreachable;
    const file2c_run_cmd = file2c.run();
    const res_c = fs.path.join(b.allocator, &[_][]const u8{ output_dir, "resources.c" }) catch unreachable;
    const res_h = fs.path.join(b.allocator, &[_][]const u8{ output_dir, "resources.h" }) catch unreachable;
    const kiwi_project_path = fs.path.join(b.allocator, &[_][]const u8{ b.build_root, KIWI_PROJECT_PATH }) catch unreachable;
    file2c_run_cmd.cwd = kiwi_project_path;
    file2c_run_cmd.addArgs([_][]const u8{ res_h, res_c, "resources/sourcesans-pro-semibold.ttf" });

    const build_resources_step = b.step("build_resources", "Build the resources for KiWi into a `resources.c` file");
    build_resources_step.dependOn(&file2c_run_cmd.step);
    return build_resources_step;
}

const KIWI_PROJECT_PATH = "../lib/kiwi";
const KIWI_SOURCE_PATH = KIWI_PROJECT_PATH ++ fs.path.sep_str ++ "src";
const FILE2C_SOURCE = "file2c.c";
const FILE2C_OUTPUT_SUBDIR = "file2c_generated_code";
const KIWI_SOURCES = [_][]const u8{
    "KW_scrollbox_internal.c",
    "KW_scrollbox.c",
    "KW_editbox_internal.c",
    "utf8.c",
    "KW_editbox.c",
    "KW_eventwatcher.c",
    "KW_button.c",
    "KW_label.c",
    "KW_label_internal.c",
    "KW_gui.c",
    "KW_frame.c",
    "KW_frame_internal.c",
    "KW_tilerenderer.c",
    "KW_widget.c",
    "KW_widget_eventhandlers.c",
    "KW_renderdriver.c",
    "KW_renderdriver_sdl2.c",
    "KW_rect.c",
    "KW_toggle.c",
    "KW_checkbox.c",
};

const LIBPD_PROJECT_PATH = "../lib/libpd";
const PD_INCLUDE_PATH = LIBPD_PROJECT_PATH ++ fs.path.sep_str ++ "pure-data" ++ fs.path.sep_str ++ "src";
const LIBPD_INCLUDE_PATH = LIBPD_PROJECT_PATH ++ fs.path.sep_str ++ "libpd_wrapper";
const LIBPD_LIB_PATH = LIBPD_PROJECT_PATH ++ fs.path.sep_str ++ "libs";
