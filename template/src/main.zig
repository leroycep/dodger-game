const std = @import("std");
const sdl = @import("sdl.zig");
const gl = @import("gl.zig");

const vertexSource: sdl.GLchar =
    \\ attribute vec4 position;
    \\ void main()
    \\ {
    \\     gl_Position = vec4(position.xyz, 1.0);
    \\ }
;
const fragmentSource: sdl.GLchar =
    \\ precision mediump float;
    \\ void main()
    \\ {
    \\     gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
    \\ }
;

pub fn main() !void {
    if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO) != 0) {
        return sdl.logErr(error.InitFailed);
    }
    defer sdl.SDL_Quit();

    const win = sdl.SDL_CreateWindow(c"Hello World!", 100, 100, 640, 480, sdl.SDL_WINDOW_SHOWN | sdl.SDL_WINDOW_OPENGL) orelse {
        return sdl.logErr(error.CouldntCreateWindow);
    };
    defer sdl.SDL_DestroyWindow(win);

    if (sdl.SDL_GL_SetAttribute(sdl.SDL_GLattr.SDL_GL_CONTEXT_MAJOR_VERSION, 2) != 0) {
        return sdl.logErr(error.InitFailed);
    }
    if (sdl.SDL_GL_SetAttribute(sdl.SDL_GLattr.SDL_GL_CONTEXT_MINOR_VERSION, 0) != 0) {
        return sdl.logErr(error.InitFailed);
    }
    if (sdl.SDL_GL_SetAttribute(sdl.SDL_GLattr.SDL_GL_DOUBLEBUFFER, 1) != 0) {
        return sdl.logErr(error.InitFailed);
    }
    if (sdl.SDL_GL_SetAttribute(sdl.SDL_GLattr.SDL_GL_DEPTH_SIZE, 24) != 0) {
        return sdl.logErr(error.InitFailed);
    }

    var glc = sdl.SDL_GL_CreateContext(win);

    const ren = sdl.SDL_CreateRenderer(win, -1, sdl.SDL_RENDERER_ACCELERATED | sdl.SDL_RENDERER_TARGETTEXTURE) orelse {
        return sdl.logErr(error.CouldntCreateRenderer);
    };
    defer sdl.SDL_DestroyRenderer(ren);

    // Vertex array object
    var vao: sdl.GLuint = undefined;
    gl.glGenVertexArraysOES(1, &vao);
    gl.glBindVertexArraysOES(vao);

    // Vertex buffer object
    var vbo: sdl.GLuint = undefined;
    sdl.glGenBuffers(1, &vbo);

    var vertices = [_]sdl.GLfloat{ 0.0, 0.5, 0.5, 0.5, 0.5, 0.5 };

    sdl.glBindBuffer(GL_ARRAY_BUFFER, vbo);
    sdl.glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    var vertexShader: sdl.GLuint = glCreateShader(GL_VERTEX_SHADER);
    sdl.glShaderSource(vertexShader, 1, &vertexSource, null);
    sdl.glCompileShader(vertexShader);

    var fragmentShader: sdl.GLuint = glCreateShader(GL_FRAGMENT_SHADER);
    sdl.glShaderSource(fragmentShader, 1, &fragmentSource, null);
    sdl.glCompileShader(fragmentShader);

    var shaderProgram: sdl.GLuint = sdl.glCreateProgram();
    sdl.glAttachShader(shaderProgram, vertexShader);
    sdl.glAttachShader(shaderProgram, fragmentShader);
    sdl.glLinkProgram(shaderProgram);
    sdl.glUseProgram(shaderProgram);

    var posAttrib: sdl.GLuint = sdl.glGetAttribLocation(shaderProgram, "position");
    sdl.glEnableVertexAttribArray(posAttrib);
    sdl.glVertexAttribPointer(posAttrib, 2, sdl.GL_FLOAT, sdl.GS_FALSE, 0, 0);

    var quit = false;
    var e: sdl.SDL_Event = undefined;
    const keys = sdl.SDL_GetKeyboardState(null);

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
    }
}
