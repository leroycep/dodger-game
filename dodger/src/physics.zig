const std = @import("std");
const sdl = @import("sdl.zig");
const constants = @import("constants.zig");

pub const Vec2 = struct {
    x: f32,
    y: f32,

    pub fn zero() Vec2 {
        return Vec2{
            .x = 0,
            .y = 0,
        };
    }

    pub fn init(x: f32, y: f32) Vec2 {
        return Vec2{
            .x = x,
            .y = y,
        };
    }
};

pub fn distance(p1: Vec2, p2: Vec2) f32 {
    var a = p1.x - p2.x;
    var b = p1.y - p2.y;
    return @sqrt(f32, (a * a) + (b * b));
}

pub const PhysicsComponent = struct {
    pos: Vec2,
    size: Vec2,
    vel: Vec2,

    pub fn init(x: f32, y: f32) PhysicsComponent {
        return PhysicsComponent{
            .pos = Vec2.init(x, y),
            .size = Vec2.zero(),
            .vel = Vec2.zero(),
        };
    }

    pub fn applyGravity(self: *PhysicsComponent) void {
        self.vel.y += constants.GRAVITY;
        if (self.vel.y > MAX_VELOCITY) {
            self.vel.y = MAX_VELOCITY;
        }
    }
};
