const c = @import("../c.zig");

pub const TransitionTag = enum {
    PushScreen,
    PopScreen,
    None,
};

pub const Transition = union(TransitionTag) {
    PushScreen: *Screen,
    PopScreen: void,
    None: void,
};

pub const Screen = struct {
    startFn: ?fn (self: *Screen) void = null,
    updateFn: fn (self: *Screen, keys: [*]const u8) Transition,
    renderFn: fn (self: *Screen, *c.SDL_Renderer) anyerror!void,
    stopFn: ?fn (self: *Screen) void = null,
    deinitFn: ?fn (self: *Screen) void = null,

    pub fn start(self: *Screen) void {
        if (self.startFn) |func| {
            return func(self);
        }
    }

    pub fn update(self: *Screen, keys: [*]const u8) Transition {
        return self.updateFn(self, keys);
    }

    pub fn render(self: *Screen, ren: *c.SDL_Renderer) !void {
        return self.renderFn(self, ren);
    }

    pub fn stop(self: *Screen) void {
        if (self.stopFn) |func| {
            return func(self);
        }
    }

    pub fn deinit(self: *Screen) void {
        if (self.deinitFn) |func| {
            func(self);
        }
    }
};

