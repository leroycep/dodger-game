const std = @import("std");
const c = @import("c.zig");

pub const Error = error{
    InitFailed,
    CouldntCreateWindow,
    CouldntCreateRenderer,
    CouldntLoadBMP,
    CouldntCreateTexture,
    ImgInit,
};

pub fn logErr(err: Error) Error {
    std.debug.warn("{} error: {}", err, c.SDL_GetError());
    return err;
}

pub fn loadTexture(ren: *c.SDL_Renderer, file: [*]const u8) Error!*c.SDL_Texture {
    const texture = c.IMG_LoadTexture(ren, file) orelse {
        return logErr(error.CouldntCreateTexture);
    };

    return texture;
}

/// Renders a texture with its center at the specified position
pub fn renderTexture(ren: *c.SDL_Renderer, tex: *c.SDL_Texture, x: f32, y: f32) void {
    // Setup destination rectangle to be at the right place
    var dst: c.SDL_Rect = undefined;

    // Query the texture's size
    _ = c.SDL_QueryTexture(tex, null, null, &dst.w, &dst.h);

    dst.x = @floatToInt(c_int, x) - @divTrunc(dst.w, 2);
    dst.y = @floatToInt(c_int, y) - @divTrunc(dst.h, 2);

    // Render the texture to screen at the destination rectangle
    _ = c.SDL_RenderCopy(ren, tex, null, &dst);
}

pub fn scnFromKey(key: c.SDL_Keycode) usize {
    return @intCast(usize, @enumToInt(c.SDL_GetScancodeFromKey(key)));
}
