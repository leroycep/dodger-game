const std = @import("std");
const Allocator = std.mem.Allocator;
const StringHashMap = std.StringHashMap;
const c = @import("c.zig");
const sdl = @import("sdl.zig");
const EnemyBreed = @import("game/enemy.zig").EnemyBreed;
const constants = @import("constants.zig");
const Vec2 = @import("game/physics.zig").Vec2;

pub const Assets = struct {
    allocator: *Allocator,
    rootDir: []const u8,
    textures: StringHashMap(*c.GPU_Image),
    breeds: StringHashMap(EnemyBreed),

    pub fn init(allocator: *Allocator, rootDir: []const u8) Assets {
        return Assets{
            .allocator = allocator,
            .rootDir = rootDir,
            .textures = StringHashMap(*c.GPU_Image).init(allocator),
            .breeds = StringHashMap(EnemyBreed).init(allocator),
        };
    }

    pub fn loadTexture(self: *Assets, name: []const u8, filepath: []const u8) !void {
        const path = try std.fs.path.join(self.allocator, [_][]const u8{ self.rootDir, filepath });
        const cpath = try std.fmt.allocPrint(self.allocator, "{}\x00", path);

        const image = c.GPU_LoadImage(cpath.ptr);
        _ = try self.textures.put(name, image);

        self.allocator.free(cpath);
        self.allocator.free(path);
    }

    pub fn tex(self: *Assets, name: []const u8) *c.GPU_Image {
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

pub fn initAssets(assets: *Assets) !void {
    try assets.loadTexture("background", "background.png");
    try assets.loadTexture("guy", "guy.png");
    try assets.loadTexture("badguy", "badguy.png");

    _ = try assets.breeds.put("badguy", EnemyBreed{
        .texture = assets.tex("badguy"),
        .ticksOnFloor = constants.ENEMY_TICKS_ON_FLOOR,
        .collisionRectSize = Vec2{ .x = 27, .y = 28 },
    });
}
