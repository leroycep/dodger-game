const c = @import("../c.zig");
const physics = @import("physics.zig");
const PhysicsComponent = physics.PhysicsComponent;
const Tween = @import("../tween.zig").Tween;

pub const EnemyBreed = struct {
    texture: *c.GPU_Image,
    collisionRectSize: physics.Vec2,
    ticksOnFloor: u32,

    fn initEnemy(self: *EnemyBreed, enemy: *Enemy) void {
        enemy.breed = self;
        enemy.physics = PhysicsComponent.init(0, 0, self.collisionRectSize.x, self.collisionRectSize.y);
        enemy.ticksLeftOnFloor = 0;

        // Rendering stuff
        enemy.scaleX = 1;
        enemy.targetScaleX = 1;
        enemy.previousVel = enemy.physics.vel;
        enemy.scaleY = 1;
    }
};

pub const Enemy = struct {
    breed: *EnemyBreed,
    physics: PhysicsComponent,
    ticksLeftOnFloor: u32,
    dead: bool,

    // Rendering stuff
    scaleX: f32 = 1,
    targetScaleX: f32 = 1,

    previousVel: physics.Vec2,
    landingTween: Tween,
    scaleY: f32 = 1,

    deathTween: Tween,
};
