usingnamespace @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL_image.h");
    @cDefine("GL_GLEXT_PROTOTYPES", "1");
    @cInclude("SDL2/SDL_opengles2.h");

    @cInclude("impl.h");
});
