const std = @import("std");
const c = @import("../c.zig");
const sdl = @import("../sdl.zig");
usingnamespace @import("screen.zig");
const Context = @import("../context.zig").Context;
const PlayScreen = @import("play.zig").PlayScreen;
const HighScoresScreen = @import("high_scores.zig").HighScoresScreen;

pub const MenuScreen = struct {
    allocator: *std.mem.Allocator,
    screen: Screen,
    gui: *c.KW_GUI,
    playButtonPressed: *bool,
    highScoresButtonPressed: *bool,
    exitButtonPressed: *bool,

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
        self.highScoresButtonPressed = try allocator.create(bool);
        self.exitButtonPressed = try allocator.create(bool);

        return self;
    }

    fn start(screen: *Screen, ctx: *Context) void {
        const self = @fieldParentPtr(Self, "screen", screen);

        self.playButtonPressed.* = false;
        self.highScoresButtonPressed.* = false;

        self.gui = c.KW_Init(ctx.kw_driver, ctx.kw_tileset) orelse unreachable;

        var windowrect = c.KW_Rect{ .x = 0, .y = 0, .w = 0, .h = 0 };
        c.SDL_GetWindowSize(ctx.win, &windowrect.w, &windowrect.h);

        var geometry = c.KW_Rect{ .x = 0, .y = 0, .w = 320, .h = 240 };
        c.KW_RectCenterInParent(&windowrect, &geometry);
        var frame = c.KW_CreateFrame(self.gui, null, &geometry);

        var labelrect = c.KW_Rect{ .x = 0, .y = 0, .w = 320, .h = 0 };
        var playbuttonrect: c.KW_Rect = c.KW_Rect{ .x = 10, .y = 0, .w = 300, .h = 0 };
        var highScoresRect: c.KW_Rect = c.KW_Rect{ .x = 10, .y = 0, .w = 300, .h = 0 };
        var exitRect: c.KW_Rect = c.KW_Rect{ .x = 10, .y = 0, .w = 300, .h = 0 };

        var rects = [_]?*c.KW_Rect{ &labelrect, &playbuttonrect, &highScoresRect, &exitRect };
        var weights = [_]c_uint{ 2, 1, 1, 1 };
        comptime std.debug.assert(rects.len == weights.len);

        c.KW_RectFillParentVertically(&geometry, &rects, &weights, weights.len, 10);
        const label = c.KW_CreateLabel(self.gui, frame, c"Dodger", &labelrect);
        const playbutton = c.KW_CreateButtonAndLabel(self.gui, frame, c"Play", &playbuttonrect) orelse unreachable;
        const highScoresButton = c.KW_CreateButtonAndLabel(self.gui, frame, c"High Scores", &highScoresRect) orelse unreachable;
        const exitButton = c.KW_CreateButtonAndLabel(self.gui, frame, c"Exit", &exitRect) orelse unreachable;

        const iconrect = c.KW_Rect{ .x = 0, .y = 48, .w = 24, .h = 24 };
        c.KW_SetLabelIcon(label, &iconrect);

        c.KW_SetWidgetUserData(playbutton, @ptrCast(*c_void, self.playButtonPressed));
        c.KW_AddWidgetMouseDownHandler(playbutton, onPressed);

        c.KW_SetWidgetUserData(highScoresButton, @ptrCast(*c_void, self.highScoresButtonPressed));
        c.KW_AddWidgetMouseDownHandler(highScoresButton, onPressed);

        c.KW_SetWidgetUserData(exitButton, @ptrCast(*c_void, self.exitButtonPressed));
        c.KW_AddWidgetMouseDownHandler(exitButton, onPressed);
    }

    fn onEvent(screen: *Screen, event: ScreenEvent) ?Transition {
        const self = @fieldParentPtr(Self, "screen", screen);

        if (ScreenEventTag(event.type) == .KeyPressed and event.type.KeyPressed == c.SDLK_ESCAPE) {
            return Transition{ .PopScreen = {} };
        }

        c.KW_ProcessEvent(self.gui, event.sdl_event);

        return null;
    }

    fn update(screen: *Screen, ctx: *Context, keys: [*]const u8) ?Transition {
        const self = @fieldParentPtr(Self, "screen", screen);

        if (self.playButtonPressed.*) {
            const play_screen = PlayScreen.init(self.allocator) catch unreachable;
            return Transition{ .PushScreen = &play_screen.screen };
        }

        if (self.highScoresButtonPressed.*) {
            const high_scores_screen = HighScoresScreen.init(self.allocator, ctx) catch unreachable;
            return Transition{ .PushScreen = &high_scores_screen.screen };
        }

        if (self.exitButtonPressed.*) {
            return Transition{ .PopScreen = {} };
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
        self.allocator.destroy(self.highScoresButtonPressed);
        self.allocator.destroy(self);
    }

    extern fn onPressed(widget: ?*c.KW_Widget, mouse_button: c_int) void {
        const btnPressed = @ptrCast(*bool, c.KW_GetWidgetUserData(widget));
        btnPressed.* = true;
    }
};
