const std = @import("std");
const Allocator = std.mem.Allocator;
const StringHashMap = std.StringHashMap;
const c = @import("../c.zig");
const sdl = @import("../sdl.zig");
const EnemyBreed = @import("enemy.zig").EnemyBreed;
const constants = @import("constants.zig");

pub const Assets = struct {
    textures: StringHashMap(*c.SDL_Texture),
    breeds: StringHashMap(EnemyBreed),

    pub fn init(allocator: *Allocator) Assets {
        return Assets{
            .textures = StringHashMap(*c.SDL_Texture).init(allocator),
            .breeds = StringHashMap(EnemyBreed).init(allocator),
        };
    }

    pub fn loadTexture(self: *Assets, ren: *c.SDL_Renderer, name: []const u8, filepath: [*]const u8) !void {
        _ = try self.textures.put(name, try sdl.loadTexture(ren, filepath));
    }

    pub fn tex(self: *Assets, name: []const u8) *c.SDL_Texture {
        return self.textures.get(name).?.value;
    }

    pub fn deinit(self: *Assets) void {
        var iter = self.textures.iterator();
        while (iter.next()) |texture| {
            c.SDL_DestroyTexture(texture.value);
        }
        self.textures.deinit();
        self.breeds.deinit();
    }
};

pub fn initAssets(assets: *Assets, ren: *c.SDL_Renderer) !void {
    try assets.loadTexture(ren, "background", c"assets/background.png");
    try assets.loadTexture(ren, "guy", c"assets/guy.png");
    try assets.loadTexture(ren, "badguy", c"assets/badguy.png");

    _ = try assets.breeds.put("badguy", EnemyBreed{ .texture = assets.tex("badguy"), .ticksOnFloor = constants.ENEMY_TICKS_ON_FLOOR });
}
