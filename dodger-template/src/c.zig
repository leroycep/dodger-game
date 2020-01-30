usingnamespace @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL_image.h");
    @cDefine("GL_GLEXT_PROTOTYPES", "1");
    @cInclude("SDL2/SDL_opengles2.h");

    // Include KiWi headers
    @cInclude("KW_gui.h");
    @cInclude("KW_frame.h");
    @cInclude("KW_label.h");
    @cInclude("KW_button.h");
    @cInclude("KW_renderdriver_sdl2.h");
});
