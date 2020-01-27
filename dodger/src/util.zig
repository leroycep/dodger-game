const std = @import("std");
const sdl = @import("sdl.zig");

pub fn distance(p1: sdl.SDL_Point, p2: sdl.SDL_Point) f32 {
    var a = @intToFloat(f32, p1.x - p2.x);
    var b = @intToFloat(f32, p1.y - p2.y);
    return @sqrt(f32, (a * a) + (b * b));
}
