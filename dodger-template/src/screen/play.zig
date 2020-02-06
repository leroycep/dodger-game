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
const EnterNameScreen = @import("enter_name.zig").EnterNameScreen;
const Tween = @import("../tween.zig").Tween;

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
    fpsLabel: *c.KW_Widget,

    const Self = @This();

    lastLoopTime: u64,
    score: f32,
    playerPhysics: physics.PhysicsComponent,
    playerAlive: bool,
    playerMoving: bool,
    inputMap: InputMap,
    enemies: ArrayList(Enemy),
    maxEnemies: usize,
    world: World,
    rand: std.rand.DefaultPrng,
    death_start: u64,

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
        self.playerMoving = false;
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

        const framerect = c.KW_Rect{ .x = 0, .y = 0, .w = SCREEN_WIDTH, .h = 30 };
        var frame = c.KW_CreateFrame(self.gui, null, &framerect);
        const labelrect = c.KW_Rect{ .x = 0, .y = 0, .w = 100, .h = 30 };
        self.scoreLabel = c.KW_CreateLabel(self.gui, frame, c"score", &labelrect).?;

        const fpsrect = c.KW_Rect{ .x = SCREEN_WIDTH - 100, .y = 0, .w = 100, .h = 30 };
        self.fpsLabel = c.KW_CreateLabel(self.gui, frame, c"fps", &fpsrect).?;
    }

    fn onEvent(screen: *Screen, event: ScreenEvent) ?Transition {
        const self = @fieldParentPtr(Self, "screen", screen);

        if (ScreenEventTag(event.type) == .KeyPressed and event.type.KeyPressed == c.SDLK_ESCAPE) {
            return Transition{ .PopScreen = {} };
        }

        c.KW_ProcessEvent(self.gui, event.sdl_event);

        return null;
    }

    fn update(screen: *Screen, ctx: *Context, keys: [*]const u8) ?Transition {
        const self = @fieldParentPtr(Self, "screen", screen);

        const fpsTextSlice = std.fmt.bufPrint(self.textBuf, "FPS: {d:0.2}", ctx.fps) catch unreachable;
        self.textBuf[fpsTextSlice.len] = 0;
        c.KW_SetLabelText(self.fpsLabel, fpsTextSlice.ptr);

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

                if (!self.playerMoving) {
                    _ = c.libpd_start_message(2);
                    _ = c.libpd_add_float(0.5);
                    _ = c.libpd_add_float(250.0);
                    _ = c.libpd_finish_list(c"rampwalk");
                }
                self.playerMoving = true;
            } else if (goingRight and !goingLeft) {
                self.playerPhysics.vel.x = PLAYER_SPEED;

                if (!self.playerMoving) {
                    _ = c.libpd_start_message(2);
                    _ = c.libpd_add_float(0.5);
                    _ = c.libpd_add_float(250.0);
                    _ = c.libpd_finish_list(c"rampwalk");
                }
                self.playerMoving = true;
            } else {
                self.playerPhysics.vel.x = 0;

                if (self.playerMoving) {
                    _ = c.libpd_start_message(2);
                    _ = c.libpd_add_float(0.0);
                    _ = c.libpd_add_float(20.0);
                    _ = c.libpd_finish_list(c"rampwalk");
                }
                self.playerMoving = false;
            }
            self.playerPhysics.applyGravity();
            self.playerPhysics.update(&self.world);
            // Player won't need up/down input. May need a jump button
            if (keys[self.inputMap.jump] == 1 and self.playerPhysics.isOnFloor(&self.world)) {
                self.playerPhysics.vel.y += PLAYER_JUMP_VEL;
            }
        } else {
            if (self.playerMoving) {
                _ = c.libpd_start_message(2);
                _ = c.libpd_add_float(0.0);
                _ = c.libpd_add_float(20.0);
                _ = c.libpd_finish_list(c"rampwalk");
            }
            self.playerMoving = false;
        }

        if (self.enemies.toSlice().len < self.maxEnemies) {
            const enemy = self.enemies.addOne() catch unreachable;
            ctx.assets.breeds.get("badguy").?.value.initEnemy(enemy);
            enemy.dead = true;
            enemy.landingTween = Tween.linearLimited(ENEMY_LANDING_TWEEN_DURATION, ENEMY_LANDING_TWEEN_START_SCALE_Y, (1 - ENEMY_LANDING_TWEEN_START_SCALE_Y));
            enemy.deathTween = Tween.linearLimited(ENEMY_DEATH_TWEEN_DURATION, ENEMY_DEATH_TWEEN_START_SCALE_X, ENEMY_DEATH_TWEEN_CHANGE_SCALE_X);
        }

        for (self.enemies.toSlice()) |*enemy, i| {
            if (enemy.physics.isOnFloor(&self.world)) {
                if (enemy.ticksLeftOnFloor == 0) {
                    enemy.dead = true;
                } else {
                    enemy.ticksLeftOnFloor -= 1;
                }
            }

            if (enemy.dead) {
                enemy.physics.pos.y = ENEMY_START_Y;
                enemy.physics.pos.x = self.rand.random.float(f32) * (SCREEN_WIDTH - 32) + 32;
                enemy.physics.vel = Vec2.zero();

                const ticks = enemy.breed.ticksOnFloor;
                const variation = (ticks * ENEMY_TICKS_ON_FLOOR_VARIATION) / 100;
                enemy.ticksLeftOnFloor = self.rand.random.intRangeLessThan(u32, ticks - variation, ticks + variation);
                enemy.dead = false;
            }

            enemy.previousVel = enemy.physics.vel;
            enemy.physics.applyGravity();
            enemy.physics.update(&self.world);

            if (enemy.physics.intersects(&self.playerPhysics) and self.playerAlive) {
                self.playerAlive = false;
                self.death_start = std.time.milliTimestamp();
            }

            const now = std.time.milliTimestamp();

            // Squash the enemy on extereme y velocity changes
            if (enemy.physics.vel.y < enemy.previousVel.y) {
                enemy.landingTween.reset(now);
            }

            // Make the enemies face the player
            if (self.playerPhysics.pos.x < enemy.physics.pos.x) {
                enemy.targetScaleX = 1;
            } else if (self.playerPhysics.pos.x > enemy.physics.pos.x) {
                enemy.targetScaleX = -1;
            }

            // Slowly change current scale to target scale
            if (enemy.ticksLeftOnFloor > ENEMY_DEATH_TWEEN_DURATION_TICKS) {
                enemy.scaleX += (enemy.targetScaleX - enemy.scaleX) * ENEMY_TURN_TWEEN_SPEED;
                enemy.deathTween.reset(now);
            } else {
                enemy.scaleX = enemy.deathTween.getValue(now) * enemy.targetScaleX;
            }
            enemy.scaleY = enemy.landingTween.getValue(now);
        }

        if (!self.playerAlive) {
            if (std.time.milliTimestamp() - self.death_start > 1000) {
                const newScreen = EnterNameScreen.init(self.allocator, self.score) catch unreachable;
                return Transition{ .ReplaceScreen = &newScreen.screen };
            }
        }

        return null;
    }

    fn render(screen: *Screen, ctx: *Context, gpuTarget: *c.GPU_Target) anyerror!void {
        const self = @fieldParentPtr(Self, "screen", screen);

        c.GPU_BlitRect(ctx.assets.tex("background"), null, gpuTarget, null);
        if (self.playerAlive) {
            c.GPU_Blit(ctx.assets.tex("guy"), null, gpuTarget, self.playerPhysics.pos.x, self.playerPhysics.pos.y);
        }
        for (self.enemies.toSlice()) |*enemy| {
            // Offset the y position so that the enemy keeps their feet planted on the ground
            const renderY = enemy.physics.pos.y + ((1 - enemy.scaleY) / 2) * @intToFloat(f32, enemy.breed.texture.h);
            c.GPU_BlitTransform(enemy.breed.texture, null, gpuTarget, enemy.physics.pos.x, renderY, 0, enemy.scaleX, enemy.scaleY);
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

fn point(x: c_int, y: c_int) c.SDL_Point {
    return c.SDL_Point{
        .x = x,
        .y = y,
    };
}
