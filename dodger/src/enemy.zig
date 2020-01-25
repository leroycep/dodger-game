const sdl = @import("sdl.zig");

pub const EnemyBreed = struct {
    texture: []const u8,
};

pub const Enemy = struct {
    breed: *EnemyBreed,
    pos: sdl.SDL_Point,
};


