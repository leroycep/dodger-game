const c = @import("../c.zig");
const Context = @import("../context.zig").Context;

pub const TransitionTag = enum {
    PushScreen,
    ReplaceScreen,
    PopScreen,
};

pub const Transition = union(TransitionTag) {
    PushScreen: *Screen,
    ReplaceScreen: *Screen,
    PopScreen: void,
};

pub const ScreenEventTag = enum {
    KeyPressed,
};

pub const ScreenEvent = union(ScreenEventTag) {
    KeyPressed: c.SDL_Keycode,
};

pub const Screen = struct {
    startFn: ?fn (self: *Screen, *Context) void = null,
    onEventFn: ?fn (self: *Screen, event: ScreenEvent) ?Transition = null,
    updateFn: ?fn (self: *Screen, *Context, keys: [*]const u8) ?Transition = null,
    renderFn: fn (self: *Screen, *Context, *c.GPU_Target) anyerror!void,
    stopFn: ?fn (self: *Screen, *Context) void = null,
    deinitFn: ?fn (self: *Screen) void = null,

    pub fn start(self: *Screen, ctx: *Context) void {
        if (self.startFn) |func| {
            return func(self, ctx);
        }
    }

    pub fn onEvent(self: *Screen, event: ScreenEvent) ?Transition {
        if (self.onEventFn) |func| {
            return func(self, event);
        }
        return null;
    }

    pub fn update(self: *Screen, ctx: *Context, keys: [*]const u8) ?Transition {
        if (self.updateFn) |func| {
            return func(self, ctx, keys);
        }
        return null;
    }

    pub fn render(self: *Screen, ctx: *Context, gpuTarget: *c.GPU_Target) !void {
        return self.renderFn(self, ctx, gpuTarget);
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
