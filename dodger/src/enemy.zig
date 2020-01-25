const sdl = @import("sdl.zig");

pub const EnemyBreed = struct {
    texture: *sdl.SDL_Texture,
};

pub const Enemy = struct {
    breed: *EnemyBreed,
    pos: sdl.SDL_Point,
};


