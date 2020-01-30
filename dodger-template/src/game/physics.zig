const std = @import("std");
const sdl = @import("sdl.zig");
const constants = @import("../constants.zig");
const World = @import("world.zig").World;

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

    pub fn init(x: f32, y: f32, w: f32, h: f32) PhysicsComponent {
        return PhysicsComponent{
            .pos = Vec2.init(x, y),
            .size = Vec2.init(w, h),
            .vel = Vec2.zero(),
        };
    }

    pub fn applyGravity(self: *PhysicsComponent) void {
        self.vel.y += constants.GRAVITY;
        if (self.vel.y > constants.MAX_VELOCITY) {
            self.vel.y = constants.MAX_VELOCITY;
        }
    }

    pub fn isOnFloor(self: *PhysicsComponent, world: *World) bool {
        return (self.pos.y + self.size.y / 2 == world.floor);
    }

    pub fn update(self: *PhysicsComponent, world: *World) void {
        var nextX = self.pos.x;
        nextX += self.vel.x;
        var left = nextX - self.size.x / 2;
        var right = nextX + self.size.x / 2;
        if (left < world.leftWall) {
            nextX = world.leftWall + self.size.x / 2;
        } else if (right > world.rightWall) {
            nextX = world.rightWall - self.size.x / 2;
        }
        self.pos.x = nextX;

        var nextY = self.pos.y;
        nextY += self.vel.y;
        var bottom = nextY + self.size.y / 2;
        if (bottom > world.floor) {
            nextY = world.floor - self.size.y / 2;
            self.vel.y = 0;
        }
        self.pos.y = nextY;
    }
};
