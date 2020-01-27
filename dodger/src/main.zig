const std = @import("std");
const sdl = @import("sdl.zig");
usingnamespace @import("constants.zig");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const assets_ = @import("assets.zig");
const Assets = assets_.Assets;
const Enemy = @import("enemy.zig").Enemy;
const EnemyBreed = @import("enemy.zig").EnemyBreed;
const physics = @import("physics.zig");
const Vec2 = physics.Vec2;
const World = @import("world.zig").World;

pub fn main() !void {
    if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO) != 0) {
        return sdl.logErr(error.InitFailed);
    }
    defer sdl.SDL_Quit();

    const win = sdl.SDL_CreateWindow(c"Hello World!", 100, 100, SCREEN_WIDTH, SCREEN_HEIGHT, sdl.SDL_WINDOW_SHOWN) orelse {
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

    var game = try Game.init(allocator, ren, assets);
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

        game.update(keys, assets);
        game.render(ren, assets);
    }
}

const InputMap = struct {
    up: usize,
    down: usize,
    left: usize,
    right: usize,
};

const Game = struct {
    allocator: *Allocator,
    playerPhysics: physics.PhysicsComponent,
    inputMap: InputMap,
    enemies: ArrayList(Enemy),
    maxEnemies: usize,
    world: World,
    rand: std.rand.DefaultPrng,

    fn init(allocator: *Allocator, ren: *sdl.SDL_Renderer, assets: *Assets) !*Game {
        var game = try allocator.create(Game);

        var buf: [8]u8 = undefined;
        try std.crypto.randomBytes(buf[0..]);
        const seed = std.mem.readIntSliceLittle(u64, buf[0..8]);
        game.rand = std.rand.DefaultPrng.init(seed);

        game.allocator = allocator;
        game.playerPhysics = physics.PhysicsComponent.init(SCREEN_WIDTH / 2, SCREEN_HEIGHT - 32);
        game.inputMap = InputMap{
            .up = sdl.scnFromKey(sdl.SDLK_UP),
            .down = sdl.scnFromKey(sdl.SDLK_DOWN),
            .left = sdl.scnFromKey(sdl.SDLK_LEFT),
            .right = sdl.scnFromKey(sdl.SDLK_RIGHT),
        };
        game.enemies = ArrayList(Enemy).init(allocator);
        game.maxEnemies = INITIAL_MAX_ENEMIES;
        game.world = World{ .leftWall = 0, .rightWall = SCREEN_WIDTH, .floor = SCREEN_HEIGHT - 16 };

        return game;
    }

    fn update(self: *Game, keys: [*]const u8, assets: *Assets) void {
        var goingLeft = keys[self.inputMap.left] == 1 and self.playerPhysics.pos.x > 16;
        var goingRight = keys[self.inputMap.right] == 1 and self.playerPhysics.pos.x < SCREEN_WIDTH - 16;
        if (goingLeft and !goingRight) {
            self.playerPhysics.vel.x = -PLAYER_SPEED;
        } else if (goingRight and !goingLeft) {
            self.playerPhysics.vel.x = PLAYER_SPEED;
        } else {
            self.playerPhysics.vel.x = 0;
        }
        self.playerPhysics.update(&self.world);
        // Player won't need up/down input. May need a jump button
        // if (keys[self.inputMap.up] == 1) {
        //     self.playerPos.y -= PLAYER_SPEED;
        // }
        // if (keys[self.inputMap.down] == 1) {
        //     self.playerPos.y += PLAYER_SPEED;
        // }

        if (self.enemies.toSlice().len < self.maxEnemies) {
            self.enemies.append(Enemy{
                .breed = &assets.breeds.get("badguy").?.value,
                .physics = physics.PhysicsComponent.init(0.0, @intToFloat(f32, SCREEN_HEIGHT + 32)), // Start the enemy below the screen, so it will be picked up by the loop
            }) catch |_| {
                // Do nothing
            };
        }

        for (self.enemies.toSlice()) |*enemy, i| {
            enemy.physics.pos.y += ENEMY_SPEED;

            if (physics.distance(enemy.physics.pos, self.playerPhysics.pos) < 32) {
                std.debug.warn("You're dead!\n");
            }

            if (enemy.physics.pos.y > SCREEN_HEIGHT) {
                enemy.physics.pos.y = ENEMY_START_Y;
                enemy.physics.pos.x = self.rand.random.float(f32) * (SCREEN_WIDTH - 32) + 32;
                enemy.physics.vel = Vec2.zero();
            }
        }
    }

    fn render(self: *Game, ren: *sdl.SDL_Renderer, assets: *Assets) void {
        _ = sdl.SDL_RenderClear(ren);

        renderBackground(ren, assets.tex("background"));
        sdl.renderTexture(ren, assets.tex("guy"), self.playerPhysics.pos.x, self.playerPhysics.pos.y);
        for (self.enemies.toSlice()) |*enemy| {
            sdl.renderTexture(ren, enemy.breed.texture, enemy.physics.pos.x, enemy.physics.pos.y);
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
