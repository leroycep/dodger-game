const std = @import("std");
const builtin = @import("builtin");
const c = @import("c.zig");
const sdl = @import("sdl.zig");
const assets = @import("assets.zig");
usingnamespace @import("constants.zig");

pub fn init() void {
    var want: c.SDL_AudioSpec = undefined;
    _ = c.SDL_memset(&want, 0, @sizeOf(c.SDL_AudioSpec));
    want.freq = 48000;
    want.format = c.AUDIO_F32;
    want.channels = 2;
    want.samples = 4096;
    want.callback = audio_callback;

    var have: c.SDL_AudioSpec = undefined;
    _ = c.SDL_memset(&have, 0, @sizeOf(c.SDL_AudioSpec));
    var dev = c.SDL_OpenAudioDevice(null, 0, &want, &have, c.SDL_AUDIO_ALLOW_FORMAT_CHANGE);
    if (dev == 0) {
        std.debug.warn("Could not acquire audio device.\n");
        _ = std.c.printf(c"%s", c.SDL_GetError());
        return;
    }

    c.SDL_PauseAudioDevice(dev, 0);
}

pub extern fn audio_callback(userdata: ?*c_void, stream: ?[*]u8, length: c_int) void {
    var len: usize = @intCast(usize, @divTrunc(length, 2));
    var i: usize = 0;
    var buf: [*]c.Sint16 = @ptrCast([*]c.Sint16, @alignCast(2, stream));
    while (i < len) {
        buf[i] = 0;
        i += 1;
    }
    return;
}
