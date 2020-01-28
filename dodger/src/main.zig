const std = @import("std");
const c = @import("c.zig");
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
    if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
        return sdl.logErr(error.InitFailed);
    }
    defer c.SDL_Quit();

    const win = c.SDL_CreateWindow(c"Hello World!", 100, 100, SCREEN_WIDTH, SCREEN_HEIGHT, c.SDL_WINDOW_SHOWN) orelse {
        return sdl.logErr(error.CouldntCreateWindow);
    };
    defer c.SDL_DestroyWindow(win);

    const ren = c.SDL_CreateRenderer(win, -1, c.SDL_RENDERER_ACCELERATED | c.SDL_RENDERER_PRESENTVSYNC) orelse {
        return sdl.logErr(error.CouldntCreateRenderer);
    };
    defer c.SDL_DestroyRenderer(ren);

    if ((c.IMG_Init(c.IMG_INIT_PNG) & c.IMG_INIT_PNG) != c.IMG_INIT_PNG) {
        return sdl.logErr(error.ImgInit);
    }

    const allocator = std.heap.direct_allocator;

    const assets = &Assets.init(allocator);
    try assets_.initAssets(assets, ren);
    defer assets.deinit();

    var quit = false;
    var e: c.SDL_Event = undefined;
    const keys = c.SDL_GetKeyboardState(null);

    var game = try Game.init(allocator, ren, assets);
    defer game.deinit();

    while (!quit) {
        while (c.SDL_PollEvent(&e) != 0) {
            if (e.type == c.SDL_QUIT) {
                quit = true;
            }
            if (e.type == c.SDL_KEYDOWN) {
                if (e.key.keysym.sym == c.SDLK_ESCAPE) {
                    quit = true;
                }
            }
        }

        game.update(keys, assets);
        game.render(ren, assets);
    }
}

const InputMap = struct {
    left: usize,
    right: usize,
    jump: usize,
};

const Game = struct {
    allocator: *Allocator,
    playerPhysics: physics.PhysicsComponent,
    inputMap: InputMap,
    enemies: ArrayList(Enemy),
    maxEnemies: usize,
    world: World,
    rand: std.rand.DefaultPrng,

    fn init(allocator: *Allocator, ren: *c.SDL_Renderer, assets: *Assets) !*Game {
        var game = try allocator.create(Game);

        var buf: [8]u8 = undefined;
        try std.crypto.randomBytes(buf[0..]);
        const seed = std.mem.readIntSliceLittle(u64, buf[0..8]);
        game.rand = std.rand.DefaultPrng.init(seed);

        game.allocator = allocator;
        game.playerPhysics = physics.PhysicsComponent.init(SCREEN_WIDTH / 2, SCREEN_HEIGHT - 32, 32, 32);
        game.inputMap = InputMap{
            .left = sdl.scnFromKey(c.SDLK_LEFT),
            .right = sdl.scnFromKey(c.SDLK_RIGHT),
            .jump = sdl.scnFromKey(c.SDLK_z),
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
        self.playerPhysics.applyGravity();
        self.playerPhysics.update(&self.world);
        // Player won't need up/down input. May need a jump button
        if (keys[self.inputMap.jump] == 1 and self.playerPhysics.isOnFloor(&self.world)) {
            self.playerPhysics.vel.y += PLAYER_JUMP_VEL;
        }
        // if (keys[self.inputMap.down] == 1) {
        //     self.playerPos.y += PLAYER_SPEED;
        // }

        if (self.enemies.toSlice().len < self.maxEnemies) {
            self.enemies.append(Enemy{
                .breed = &assets.breeds.get("badguy").?.value,
                .physics = physics.PhysicsComponent.init(0, SCREEN_HEIGHT + 32, 32, 32), // Start the enemy below the screen, so it will be picked up by the loop
                .ticksLeftOnFloor = 0,
            }) catch |_| {
                // Do nothing
            };
        }

        for (self.enemies.toSlice()) |*enemy, i| {
            if (physics.distance(enemy.physics.pos, self.playerPhysics.pos) < 32) {
                std.debug.warn("You're dead!\n");
            }

            if (enemy.physics.isOnFloor(&self.world)) {
                if (enemy.ticksLeftOnFloor == 0) {
                    enemy.physics.pos.y = ENEMY_START_Y;
                    enemy.physics.pos.x = self.rand.random.float(f32) * (SCREEN_WIDTH - 32) + 32;
                    enemy.physics.vel = Vec2.zero();

                    const ticks = enemy.breed.ticksOnFloor;
                    const variation = (ticks * 100 / ENEMY_TICKS_ON_FLOOR_VARIATION) / 100;
                    enemy.ticksLeftOnFloor = self.rand.random.intRangeLessThan(u32, ticks - variation, ticks + variation);
                }

                enemy.ticksLeftOnFloor -= 1;
            }

            enemy.physics.applyGravity();
            enemy.physics.update(&self.world);
        }
    }

    fn render(self: *Game, ren: *c.SDL_Renderer, assets: *Assets) void {
        _ = c.SDL_RenderClear(ren);

        renderBackground(ren, assets.tex("background"));
        sdl.renderTexture(ren, assets.tex("guy"), self.playerPhysics.pos.x, self.playerPhysics.pos.y);
        for (self.enemies.toSlice()) |*enemy| {
            sdl.renderTexture(ren, enemy.breed.texture, enemy.physics.pos.x, enemy.physics.pos.y);
        }

        _ = c.SDL_RenderPresent(ren);
    }

    fn deinit(self: *Game) void {
        self.enemies.deinit();
    }
};

fn renderBackground(ren: *c.SDL_Renderer, bgTile: *c.SDL_Texture) void {
    var dst: c.SDL_Rect = undefined;

    // Query the texture's size
    _ = c.SDL_QueryTexture(bgTile, null, null, &dst.w, &dst.h);

    dst.y = 0;

    while (dst.y < SCREEN_HEIGHT) {
        dst.x = 0;
        while (dst.x < SCREEN_WIDTH) {
            _ = c.SDL_RenderCopy(ren, bgTile, null, &dst);
            dst.x += dst.w;
        }
        dst.y += dst.h;
    }
}

fn point(x: c_int, y: c_int) c.SDL_Point {
    return c.SDL_Point{
        .x = x,
        .y = y,
    };
}
