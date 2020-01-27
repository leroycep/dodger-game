const sdl = @import("sdl.zig");
const PhysicsComponent = @import("physics.zig").PhysicsComponent;

pub const EnemyBreed = struct {
    texture: *sdl.SDL_Texture,
};

pub const Enemy = struct {
    breed: *EnemyBreed,
    physics: PhysicsComponent,
};
