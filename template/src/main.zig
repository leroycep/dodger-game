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

const TransitionTag = enum {
    PushScreen,
    PopScreen,
    None,
};

const Transition = union(TransitionTag) {
    PushScreen: *Screen,
    PopScreen: void,
    None: void,
};

const Screen = struct {
    updateFn: fn (self: *Screen, keys: [*]const u8) Transition,
    renderFn: fn (self: *Screen, *c.SDL_Renderer) anyerror!void,

    pub fn init(updateFn: fn (*Screen, [*]const u8) Transition, renderFn: fn (*Screen, *c.SDL_Renderer) anyerror!void) Screen {
        return Screen{
            .updateFn = updateFn,
            .renderFn = renderFn,
        };
    }

    pub fn update(self: *Screen, keys: [*]const u8) Transition {
        return self.updateFn(self, keys);
    }

    pub fn render(self: *Screen, ren: *c.SDL_Renderer) !void {
        return self.renderFn(self, ren);
    }
};

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

    const geometry = c.KW_Rect{ .x = 0, .y = 0, .w = 320, .h = 240 };
    const frame = c.KW_CreateFrame(gui, null, &geometry);

    const label = c.KW_CreateLabel(gui, frame, c"Label with an icon :)", &geometry);

    const iconrect = c.KW_Rect{ .x = 0, .y = 48, .w = 24, .h = 24 };
    c.KW_SetLabelIcon(label, &iconrect);

    var quit = false;
    var e: c.SDL_Event = undefined;
    const keys = c.SDL_GetKeyboardState(null);
    var screen = &MenuScreen.init(gui).screen;

    while (!quit) {
        while (c.SDL_PollEvent(&e) != 0) {
            if (e.type == c.SDL_QUIT) {
                quit = true;
            }

            switch (screen.update(keys)) {
                .PushScreen => |newScreen| {
                    screen = newScreen;
                },
                .PopScreen => {
                    quit = true;
                },
                .None => {},
            }

            _ = c.SDL_RenderClear(ren);
            try screen.render(ren);
            c.SDL_RenderPresent(ren);
        }
    }
}

const MenuScreen = struct {
    screen: Screen,
    gui: *c.KW_GUI,

    fn init(gui: *c.KW_GUI) MenuScreen {
        return MenuScreen{
            .screen = Screen.init(update, render),
            .gui = gui,
        };
    }

    fn update(screen: *Screen, keys: [*]const u8) Transition {
        const self = @fieldParentPtr(MenuScreen, "screen", screen);

        c.KW_ProcessEvents(self.gui);
        if (keys[sdl.scnFromKey(c.SDLK_ESCAPE)] == 1) {
            return Transition{.PopScreen = {}};
        }
        return Transition{.None = {}};
    }

    fn render(screen: *Screen, ren: *c.SDL_Renderer) anyerror!void {
        const self = @fieldParentPtr(MenuScreen, "screen", screen);

        c.KW_Paint(self.gui);
    }
};
