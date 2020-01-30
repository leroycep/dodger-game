const std = @import("std");
const c = @import("../c.zig");
const sdl = @import("../sdl.zig");
usingnamespace @import("screen.zig");
usingnamespace @import("../constants.zig");
const Context = @import("../context.zig").Context;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const Enemy = @import("../game/enemy.zig").Enemy;
const EnemyBreed = @import("../game/enemy.zig").EnemyBreed;
const physics = @import("../game/physics.zig");
const Vec2 = physics.Vec2;
const World = @import("../game/world.zig").World;

const InputMap = struct {
    left: usize,
    right: usize,
    jump: usize,
};

pub const PlayScreen = struct {
    allocator: *std.mem.Allocator,
    screen: Screen,
    gui: *c.KW_GUI,
    textBuf: []u8,
    scoreLabel: *c.KW_Widget,

    const Self = @This();

    lastLoopTime: u64,
    score: f32,
    playerPhysics: physics.PhysicsComponent,
    playerAlive: bool,
    inputMap: InputMap,
    enemies: ArrayList(Enemy),
    maxEnemies: usize,
    world: World,
    rand: std.rand.DefaultPrng,

    pub fn init(allocator: *std.mem.Allocator) !*Self {
        const self = try allocator.create(PlayScreen);
        self.allocator = allocator;
        self.screen = Screen{
            .startFn = start,
            .onEventFn = onEvent,
            .updateFn = update,
            .renderFn = render,
            .deinitFn = deinit,
        };

        var buf: [8]u8 = undefined;
        try std.crypto.randomBytes(buf[0..]);
        const seed = std.mem.readIntSliceLittle(u64, buf[0..8]);
        self.rand = std.rand.DefaultPrng.init(seed);

        self.allocator = allocator;
        self.textBuf = allocator.alloc(u8, 50) catch unreachable;
        self.score = 0;
        self.playerPhysics = physics.PhysicsComponent.init(SCREEN_WIDTH / 2, SCREEN_HEIGHT - 32, 12, 26);
        self.playerAlive = true;
        self.inputMap = InputMap{
            .left = sdl.scnFromKey(c.SDLK_LEFT),
            .right = sdl.scnFromKey(c.SDLK_RIGHT),
            .jump = sdl.scnFromKey(c.SDLK_z),
        };
        self.enemies = ArrayList(Enemy).init(allocator);
        self.maxEnemies = INITIAL_MAX_ENEMIES;
        self.world = World{ .leftWall = 0, .rightWall = SCREEN_WIDTH, .floor = SCREEN_HEIGHT - 16 };

        return self;
    }

    pub fn start(screen: *Screen, ctx: *Context) void {
        const self = @fieldParentPtr(Self, "screen", screen);

        self.lastLoopTime = std.time.milliTimestamp();
        self.gui = c.KW_Init(ctx.kw_driver, ctx.kw_tileset) orelse unreachable;

        const labelrect = c.KW_Rect{ .x = 0, .y = 0, .w = 100, .h = 30 };
        var frame = c.KW_CreateFrame(self.gui, null, &labelrect);
        self.scoreLabel = c.KW_CreateLabel(self.gui, frame, c"score", &labelrect).?;
    }

    fn onEvent(screen: *Screen, event: ScreenEvent) ?Transition {
        const self = @fieldParentPtr(Self, "screen", screen);

        switch (event) {
            .KeyPressed => |value| {
                if (value == c.SDLK_ESCAPE) {
                    return Transition{ .PopScreen = {} };
                }
            },
        }

        return null;
    }

    fn update(screen: *Screen, ctx: *Context, keys: [*]const u8) ?Transition {
        const self = @fieldParentPtr(Self, "screen", screen);

        if (self.playerAlive) {
            const now = std.time.milliTimestamp();
            const deltaTime = now - self.lastLoopTime;
            self.lastLoopTime = std.time.milliTimestamp();
            self.score += @intToFloat(f32, deltaTime) / std.time.ms_per_s;
            const textSlice = std.fmt.bufPrint(self.textBuf, "{d:0.2}", self.score) catch unreachable;
            self.textBuf[textSlice.len] = 0;
            c.KW_SetLabelText(self.scoreLabel, textSlice.ptr);

            var goingLeft = keys[self.inputMap.left] == 1;
            var goingRight = keys[self.inputMap.right] == 1;
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
        }

        if (self.enemies.toSlice().len < self.maxEnemies) {
            self.enemies.append(Enemy{
                .breed = &ctx.assets.breeds.get("badguy").?.value,
                .physics = physics.PhysicsComponent.init(0, SCREEN_HEIGHT + 32, 32, 32), // Start the enemy below the screen, so it will be picked up by the loop
                .ticksLeftOnFloor = 0,
            }) catch |_| {
                // Do nothing
            };
        }

        for (self.enemies.toSlice()) |*enemy, i| {
            if (enemy.physics.isOnFloor(&self.world)) {
                if (enemy.ticksLeftOnFloor == 0) {
                    enemy.physics.pos.y = ENEMY_START_Y;
                    enemy.physics.pos.x = self.rand.random.float(f32) * (SCREEN_WIDTH - 32) + 32;
                    enemy.physics.vel = Vec2.zero();

                    const ticks = enemy.breed.ticksOnFloor;
                    const variation = (ticks * ENEMY_TICKS_ON_FLOOR_VARIATION) / 100;
                    enemy.ticksLeftOnFloor = self.rand.random.intRangeLessThan(u32, ticks - variation, ticks + variation);
                }

                enemy.ticksLeftOnFloor -= 1;
            }

            enemy.physics.applyGravity();
            enemy.physics.update(&self.world);

            if (enemy.physics.intersects(&self.playerPhysics)) {
                self.playerAlive = false;
            }
        }

        c.KW_ProcessEvents(self.gui);

        return null;
    }

    fn render(screen: *Screen, ctx: *Context, ren: *c.SDL_Renderer) anyerror!void {
        const self = @fieldParentPtr(Self, "screen", screen);

        renderBackground(ren, ctx.assets.tex("background"));
        if (self.playerAlive) {
            sdl.renderTexture(ren, ctx.assets.tex("guy"), self.playerPhysics.pos.x, self.playerPhysics.pos.y);
        }
        for (self.enemies.toSlice()) |*enemy| {
            sdl.renderTexture(ren, enemy.breed.texture, enemy.physics.pos.x, enemy.physics.pos.y);
        }

        c.KW_Paint(self.gui);
    }

    fn stop(screen: *Screen) void {
        c.KW_Quit(self.gui);
    }

    fn deinit(screen: *Screen) void {
        const self = @fieldParentPtr(Self, "screen", screen);
        self.allocator.free(self.textBuf);
        self.enemies.deinit();
        self.allocator.destroy(self);
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
