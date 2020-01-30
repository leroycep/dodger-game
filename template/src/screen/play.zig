const std = @import("std");
const c = @import("../c.zig");
const sdl = @import("../sdl.zig");
usingnamespace @import("screen.zig");

pub const PlayScreen = struct {
    allocator: *std.mem.Allocator,
    screen: Screen,

    const Self = @This();

    pub fn init(allocator: *std.mem.Allocator) !*Self {
        const self = try allocator.create(PlayScreen);
        self.allocator = allocator;
        self.screen = Screen{
            .onEventFn = onEvent,
            .renderFn = render,
            .deinitFn = deinit,
        };
        return self;
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

    fn render(screen: *Screen, ren: *c.SDL_Renderer) anyerror!void {
        const self = @fieldParentPtr(Self, "screen", screen);
    }

    fn deinit(screen: *Screen) void {
        const self = @fieldParentPtr(Self, "screen", screen);
        self.allocator.destroy(self);
    }
};
