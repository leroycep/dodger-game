const std = @import("std");
const sdl = @import("sdl.zig");

pub fn main() !void {
    if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO) != 0) {
        std.debug.warn("SDL init error: {}\n", sdl.SDL_GetError());
        return error.SdlInitFailed;
    }
    defer sdl.SDL_Quit();

    const win = sdl.SDL_CreateWindow(c"Hello World!", 100, 100, 640, 480, sdl.SDL_WINDOW_SHOWN);
    if (win == null) {
        return error.CouldntCreateWindow;
    }
    defer sdl.SDL_DestroyWindow(win);

    const ren = sdl.SDL_CreateRenderer(win, -1, sdl.SDL_RENDERER_ACCELERATED | sdl.SDL_RENDERER_PRESENTVSYNC);
    if (ren == null) {
        return error.CouldntCreateRenderer;
    }
    defer sdl.SDL_DestroyRenderer(ren);

    const bmp = sdl.SDL_LoadBMP_RW(sdl.SDL_RWFromFile(c"assets/texture.bmp", c"rb"), 1);
    if (bmp == null) {
        return error.CouldntLoadBMP;
    }

    const tex = sdl.SDL_CreateTextureFromSurface(ren, bmp);
    sdl.SDL_FreeSurface(bmp);
    if (tex == null) {
        return error.CouldntCreateTexture;
    }
    defer sdl.SDL_DestroyTexture(tex);

    var i: i32 = 0;
    while (i < 3) {
        _ = sdl.SDL_RenderClear(ren);
        _ = sdl.SDL_RenderCopy(ren, tex, null, null);
        _ = sdl.SDL_RenderPresent(ren);

        sdl.SDL_Delay(1000);

        i += 1;
    }
}
