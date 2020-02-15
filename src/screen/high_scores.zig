const std = @import("std");
const c = @import("../c.zig");
const sdl = @import("../sdl.zig");
usingnamespace @import("screen.zig");
const Context = @import("../context.zig").Context;
const PlayScreen = @import("play.zig").PlayScreen;
const leaderboard = @import("../leaderboard.zig");
const LeaderBoard = leaderboard.LeaderBoard;
const Score = leaderboard.Score;
const ArrayList = std.ArrayList;

pub const HighScoresScreen = struct {
    allocator: *std.mem.Allocator,
    screen: Screen,
    scores: ArrayList(Score),

    gui: *c.KW_GUI,
    textBuf: []u8,
    playAgainPressed: *bool,
    mainMenuPressed: *bool,

    const Self = @This();

    pub fn init(allocator: *std.mem.Allocator, ctx: *Context) !*Self {
        const self = try allocator.create(Self);
        self.allocator = allocator;
        self.screen = Screen{
            .startFn = start,
            .onEventFn = onEvent,
            .updateFn = update,
            .renderFn = render,
            .deinitFn = deinit,
        };
        self.scores = ArrayList(Score).init(self.allocator);
        try ctx.leaderboard.get_topten_scores(&self.scores);

        self.textBuf = try allocator.alloc(u8, 50);
        self.playAgainPressed = try allocator.create(bool);
        self.mainMenuPressed = try allocator.create(bool);

        return self;
    }

    fn start(screen: *Screen, ctx: *Context) void {
        const self = @fieldParentPtr(Self, "screen", screen);

        self.playAgainPressed.* = false;
        self.mainMenuPressed.* = false;

        self.gui = c.KW_Init(ctx.kw_driver, ctx.kw_tileset) orelse unreachable;

        var windowrect = c.KW_Rect{ .x = 0, .y = 0, .w = 0, .h = 0 };
        c.SDL_GetWindowSize(ctx.win, &windowrect.w, &windowrect.h);

        var geometry = c.KW_Rect{ .x = 0, .y = 0, .w = 500, .h = 350 };
        c.KW_RectCenterInParent(&windowrect, &geometry);
        var frame = c.KW_CreateFrame(self.gui, null, &geometry);

        // Do vertical layout
        var titlerect = c.KW_Rect{ .x = 0, .y = 0, .w = 500, .h = 0 };
        var scoresRects = [_]c.KW_Rect{c.KW_Rect{ .x = 100, .y = 0, .w = 300, .h = 0 }} ** 10;
        var buttonsrect = c.KW_Rect{ .x = 90, .y = 0, .w = 320, .h = 0 };

        var rects = [_]?*c.KW_Rect{null} ** 12;
        var weights = [_]c_uint{1} ** 12;
        rects[0] = &titlerect;
        weights[0] = 4;
        for (scoresRects) |_, idx| {
            rects[idx + 1] = &scoresRects[idx];
        }
        rects[11] = &buttonsrect;
        weights[11] = 4;
        comptime std.debug.assert(rects.len == weights.len);

        c.KW_RectFillParentVertically(&geometry, &rects, &weights, weights.len, 10);
        // END verical layout

        // Layout buttons
        var mainmenurect: c.KW_Rect = c.KW_Rect{ .x = 0, .y = 0, .w = 0, .h = 30 };
        var playagainrect: c.KW_Rect = c.KW_Rect{ .x = 0, .y = 0, .w = 0, .h = 30 };

        var btnrects = [_]?*c.KW_Rect{ &mainmenurect, &playagainrect };
        var btnweights = [_]c_uint{ 1, 1 };
        comptime std.debug.assert(btnrects.len == btnweights.len);

        c.KW_RectFillParentHorizontally(&buttonsrect, &btnrects, &btnweights, btnweights.len, 30, c.KW_RECT_ALIGN_MIDDLE);
        // END Layout buttons

        // Create widgets
        _ = c.KW_CreateLabel(self.gui, frame, c"HIGH SCORES", &titlerect);
        var btnframe = c.KW_CreateFrame(self.gui, frame, &buttonsrect);
        for (self.scores.toSlice()) |score, idx| {
            if (idx >= 10) {
                break;
            }
            const srect = scoresRects[idx];
            const splitw = srect.w - 2 * @divFloor(srect.w, 3);
            const nameRect = c.KW_Rect{ .x = srect.x, .y = srect.y, .w = splitw, .h = srect.h };
            const scoreRect = c.KW_Rect{ .x = srect.x + splitw, .y = srect.y, .w = srect.w - splitw, .h = srect.h };

            const nameText = std.fmt.bufPrint(self.textBuf, "{}\x00", score.name.toSlice()) catch unreachable;
            const nameLabel = c.KW_CreateLabel(self.gui, frame, nameText.ptr, &nameRect);
            c.KW_SetLabelAlignment(nameLabel, c.KW_LABEL_ALIGN_LEFT, 0, c.KW_LABEL_ALIGN_MIDDLE, 0);

            const scoreText = std.fmt.bufPrint(self.textBuf, "{d:0.2}\x00", score.score) catch unreachable;
            const scoreLabel = c.KW_CreateLabel(self.gui, frame, scoreText.ptr, &scoreRect);
            c.KW_SetLabelAlignment(scoreLabel, c.KW_LABEL_ALIGN_RIGHT, 0, c.KW_LABEL_ALIGN_MIDDLE, 0);
        }
        const mainmenubtn = c.KW_CreateButtonAndLabel(self.gui, btnframe, c"Main Menu", &mainmenurect) orelse unreachable;
        const playagainbtn = c.KW_CreateButtonAndLabel(self.gui, btnframe, c"Play Again", &playagainrect) orelse unreachable;
        // END Create widgets

        // Setup button mouse down handlers
        c.KW_SetWidgetUserData(mainmenubtn, @ptrCast(*c_void, self.mainMenuPressed));
        c.KW_AddWidgetMouseDownHandler(mainmenubtn, onPressed);

        c.KW_SetWidgetUserData(playagainbtn, @ptrCast(*c_void, self.playAgainPressed));
        c.KW_AddWidgetMouseDownHandler(playagainbtn, onPressed);
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

        if (self.mainMenuPressed.*) {
            return Transition{ .PopScreen = {} };
        }

        if (self.playAgainPressed.*) {
            const play_screen = PlayScreen.init(self.allocator) catch unreachable;
            return Transition{ .ReplaceScreen = &play_screen.screen };
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

        for (self.scores.toSlice()) |s| {
            s.deinit();
        }
        self.scores.deinit();

        self.allocator.destroy(self.mainMenuPressed);
        self.allocator.destroy(self.playAgainPressed);
        self.allocator.destroy(self);
    }

    extern fn onPressed(widget: ?*c.KW_Widget, mouse_button: c_int) void {
        const boolPtr = @ptrCast(*bool, c.KW_GetWidgetUserData(widget));
        boolPtr.* = true;
    }
};
