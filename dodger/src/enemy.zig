const sdl = @import("sdl.zig");
const PhysicsComponent = @import("physics.zig").PhysicsComponent;

pub const EnemyBreed = struct {
    texture: *sdl.SDL_Texture,
    ticksOnFloor: u32,
};

pub const Enemy = struct {
    breed: *EnemyBreed,
    physics: PhysicsComponent,
    ticksLeftOnFloor: u32,
};
