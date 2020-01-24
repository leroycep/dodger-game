const std = @import("std");

usingnamespace @cImport({
    @cInclude("SDL2/SDL.h");
});

pub const Error = error {
    InitFailed,
    CouldntCreateWindow,
    CouldntCreateRenderer,
    CouldntLoadBMP,
    CouldntCreateTexture,
};

pub fn logErr(err: Error) Error {
    std.debug.warn("{} error: {}", err, SDL_GetError());
    return err;
}

pub fn loadTexture(ren: *SDL_Renderer, file: [*]const u8) Error!*SDL_Texture {
    const bmp = SDL_LoadBMP_RW(SDL_RWFromFile(file, c"rb"), 1);
    if (bmp == null) {
        return logErr(error.CouldntLoadBMP);
    }
    defer SDL_FreeSurface(bmp);

    const texture = SDL_CreateTextureFromSurface(ren, bmp) orelse {
        return logErr(error.CouldntCreateTexture);
    };

    return texture;
}
