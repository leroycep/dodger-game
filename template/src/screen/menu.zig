const std = @import("std");
const c = @import("../c.zig");
const sdl = @import("../sdl.zig");
usingnamespace @import("screen.zig");
const PlayScreen = @import("play.zig").PlayScreen;

pub const MenuScreen = struct {
    allocator: *std.mem.Allocator,
    screen: Screen,
    gui: *c.KW_GUI,
    playButtonPressed: *bool,

    const Self = @This();

    pub fn init(allocator: *std.mem.Allocator, gui: *c.KW_GUI, button: *c.KW_Widget) !*Self {
        const self = try allocator.create(Self);
        self.allocator = allocator;
        self.screen = Screen{
            .startFn = start,
            .updateFn = update,
            .renderFn = render,
            .deinitFn = deinit,
        };
        self.gui = gui;
        self.playButtonPressed = try allocator.create(bool);
        self.playButtonPressed.* = false;

        c.KW_SetWidgetUserData(button, @ptrCast(*c_void, self.playButtonPressed));
        c.KW_AddWidgetMouseDownHandler(button, onPlayPressed);

        return self;
    }

    fn start(screen: *Screen) void {
        const self = @fieldParentPtr(Self, "screen", screen);
        self.playButtonPressed.* = false;
    }

    fn update(screen: *Screen, keys: [*]const u8) Transition {
        const self = @fieldParentPtr(Self, "screen", screen);

        c.KW_ProcessEvents(self.gui);

        if (self.playButtonPressed.*) {
            const play_screen = PlayScreen.init(self.allocator) catch unreachable;
            return Transition{ .PushScreen = &play_screen.screen };
        }

        if (keys[sdl.scnFromKey(c.SDLK_ESCAPE)] == 1) {
            return Transition{ .PopScreen = {} };
        }
        return Transition{ .None = {} };
    }

    fn render(screen: *Screen, ren: *c.SDL_Renderer) anyerror!void {
        const self = @fieldParentPtr(Self, "screen", screen);

        c.KW_Paint(self.gui);
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
