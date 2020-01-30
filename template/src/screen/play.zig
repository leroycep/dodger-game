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
            .updateFn = update,
            .renderFn = render,
            .deinitFn = deinit,
        };
        return self;
    }

    fn update(screen: *Screen, keys: [*]const u8) ?Transition {
        const self = @fieldParentPtr(Self, "screen", screen);
        if (keys[sdl.scnFromKey(c.SDLK_ESCAPE)] == 1) {
            return Transition{ .PopScreen = {} };
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
