const std = @import("std");
const sdl = @import("sdl.zig");
usingnamespace @import("constants.zig");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const assets_ = @import("assets.zig");
const Assets = assets_.Assets;

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

    const assets = &Assets.init(allocator);
    try assets_.initAssets(assets, ren);
    defer assets.deinit();

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
        game.render(ren, assets);
    }
}

const InputMap = struct {
    up: usize,
    down: usize,
    left: usize,
    right: usize,
};

const EnemyBreed = struct {
    texture: []const u8,
};

const Enemy = struct {
    breed: *EnemyBreed,
    pos: sdl.SDL_Point,
};

const Game = struct {
    allocator: *Allocator,
    playerPos: sdl.SDL_Point,
    inputMap: InputMap,
    enemyBreeds: [1]EnemyBreed,
    enemies: ArrayList(Enemy),

    fn init(allocator: *Allocator, ren: *sdl.SDL_Renderer) !*Game {
        var game = try allocator.create(Game);
        game.allocator = allocator;
        game.playerPos = sdl.SDL_Point{
            .x = 50,
            .y = 50,
        };
        game.inputMap = InputMap{
            .up = sdl.scnFromKey(sdl.SDLK_UP),
            .down = sdl.scnFromKey(sdl.SDLK_DOWN),
            .left = sdl.scnFromKey(sdl.SDLK_LEFT),
            .right = sdl.scnFromKey(sdl.SDLK_RIGHT),
        };
        game.enemyBreeds = [_]EnemyBreed{
            EnemyBreed{
                .texture = "badguy",
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

    fn render(self: *Game, ren: *sdl.SDL_Renderer, assets: *Assets) void {
        _ = sdl.SDL_RenderClear(ren);

        if (assets.textures.get("background")) |tex| {
            renderBackground(ren, tex.value);
        }
        if (assets.textures.get("guy")) |tex| {
            sdl.renderTexture(ren, tex.value, self.playerPos.x, self.playerPos.y);
        }
        for (self.enemies.toSlice()) |*enemy| {
            if (assets.textures.get(enemy.breed.texture)) |tex| {
                sdl.renderTexture(ren, tex.value, enemy.pos.x, enemy.pos.y);
            }
        }

        _ = sdl.SDL_RenderPresent(ren);
    }

    fn deinit(self: *Game) void {
        self.enemies.deinit();
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
