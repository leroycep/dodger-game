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

    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("dodger", "src/main.zig");
    exe.setBuildMode(mode);
    exe.linkSystemLibrary("SDL2");
    exe.linkSystemLibrary("SDL2_ttf");
    exe.linkSystemLibrary("SDL2_gpu");
    exe.linkSystemLibrary("sqlite3");
    exe.linkSystemLibrary("c");
    exe.addIncludeDir(KIWI_SOURCE_PATH);
    exe.addIncludeDir(file2c_output_dir);

    exe.addIncludeDir(PD_INCLUDE_PATH);
    exe.addIncludeDir(LIBPD_INCLUDE_PATH);
    exe.step.dependOn(resources);

    const lib_cflags = [_][]const u8{};
    const resource_c_path = fs.path.join(b.allocator, &[_][]const u8{ file2c_output_dir, "resources.c" }) catch unreachable;
    exe.addCSourceFile(resource_c_path, lib_cflags);
    inline for (KIWI_SOURCES) |src| {
        exe.addCSourceFile(KIWI_SOURCE_PATH ++ fs.path.sep_str ++ src, lib_cflags);
    }
    const lib_cflags_pd = [_][]const u8{"-DPD", "-DHAVE_UNISTD_H", "-DUSEAPI_DUMMY"};
    inline for (LIBPD_SOURCES) |src| {
        exe.addCSourceFile(LIBPD_PROJECT_PATH ++ fs.path.sep_str ++ src, lib_cflags_pd);
    }
    exe.install();

    // Copy assets folder next to binary
    b.installDirectory(std.build.InstallDirectoryOptions{
        .source_dir = "assets",
        .install_dir = .Bin,
        .install_subdir = "assets",
    });

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
    // "utf8.c",
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
    "KW_rect.c",
    "KW_toggle.c",
    "KW_checkbox.c",
};

const LIBPD_PROJECT_PATH = "../lib/libpd";
const PD_INCLUDE_PATH = LIBPD_PROJECT_PATH ++ fs.path.sep_str ++ "pure-data" ++ fs.path.sep_str ++ "src";
const LIBPD_INCLUDE_PATH = LIBPD_PROJECT_PATH ++ fs.path.sep_str ++ "libpd_wrapper";
const LIBPD_LIB_PATH = LIBPD_PROJECT_PATH ++ fs.path.sep_str ++ "libs";
const LIBPD_SOURCES = [_][]const u8 {
    "pure-data/src/d_arithmetic.c",
    "pure-data/src/d_array.c",
    "pure-data/src/d_ctl.c",
    "pure-data/src/d_dac.c",
    "pure-data/src/d_delay.c",
    "pure-data/src/d_fft.c",
    "pure-data/src/d_fft_fftsg.c",
    "pure-data/src/d_filter.c",
    "pure-data/src/d_global.c",
    "pure-data/src/d_math.c",
    "pure-data/src/d_misc.c",
    "pure-data/src/d_osc.c",
    "pure-data/src/d_resample.c",
    "pure-data/src/d_soundfile.c",
    "pure-data/src/d_ugen.c",
    "pure-data/src/g_all_guis.c",
    "pure-data/src/g_array.c",
    "pure-data/src/g_bang.c",
    "pure-data/src/g_canvas.c",
    "pure-data/src/g_clone.c",
    "pure-data/src/g_editor.c",
    "pure-data/src/g_editor_extras.c",
    "pure-data/src/g_graph.c",
    "pure-data/src/g_guiconnect.c",
    "pure-data/src/g_hdial.c",
    "pure-data/src/g_hslider.c",
    "pure-data/src/g_io.c",
    "pure-data/src/g_mycanvas.c",
    "pure-data/src/g_numbox.c",
    "pure-data/src/g_readwrite.c",
    "pure-data/src/g_rtext.c",
    "pure-data/src/g_scalar.c",
    "pure-data/src/g_template.c",
    "pure-data/src/g_text.c",
    "pure-data/src/g_toggle.c",
    "pure-data/src/g_traversal.c",
    "pure-data/src/g_undo.c",
    "pure-data/src/g_vdial.c",
    "pure-data/src/g_vslider.c",
    "pure-data/src/g_vumeter.c",
    "pure-data/src/m_atom.c",
    "pure-data/src/m_binbuf.c",
    "pure-data/src/m_class.c",
    "pure-data/src/m_conf.c",
    "pure-data/src/m_glob.c",
    "pure-data/src/m_memory.c",
    "pure-data/src/m_obj.c",
    "pure-data/src/m_pd.c",
    "pure-data/src/m_sched.c",
    "pure-data/src/s_audio.c",
    "pure-data/src/s_audio_dummy.c",
    "pure-data/src/s_inter.c",
    "pure-data/src/s_loader.c",
    "pure-data/src/s_main.c",
    "pure-data/src/s_path.c",
    "pure-data/src/s_print.c",
    "pure-data/src/s_utf8.c",
    "pure-data/src/x_acoustics.c",
    "pure-data/src/x_arithmetic.c",
    "pure-data/src/x_array.c",
    "pure-data/src/x_connective.c",
    "pure-data/src/x_gui.c",
    "pure-data/src/x_interface.c",
    "pure-data/src/x_list.c",
    "pure-data/src/x_midi.c",
    "pure-data/src/x_misc.c",
    "pure-data/src/x_net.c",
    "pure-data/src/x_scalar.c",
    "pure-data/src/x_text.c",
    "pure-data/src/x_time.c",
    "pure-data/src/x_vexp.c",
    "pure-data/src/x_vexp_if.c",
    "pure-data/src/x_vexp_fun.c",
    "libpd_wrapper/s_libpdmidi.c",
    "libpd_wrapper/x_libpdreceive.c",
    "libpd_wrapper/z_hooks.c",
    "libpd_wrapper/z_libpd.c",
};
