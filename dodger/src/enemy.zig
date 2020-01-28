const c = @import("c.zig");
const PhysicsComponent = @import("physics.zig").PhysicsComponent;

pub const EnemyBreed = struct {
    texture: *c.SDL_Texture,
    ticksOnFloor: u32,
};

pub const Enemy = struct {
    breed: *EnemyBreed,
    physics: PhysicsComponent,
    ticksLeftOnFloor: u32,
};
