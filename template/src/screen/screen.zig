const c = @import("../c.zig");
const Context = @import("../context.zig").Context;

pub const TransitionTag = enum {
    PushScreen,
    PopScreen,
};

pub const Transition = union(TransitionTag) {
    PushScreen: *Screen,
    PopScreen: void,
};

pub const Screen = struct {
    startFn: ?fn (self: *Screen, *Context) void = null,
    updateFn: fn (self: *Screen, keys: [*]const u8) ?Transition,
    renderFn: fn (self: *Screen, *c.SDL_Renderer) anyerror!void,
    stopFn: ?fn (self: *Screen, *Context) void = null,
    deinitFn: ?fn (self: *Screen) void = null,

    pub fn start(self: *Screen, ctx: *Context) void {
        if (self.startFn) |func| {
            return func(self, ctx);
        }
    }

    pub fn update(self: *Screen, keys: [*]const u8) ?Transition {
        return self.updateFn(self, keys);
    }

    pub fn render(self: *Screen, ren: *c.SDL_Renderer) !void {
        return self.renderFn(self, ren);
    }

    pub fn stop(self: *Screen, ctx: *Context) void {
        if (self.stopFn) |func| {
            return func(self, ctx);
        }
    }

    pub fn deinit(self: *Screen) void {
        if (self.deinitFn) |func| {
            func(self);
        }
    }
};
