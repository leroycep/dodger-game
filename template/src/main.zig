const std = @import("std");
const c = @import("c.zig");
const sdl = @import("sdl.zig");
const screen = @import("screen.zig");

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

    const gui = c.KW_Init(kw_driver, set) orelse {
        return error.CouldntInitGUI;
    };
    defer c.KW_Quit(gui);

    var geometry = c.KW_Rect{ .x = 0, .y = 0, .w = 320, .h = 240 };
    var frame = c.KW_CreateFrame(gui, null, &geometry);

    var labelrect_ = c.KW_Rect{ .x = 0, .y = 0, .w = 320, .h = 100 };
    const labelrect: [*c]c.KW_Rect = &labelrect_;
    var playbuttonrect_: c.KW_Rect = c.KW_Rect{ .x = 0, .y = 0, .w = 320, .h = 100 };
    const playbuttonrect: [*c]c.KW_Rect = &playbuttonrect_;

    var rects_array = [_][*c]c.KW_Rect{ labelrect, playbuttonrect };
    const rects = rects_array[0..2].ptr;

    var weights_array = [_]c_uint{ 2, 1 };
    const weights = weights_array[0..2].ptr;

    c.KW_RectFillParentVertically(&geometry, rects, weights, 2, 10);
    const label = c.KW_CreateLabel(gui, frame, c"Label with an icon :)", labelrect);
    const playbutton = c.KW_CreateButtonAndLabel(gui, frame, c"Play", playbuttonrect) orelse unreachable;

    const iconrect = c.KW_Rect{ .x = 0, .y = 48, .w = 24, .h = 24 };
    c.KW_SetLabelIcon(label, &iconrect);

    var quit = false;
    var screenStarted = false;
    var e: c.SDL_Event = undefined;
    const keys = c.SDL_GetKeyboardState(null);

    var screens = std.ArrayList(*screen.Screen).init(allocator);
    try screens.append(&(try screen.menu.MenuScreen.init(allocator, gui, playbutton)).screen);

    while (!quit) {
        const currentScreen = screens.toSlice()[screens.len - 1];
        if (!screenStarted) {
            currentScreen.start();
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
                currentScreen.stop();
                try screens.append(newScreen);
                screenStarted = false;
            },
            .PopScreen => {
                currentScreen.stop();
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

