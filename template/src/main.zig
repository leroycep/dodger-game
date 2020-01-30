const std = @import("std");
const c = @import("c.zig");
const sdl = @import("sdl.zig");
const screen = @import("screen.zig");
const Context = @import("context.zig").Context;

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
    const allocator = std.heap.direct_allocator;

    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        return sdl.logErr(error.InitFailed);
    }
    defer c.SDL_Quit();

    const win = c.SDL_CreateWindow(c"Hello World!", 100, 100, 640, 480, c.SDL_WINDOW_SHOWN | c.SDL_WINDOW_OPENGL) orelse {
        return sdl.logErr(error.CouldntCreateWindow);
    };
    defer c.SDL_DestroyWindow(win);

    const ren = c.SDL_CreateRenderer(win, -1, c.SDL_RENDERER_ACCELERATED | c.SDL_RENDERER_PRESENTVSYNC) orelse {
        return sdl.logErr(error.CouldntCreateRenderer);
    };
    defer c.SDL_DestroyRenderer(ren);

    if ((c.IMG_Init(c.IMG_INIT_PNG) & c.IMG_INIT_PNG) != c.IMG_INIT_PNG) {
        return sdl.logErr(error.ImgInit);
    }

    const kw_driver = c.KW_CreateSDL2RenderDriver(ren, win);
    defer c.KW_ReleaseRenderDriver(kw_driver);

    const set = c.KW_LoadSurface(kw_driver, c"lib/kiwi/examples/tileset/tileset.png");
    defer c.KW_ReleaseSurface(kw_driver, set);

    var ctx = Context{ .win = win, .kw_driver = kw_driver, .kw_tileset = set };

    var quit = false;
    var screenStarted = false;
    var e: c.SDL_Event = undefined;
    const keys = c.SDL_GetKeyboardState(null);

    var screens = std.ArrayList(*screen.Screen).init(allocator);
    try screens.append(&(try screen.menu.MenuScreen.init(allocator)).screen);

    while (!quit) {
        const currentScreen = screens.toSlice()[screens.len - 1];
        if (!screenStarted) {
            currentScreen.start(&ctx);
            screenStarted = true;
        }

        while (c.SDL_PollEvent(&e) != 0) {
            if (e.type == c.SDL_QUIT) {
                quit = true;
            }
        }

        const transition = currentScreen.update(keys);

        _ = c.SDL_RenderClear(ren);
        try currentScreen.render(ren);
        c.SDL_RenderPresent(ren);

        switch (transition) {
            .PushScreen => |newScreen| {
                currentScreen.stop(&ctx);
                try screens.append(newScreen);
                screenStarted = false;
            },
            .PopScreen => {
                currentScreen.stop(&ctx);
                screens.pop().deinit();
                if (screens.len == 0) {
                    quit = true;
                }
                screenStarted = false;
            },
            .None => {},
        }
    }
}
