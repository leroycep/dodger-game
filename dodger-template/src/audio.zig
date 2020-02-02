const std = @import("std");
const builtin = @import("builtin");
const c = @import("c.zig");
const sdl = @import("sdl.zig");
const assets = @import("assets.zig");
usingnamespace @import("constants.zig");

const SAMPLE_RATE = 48000;

pub fn init() void {
    var want: c.SDL_AudioSpec = undefined;
    _ = c.SDL_memset(&want, 0, @sizeOf(c.SDL_AudioSpec));
    want.freq = SAMPLE_RATE;
    want.format = c.AUDIO_F32;
    want.channels = 2;
    want.samples = 256;
    want.callback = audio_callback;

    var have: c.SDL_AudioSpec = undefined;
    _ = c.SDL_memset(&have, 0, @sizeOf(c.SDL_AudioSpec));
    var dev = c.SDL_OpenAudioDevice(null, 0, &want, &have, c.SDL_AUDIO_ALLOW_FORMAT_CHANGE);
    if (dev == 0) {
        std.debug.warn("Could not acquire audio device.\n");
        _ = std.c.printf(c"%s", c.SDL_GetError());
        return;
    }

    std.debug.warn("Samples per callback: {}\n", have.samples);

    init_pd();

    c.SDL_PauseAudioDevice(dev, 0);
}

extern fn pdprint(s: ?[*]const u8) void {
    _ = std.c.printf(c"%s", s);
}

extern fn init_pd() void {
    c.libpd_set_printhook(pdprint);
    _ = c.libpd_init();
    _ = c.libpd_init_audio(0, 2, SAMPLE_RATE);
    c.libpd_set_verbose(0);

    _ = c.libpd_start_message(1);
    c.libpd_add_float(1.0);
    _ = c.libpd_finish_message(c"pd", c"dsp");

    var patch = c.libpd_openfile(c"footstep.pd", c"assets");
    var patch_id = c.libpd_getdollarzero(patch);
    std.debug.warn("{}\n", patch_id);

    _ = c.libpd_float(c"walkspeed", 0.0);
    _ = c.libpd_start_message(1);
    _ = c.libpd_finish_message(c"texture", c"snow");
    _ = c.libpd_float(c"$0-roll", 0.0);
}

const inbuf: [64]f32 = undefined;

pub extern fn audio_callback(userdata: ?*c_void, stream: ?[*]u8, length: c_int) void {
    var float_len = @divTrunc(length, @sizeOf(f32)); // 4 = size of float in bytes
    var len = @divTrunc(float_len, 64 * 2);
    var outbuf: [*]f32 = @ptrCast([*]f32, @alignCast(@alignOf(f32), stream));
    var rc = c.libpd_process_float(len, &inbuf, outbuf);
    if (rc != 0) {
        // This is an error, but it probably shouldn't be printed in this thread
    }
    return;
}
