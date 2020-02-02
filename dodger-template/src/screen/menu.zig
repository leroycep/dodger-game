const std = @import("std");
const c = @import("../c.zig");
const sdl = @import("../sdl.zig");
usingnamespace @import("screen.zig");
const Context = @import("../context.zig").Context;
const PlayScreen = @import("play.zig").PlayScreen;

pub const MenuScreen = struct {
    allocator: *std.mem.Allocator,
    screen: Screen,
    gui: *c.KW_GUI,
    playButtonPressed: *bool,

    const Self = @This();

    pub fn init(allocator: *std.mem.Allocator) !*Self {
        const self = try allocator.create(Self);
        self.allocator = allocator;
        self.screen = Screen{
            .startFn = start,
            .onEventFn = onEvent,
            .updateFn = update,
            .renderFn = render,
            .deinitFn = deinit,
        };

        self.playButtonPressed = try allocator.create(bool);

        return self;
    }

    fn start(screen: *Screen, ctx: *Context) void {
        const self = @fieldParentPtr(Self, "screen", screen);

        self.playButtonPressed.* = false;

        self.gui = c.KW_Init(ctx.kw_driver, ctx.kw_tileset) orelse unreachable;

        var windowrect = c.KW_Rect{ .x = 0, .y = 0, .w = 0, .h = 0 };
        c.SDL_GetWindowSize(ctx.win, &windowrect.w, &windowrect.h);

        var geometry = c.KW_Rect{ .x = 0, .y = 0, .w = 320, .h = 240 };
        c.KW_RectCenterInParent(&windowrect, &geometry);
        var frame = c.KW_CreateFrame(self.gui, null, &geometry);

        var labelrect = c.KW_Rect{ .x = 0, .y = 0, .w = 320, .h = 100 };
        var playbuttonrect: c.KW_Rect = c.KW_Rect{ .x = 10, .y = 0, .w = 300, .h = 20 };

        var rects = [_]?*c.KW_Rect{ &labelrect, &playbuttonrect };
        var weights = [_]c_uint{ 2, 1 };

        c.KW_RectFillParentVertically(&geometry, &rects, &weights, weights.len, 10);
        const label = c.KW_CreateLabel(self.gui, frame, c"Dodger", &labelrect);
        const playbutton = c.KW_CreateButtonAndLabel(self.gui, frame, c"Play", &playbuttonrect) orelse unreachable;

        const iconrect = c.KW_Rect{ .x = 0, .y = 48, .w = 24, .h = 24 };
        c.KW_SetLabelIcon(label, &iconrect);

        c.KW_SetWidgetUserData(playbutton, @ptrCast(*c_void, self.playButtonPressed));
        c.KW_AddWidgetMouseDownHandler(playbutton, onPlayPressed);
    }

    fn onEvent(screen: *Screen, event: ScreenEvent) ?Transition {
        const self = @fieldParentPtr(Self, "screen", screen);

        switch (event) {
            .KeyPressed => |value| {
                if (value == c.SDLK_ESCAPE) {
                    return Transition{ .PopScreen = {} };
                }
            },
        }

        return null;
    }

    fn update(screen: *Screen, ctx: *Context, keys: [*]const u8) ?Transition {
        const self = @fieldParentPtr(Self, "screen", screen);

        c.KW_ProcessEvents(self.gui);

        if (self.playButtonPressed.*) {
            const play_screen = PlayScreen.init(self.allocator) catch unreachable;
            return Transition{ .PushScreen = &play_screen.screen };
        }

        return null;
    }

    fn render(screen: *Screen, ctx: *Context, gpu: *c.GPU_Target) anyerror!void {
        const self = @fieldParentPtr(Self, "screen", screen);

        c.KW_Paint(self.gui);
    }

    fn stop(screen: *Screen) void {
        c.KW_Quit(self.gui);
    }

    fn deinit(screen: *Screen) void {
        const self = @fieldParentPtr(Self, "screen", screen);
        self.allocator.destroy(self.playButtonPressed);
        self.allocator.destroy(self);
    }

    extern fn onPlayPressed(widget: ?*c.KW_Widget, mouse_button: c_int) void {
        const playButtonPressed = @ptrCast(*bool, c.KW_GetWidgetUserData(widget));
        playButtonPressed.* = true;
    }
};
