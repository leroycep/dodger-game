const std = @import("std");
const sdl = @import("sdl.zig");
usingnamespace @import("constants.zig");

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

    const tex = try sdl.loadTexture(ren, c"assets/texture.png");
    defer sdl.SDL_DestroyTexture(tex);
    const guyTex = try sdl.loadTexture(ren, c"assets/guy.png");
    defer sdl.SDL_DestroyTexture(tex);

    var quit = false;
    var e: sdl.SDL_Event = undefined;
    const keys = sdl.SDL_GetKeyboardState(null);
    var game = Game{
        .textures = Textures{
            .background = tex,
            .guy = guyTex,
        },
        .playerPos = sdl.SDL_Point{
            .x = 50,
            .y = 50,
        },
        .inputMap = InputMap{
            .up = @intCast(usize, @enumToInt(sdl.SDL_GetScancodeFromKey(sdl.SDLK_UP))),
            .down = @intCast(usize, @enumToInt(sdl.SDL_GetScancodeFromKey(sdl.SDLK_DOWN))),
            .left = @intCast(usize, @enumToInt(sdl.SDL_GetScancodeFromKey(sdl.SDLK_LEFT))),
            .right = @intCast(usize, @enumToInt(sdl.SDL_GetScancodeFromKey(sdl.SDLK_RIGHT))),
        },
    };
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
};

const Game = struct {
    textures: Textures,
    playerPos: sdl.SDL_Point,
    inputMap: InputMap,

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

    }

    fn render(self: *Game, ren: *sdl.SDL_Renderer) void {
        _ = sdl.SDL_RenderClear(ren);

        renderBackground(ren, self.textures.background);
        sdl.renderTexture(ren, self.textures.guy, self.playerPos.x, self.playerPos.y);

        _ = sdl.SDL_RenderPresent(ren);
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
