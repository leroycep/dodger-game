const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("template", "src/main.zig");
    exe.setBuildMode(mode);
    exe.linkSystemLibrary("SDL2");
    exe.linkSystemLibrary("SDL2_image");
    exe.linkSystemLibrary("GLESv2");
    exe.linkSystemLibrary("c");
    exe.addIncludeDir("lib/kiwi/src/");

    const lib_cflags = [_][]const u8{};
    inline for (KIWI_SOURCES) |src| {
        exe.addCSourceFile("lib/kiwi/src/" ++ src, lib_cflags);
    }
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the game");
    run_step.dependOn(&run_cmd.step);
}

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
