const std = @import("std");
const c = @import("../c.zig");
const sdl = @import("../sdl.zig");
usingnamespace @import("screen.zig");
const Context = @import("../context.zig").Context;
const leaderboard = @import("../leaderboard.zig");
const HighScoresScreen = @import("high_scores.zig").HighScoresScreen;
const ArrayList = std.ArrayList;

pub const EnterNameScreen = struct {
    allocator: *std.mem.Allocator,
    score: f64,
    screen: Screen,
    gui: *c.KW_GUI,
    textBuf: []u8,
    namebox: *c.KW_Widget,
    okayPressed: *bool,
    cancelPressed: *bool,

    const Self = @This();

    pub fn init(allocator: *std.mem.Allocator, score: f64) !*Self {
        const self = try allocator.create(Self);
        self.allocator = allocator;
        self.score = score;
        self.screen = Screen{
            .startFn = start,
            .onEventFn = onEvent,
            .updateFn = update,
            .renderFn = render,
            .deinitFn = deinit,
        };

        self.textBuf = try allocator.alloc(u8, 50);
        self.okayPressed = try allocator.create(bool);
        self.cancelPressed = try allocator.create(bool);

        return self;
    }

    fn start(screen: *Screen, ctx: *Context) void {
        const self = @fieldParentPtr(Self, "screen", screen);

        self.okayPressed.* = false;
        self.cancelPressed.* = false;

        self.gui = c.KW_Init(ctx.kw_driver, ctx.kw_tileset) orelse unreachable;

        var windowrect = c.KW_Rect{ .x = 0, .y = 0, .w = 0, .h = 0 };
        c.SDL_GetWindowSize(ctx.win, &windowrect.w, &windowrect.h);

        var geometry = c.KW_Rect{ .x = 0, .y = 0, .w = 500, .h = 240 };
        c.KW_RectCenterInParent(&windowrect, &geometry);
        var frame = c.KW_CreateFrame(self.gui, null, &geometry);

        // Do vertical layout
        var titlerect = c.KW_Rect{ .x = 0, .y = 0, .w = 500, .h = 50 };
        var label0rect = c.KW_Rect{ .x = 0, .y = 0, .w = 500, .h = 20 };
        var label1rect = c.KW_Rect{ .x = 0, .y = 0, .w = 500, .h = 20 };
        var label2rect = c.KW_Rect{ .x = 0, .y = 0, .w = 500, .h = 20 };
        var nameboxrect = c.KW_Rect{ .x = 100, .y = 0, .w = 300, .h = 20 };
        var buttonsrect = c.KW_Rect{ .x = 90, .y = 0, .w = 320, .h = 20 };

        var rects = [_]?*c.KW_Rect{ &titlerect, &label0rect, &label1rect, &label2rect, &nameboxrect, &buttonsrect };
        var weights = [_]c_uint{ 4, 2, 2, 2, 4, 6 };
        comptime std.debug.assert(rects.len == weights.len);

        c.KW_RectFillParentVertically(&geometry, &rects, &weights, weights.len, 10);
        // END verical layout

        // Layout buttons
        var cancelrect: c.KW_Rect = c.KW_Rect{ .x = 0, .y = 0, .w = 0, .h = 30 };
        var okayrect: c.KW_Rect = c.KW_Rect{ .x = 0, .y = 0, .w = 0, .h = 30 };

        var btnrects = [_]?*c.KW_Rect{ &cancelrect, &okayrect };
        var btnweights = [_]c_uint{ 1, 1 };
        comptime std.debug.assert(btnrects.len == btnweights.len);

        c.KW_RectFillParentHorizontally(&buttonsrect, &btnrects, &btnweights, btnweights.len, 30, c.KW_RECT_ALIGN_MIDDLE);
        // END Layout buttons

        // Write score to textBuf
        const scoreText = std.fmt.bufPrint(self.textBuf, "{d:0.2} seconds\x00", self.score) catch unreachable;
        // END Write score to textBuf

        // Create widgets
        _ = c.KW_CreateLabel(self.gui, frame, c"GAME OVER", &titlerect);
        _ = c.KW_CreateLabel(self.gui, frame, c"You Lasted:", &label0rect);
        _ = c.KW_CreateLabel(self.gui, frame, scoreText.ptr, &label1rect);
        _ = c.KW_CreateLabel(self.gui, frame, c"Your Name:", &label2rect);
        self.namebox = c.KW_CreateEditbox(self.gui, frame, c"", &nameboxrect) orelse unreachable;
        var btnframe = c.KW_CreateFrame(self.gui, frame, &buttonsrect);
        const cancelbutton = c.KW_CreateButtonAndLabel(self.gui, btnframe, c"Cancel", &cancelrect) orelse unreachable;
        const okaybutton = c.KW_CreateButtonAndLabel(self.gui, btnframe, c"Okay", &okayrect) orelse unreachable;
        // END Create widgets

        // Setup button mouse down handlers
        c.KW_SetWidgetUserData(okaybutton, @ptrCast(*c_void, self.okayPressed));
        c.KW_AddWidgetMouseDownHandler(okaybutton, onPressed);

        c.KW_SetWidgetUserData(cancelbutton, @ptrCast(*c_void, self.cancelPressed));
        c.KW_AddWidgetMouseDownHandler(cancelbutton, onPressed);
        // END Setup button mouse down handlers
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


        if (self.cancelPressed.*) {
            return Transition{ .PopScreen = {} };
        }

        if (self.okayPressed.*) {
            const text = c.KW_GetEditboxText(self.namebox) orelse return null;
            const text_len = c.strlen(text);
            ctx.leaderboard.add_score(text[0..text_len], self.score) catch unreachable;

            const newScreen = HighScoresScreen.init(self.allocator, ctx) catch unreachable;

            return Transition{ .ReplaceScreen = &newScreen.screen };
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
        self.allocator.destroy(self.okayPressed);
        self.allocator.destroy(self.cancelPressed);
        self.allocator.destroy(self);
    }

    extern fn onPressed(widget: ?*c.KW_Widget, mouse_button: c_int) void {
        const boolPtr = @ptrCast(*bool, c.KW_GetWidgetUserData(widget));
        boolPtr.* = true;
    }
};
