const std = @import("std");
const sdl = @import("sdl.zig");
usingnamespace @import("constants.zig");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;

pub fn main() !void {
    if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO) != 0) {
        return sdl.logErr(error.InitFailed);
    }
    defer sdl.SDL_Quit();

    const win = sdl.SDL_CreateWindow(c"Hello World!", 100, 100, 640, 480, sdl.SDL_WINDOW_SHOWN) orelse {
        return sdl.logErr(error.CouldntCreateWindow);
    };
    defer sdl.SDL_DestroyWindow(win);

    const ren = sdl.SDL_CreateRenderer(win, -1, sdl.SDL_RENDERER_ACCELERATED | sdl.SDL_RENDERER_PRESENTVSYNC) orelse {
        return sdl.logErr(error.CouldntCreateRenderer);
    };
    defer sdl.SDL_DestroyRenderer(ren);

    if ((sdl.IMG_Init(sdl.IMG_INIT_PNG) & sdl.IMG_INIT_PNG) != sdl.IMG_INIT_PNG) {
        return sdl.logErr(error.ImgInit);
    }

    const allocator = std.heap.direct_allocator;

    var quit = false;
    var e: sdl.SDL_Event = undefined;
    const keys = sdl.SDL_GetKeyboardState(null);
    var game = try Game.init(allocator, ren);
    defer game.deinit();

    while (!quit) {
        while (sdl.SDL_PollEvent(&e) != 0) {
            if (e.type == sdl.SDL_QUIT) {
                quit = true;
            }
            if (e.type == sdl.SDL_KEYDOWN) {
                if (e.key.keysym.sym == sdl.SDLK_ESCAPE) {
                    quit = true;
                }
            }
        }

        game.update(keys);
        game.render(ren);
    }
}

const InputMap = struct {
    up: usize,
    down: usize,
    left: usize,
    right: usize,
};

const Textures = struct {
    background: *sdl.SDL_Texture,
    guy: *sdl.SDL_Texture,
    badguy: *sdl.SDL_Texture,

    fn destroy(self: *Textures) void {
        sdl.SDL_DestroyTexture(self.background);
        sdl.SDL_DestroyTexture(self.guy);
        sdl.SDL_DestroyTexture(self.badguy);
    }
};

const EnemyBreed = struct {
    texture: *sdl.SDL_Texture,
};

const Enemy = struct {
    breed: *EnemyBreed,
    pos: sdl.SDL_Point,
};

const Game = struct {
    allocator: *Allocator,
    textures: Textures,
    playerPos: sdl.SDL_Point,
    inputMap: InputMap,
    enemyBreeds: [1]EnemyBreed,
    enemies: ArrayList(Enemy),

    fn init(allocator: *Allocator, ren: *sdl.SDL_Renderer) !*Game {
        var game = try allocator.create(Game);
        game.textures = Textures{
            .background = try sdl.loadTexture(ren, c"assets/texture.png"),
            .guy = try sdl.loadTexture(ren, c"assets/guy.png"),
            .badguy = try sdl.loadTexture(ren, c"assets/badguy.png"),
        };
        game.allocator = allocator;
        game.playerPos = sdl.SDL_Point{
            .x = 50,
            .y = 50,
        };
        game.inputMap = InputMap{
            .up = @intCast(usize, @enumToInt(sdl.SDL_GetScancodeFromKey(sdl.SDLK_UP))),
            .down = @intCast(usize, @enumToInt(sdl.SDL_GetScancodeFromKey(sdl.SDLK_DOWN))),
            .left = @intCast(usize, @enumToInt(sdl.SDL_GetScancodeFromKey(sdl.SDLK_LEFT))),
            .right = @intCast(usize, @enumToInt(sdl.SDL_GetScancodeFromKey(sdl.SDLK_RIGHT))),
        };
        game.enemyBreeds = [_]EnemyBreed{
            EnemyBreed{
                .texture = game.textures.badguy,
            },
        };
        game.enemies = ArrayList(Enemy).init(allocator);
        try game.enemies.append(Enemy{
            .breed = &(game.enemyBreeds[0]),
            .pos = point(100, 0),
        });
        return game;
    }

    fn update(self: *Game, keys: [*]const u8) void {
        if (keys[self.inputMap.left] == 1) {
            self.playerPos.x -= PLAYER_SPEED;
        }
        if (keys[self.inputMap.right] == 1) {
            self.playerPos.x += PLAYER_SPEED;
        }
        if (keys[self.inputMap.up] == 1) {
            self.playerPos.y -= PLAYER_SPEED;
        }
        if (keys[self.inputMap.down] == 1) {
            self.playerPos.y += PLAYER_SPEED;
        }

        for (self.enemies.toSlice()) |*enemy| {
            enemy.pos.y += 1;
        }
    }

    fn render(self: *Game, ren: *sdl.SDL_Renderer) void {
        _ = sdl.SDL_RenderClear(ren);

        renderBackground(ren, self.textures.background);
        sdl.renderTexture(ren, self.textures.guy, self.playerPos.x, self.playerPos.y);
        for (self.enemies.toSlice()) |*enemy| {
            sdl.renderTexture(ren, enemy.breed.texture, enemy.pos.x, enemy.pos.y);
        }

        _ = sdl.SDL_RenderPresent(ren);
    }

    fn deinit(self: *Game) void {
        self.textures.destroy();
    }
};

fn renderBackground(ren: *sdl.SDL_Renderer, bgTile: *sdl.SDL_Texture) void {
    var dst: sdl.SDL_Rect = undefined;

    // Query the texture's size
    _ = sdl.SDL_QueryTexture(bgTile, null, null, &dst.w, &dst.h);

    dst.y = 0;

    while (dst.y < SCREEN_HEIGHT) {
        dst.x = 0;
        while (dst.x < SCREEN_WIDTH) {
            _ = sdl.SDL_RenderCopy(ren, bgTile, null, &dst);
            dst.x += dst.w;
        }
        dst.y += dst.h;
    }
}

fn point(x: c_int, y: c_int) sdl.SDL_Point {
    return sdl.SDL_Point{
        .x = x,
        .y = y,
    };
}
