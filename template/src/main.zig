const std = @import("std");
const c = @import("c.zig");
const sdl = @import("sdl.zig");

const vertexSource: [*]const u8 =
    c\\ attribute vec4 position;
    c\\ void main()
    c\\ {
    c\\     gl_Position = vec4(position.xyz, 1.0);
    c\\ }
;
const fragmentSource: [*]const c.GLchar =
    c\\ precision mediump float;
    c\\ void main()
    c\\ {
    c\\     gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
    c\\ }
;

pub fn main() !void {
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        return sdl.logErr(error.InitFailed);
    }
    defer c.SDL_Quit();

    const win = c.SDL_CreateWindow(c"Hello World!", 100, 100, 640, 480, c.SDL_WINDOW_SHOWN | c.SDL_WINDOW_OPENGL) orelse {
        return sdl.logErr(error.CouldntCreateWindow);
    };
    defer c.SDL_DestroyWindow(win);

    if (c.SDL_GL_SetAttribute(c.SDL_GLattr.SDL_GL_CONTEXT_MAJOR_VERSION, 2) != 0) {
        return sdl.logErr(error.InitFailed);
    }
    if (c.SDL_GL_SetAttribute(c.SDL_GLattr.SDL_GL_CONTEXT_MINOR_VERSION, 0) != 0) {
        return sdl.logErr(error.InitFailed);
    }
    if (c.SDL_GL_SetAttribute(c.SDL_GLattr.SDL_GL_DOUBLEBUFFER, 1) != 0) {
        return sdl.logErr(error.InitFailed);
    }
    if (c.SDL_GL_SetAttribute(c.SDL_GLattr.SDL_GL_DEPTH_SIZE, 24) != 0) {
        return sdl.logErr(error.InitFailed);
    }

    var glc = c.SDL_GL_CreateContext(win);
    defer c.SDL_GL_DeleteContext(glc);

    var quit = false;
    var e: c.SDL_Event = undefined;
    const keys = c.SDL_GetKeyboardState(null);

    while (!quit) {
        while (c.SDL_PollEvent(&e) != 0) {
            if (e.type == c.SDL_QUIT) {
                quit = true;
            }
            if (e.type == c.SDL_KEYDOWN) {
                if (e.key.keysym.sym == c.SDLK_ESCAPE) {
                    quit = true;
                }
            }

            c.glClearColor(1.0, 0.0, 0.0, 1.0);
            c.glClear(c.GL_COLOR_BUFFER_BIT);
            c.SDL_GL_SwapWindow(win);

        }
    }
}
