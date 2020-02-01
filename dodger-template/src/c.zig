pub usingnamespace @cImport({
    @cInclude("SDL2/SDL.h");
    @cInclude("SDL_ttf.h");
    @cInclude("SDL2/SDL_gpu.h");

    // Include KiWi headers
    @cInclude("KW_gui.h");
    @cInclude("KW_frame.h");
    @cInclude("KW_label.h");
    @cInclude("KW_button.h");
    @cInclude("KW_renderdriver.h");

    @cInclude("z_libpd.h");
});
