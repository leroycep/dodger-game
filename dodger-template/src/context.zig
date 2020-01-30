const std = @import("std");
const c = @import("c.zig");
const Assets = @import("assets.zig").Assets;

pub const Context = struct {
    win: *c.SDL_Window,
    kw_driver: *c.KW_RenderDriver,
    kw_tileset: *c.KW_Surface,
    assets: *Assets,
};
