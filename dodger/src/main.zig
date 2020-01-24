const std = @import("std");
const sdl = @import("sdl.zig");

const SCREEN_WIDTH = 640;
const SCREEN_HEIGHT = 480;

pub fn main() !void {
    if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO) != 0) {
        return sdl.logErr(error.InitFailed);
    }
    defer sdl.SDL_Quit();

    const win = sdl.SDL_CreateWindow(c"Hello World!", 100, 100, 640, 480, sdl.SDL_WINDOW_SHOWN) orelse {
        return sdl.logErr(error.CouldntCreateWindow);
    };
    defer sdl.SDL_DestroyWindow(win);

    const ren = sdl.SDL_CreateRenderer(win, -1, sdl.SDL_RENDERER_ACCELERATED | sdl.SDL_RENDERER_PRESENTVSYNC) orelse {
        return sdl.logErr(error.CouldntCreateRenderer);
    };
    defer sdl.SDL_DestroyRenderer(ren);

    const tex = try sdl.loadTexture(ren, c"assets/texture.bmp");
    defer sdl.SDL_DestroyTexture(tex);
    const guyTex = try sdl.loadTexture(ren, c"assets/guy.bmp");
    defer sdl.SDL_DestroyTexture(tex);

    var i: i32 = 0;
    while (i < 3) {
        _ = sdl.SDL_RenderClear(ren);
        _ = sdl.SDL_RenderCopy(ren, tex, null, null);

        sdl.renderTexture(ren, guyTex, 50, 50);

        _ = sdl.SDL_RenderPresent(ren);

        sdl.SDL_Delay(1000);

        i += 1;
    }
}

