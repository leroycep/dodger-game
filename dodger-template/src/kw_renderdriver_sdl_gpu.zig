const std = @import("std");
const Allocator = std.mem.Allocator;
usingnamespace @import("c.zig");

pub const KW_GPU_RenderDriver = struct {
    driver: KW_RenderDriver,
    allocator: *Allocator,
    gpuTarget: *GPU_Target,

    const Self = @This();

    pub fn init(allocator: *Allocator, gpuTarget: *GPU_Target) Self {
        const driver = KW_RenderDriver{
            .renderCopy = renderCopy,
            .renderText = renderText,
            .renderRect = renderRect,
            .utf8TextSize = utf8TextSize,
            .loadFont = loadFont,
            .loadFontFromMemory = loadFontFromMemory,
            .createTexture = createTexture,
            .createSurface = createSurface,
            .loadTexture = loadTexture,
            .loadSurface = loadSurface,

            .getSurfaceExtents = getSurfaceExtents,
            .getTextureExtents = getTextureExtents,
            .blitSurface = blitSurface,

            .getViewportSize = getViewportSize,

            .releaseTexture = releaseTexture,
            .releaseSurface = releaseSurface,
            .releaseFont = releaseFont,

            .setClipRect = setClipRect,
            .getClipRect = getClipRect,

            .getPixel = getPixel,

            .release = releaseRenderDriver,

            .priv = null,
        };
        return Self{
            .allocator = allocator,
            .driver = driver,
            .gpuTarget = gpuTarget,
        };
    }

    extern fn renderRect(driver: ?*KW_RenderDriver, kw_rectOpt: ?*KW_Rect, kw_color: KW_Color) void {
        const self = @fieldParentPtr(Self, "driver", driver.?);
        if (kw_rectOpt) |kw_rect| {
            const color = SDL_Color{
                .r = kw_color.r,
                .g = kw_color.g,
                .b = kw_color.b,
                .a = kw_color.a,
            };
            const rect = GPU_Rect{
                .x = @intToFloat(f32, kw_rect.x),
                .y = @intToFloat(f32, kw_rect.y),
                .w = @intToFloat(f32, kw_rect.w),
                .h = @intToFloat(f32, kw_rect.h),
            };
            GPU_RectangleFilled(self.gpuTarget, rect.x, rect.y, rect.w, rect.h, color);
        }
    }

    extern fn blitSurface(driver: ?*KW_RenderDriver, srcOpt: ?*KW_Surface, srcRectOpt: ?*const KW_Rect, dstOpt: ?*KW_Surface, dstRectOpt: ?*const KW_Rect) void {
        const self = @fieldParentPtr(Self, "driver", driver.?);
        const kw_src = srcOpt orelse return;
        const srcRect = srcRectOpt orelse return;
        const kw_dst = dstOpt orelse return;
        const dstRect = dstRectOpt orelse return;

        var s = SDL_Rect{
            .x = srcRect.x,
            .y = srcRect.y,
            .w = srcRect.w,
            .h = srcRect.h,
        };
        var d = SDL_Rect{
            .x = dstRect.x,
            .y = dstRect.y,
            .w = dstRect.w,
            .h = dstRect.h,
        };

        const src = castSurface(kw_src.surface);
        const dst = castSurface(kw_dst.surface);

        if (d.w != s.w or d.h != s.h) {
            _ = SDL_BlitScaled(src, &s, dst, &d);
        } else {
            _ = SDL_BlitSurface(src, &s, dst, &d);
        }
    }

    extern fn createSurface(driver: ?*KW_RenderDriver, width: c_uint, height: c_uint) ?*KW_Surface {
        const self = @fieldParentPtr(Self, "driver", driver.?);
        const RGBAMask = struct {
            r: u32,
            g: u32,
            b: u32,
            a: u32,
        };
        const mask = maskblock: {
            if (SDL_BYTEORDER == SDL_BIG_ENDIAN) {
                break :maskblock RGBAMask{
                    .r = 0xff000000,
                    .g = 0x00ff0000,
                    .b = 0x0000ff00,
                    .a = 0x000000ff,
                };
            } else {
                break :maskblock RGBAMask{
                    .r = 0x000000ff,
                    .g = 0x0000ff00,
                    .b = 0x00ff0000,
                    .a = 0xff000000,
                };
            }
        };
        const s = SDL_CreateRGBSurface(0, @intCast(c_int, width), @intCast(c_int, height), 32, mask.r, mask.g, mask.b, mask.a);
        _ = SDL_SetSurfaceBlendMode(s, SDL_BlendMode.SDL_BLENDMODE_NONE);
        return self.wrapSurface(s);
    }

    extern fn getSurfaceExtents(driver: ?*KW_RenderDriver, surfaceOpt: ?*const KW_Surface, widthOpt: ?*c_uint, heightOpt: ?*c_uint) void {
        const self = @fieldParentPtr(Self, "driver", driver.?);

        const kw_surface = surfaceOpt orelse return;
        const surface = castSurface(kw_surface.surface orelse return);
        var width = widthOpt orelse return;
        var height = heightOpt orelse return;
        width.* = @intCast(c_uint, surface.w);
        height.* = @intCast(c_uint, surface.h);
    }

    extern fn getTextureExtents(driver: ?*KW_RenderDriver, textureOpt: ?*KW_Texture, widthOpt: ?*c_uint, heightOpt: ?*c_uint) void {
        const self = @fieldParentPtr(Self, "driver", driver.?);
        const kw_texture = textureOpt orelse return;
        const texture = castImage(kw_texture.texture orelse return);
        var width = widthOpt orelse return;
        var height = heightOpt orelse return;
        width.* = texture.w;
        height.* = texture.h;
    }

    extern fn renderCopy(driver: ?*KW_RenderDriver, textureOpt: ?*KW_Texture, clipOpt: ?*const KW_Rect, dstOpt: ?*const KW_Rect) void {
        const self = @fieldParentPtr(Self, "driver", driver.?);
        const kw_texture = textureOpt orelse return;
        const texture = castImage(kw_texture.texture orelse return);
        var srcRect: ?*GPU_Rect = null;
        var dstRect: ?*GPU_Rect = null;
        if (clipOpt) |clip| {
            srcRect = &kwRectToGPU(clip);
        }
        if (dstOpt) |dst| {
            dstRect = &kwRectToGPU(dst);
        }
        GPU_BlitRect(texture, srcRect, self.gpuTarget, dstRect);
    }

    extern fn renderText(driver: ?*KW_RenderDriver, fontOpt: ?*KW_Font, textOpt: ?*const u8, color: KW_Color, style: KW_RenderDriver_TextStyle) ?*KW_Texture {
        const self = @fieldParentPtr(Self, "driver", driver.?);

        const kw_font = fontOpt orelse return null;
        const font = castFont(kw_font.font.?);
        const text = textOpt orelse return null;
        const sdlcolor = SDL_Color{ .r = color.r, .g = color.g, .b = color.b, .a = color.a };

        const previousstyle = TTF_GetFontStyle(font);
        TTF_SetFontStyle(font, @enumToInt(style));
        const textsurface = TTF_RenderUTF8_Blended(font, text, sdlcolor);
        const ret = GPU_CopyImageFromSurface(textsurface) orelse return null;
        SDL_FreeSurface(textsurface);
        TTF_SetFontStyle(font, previousstyle);
        return self.wrapImage(ret);
    }

    extern fn loadFont(driver: ?*KW_RenderDriver, fontFile: ?*const u8, ptSize: c_uint) ?*KW_Font {
        const self = @fieldParentPtr(Self, "driver", driver.?);
        return self.wrapFont(TTF_OpenFont(fontFile, @intCast(c_int, ptSize)));
    }

    extern fn loadFontFromMemory(driver: ?*KW_RenderDriver, fontMemory: ?*const c_void, memSize: c_ulong, ptSize: c_uint) ?*KW_Font {
        const self = @fieldParentPtr(Self, "driver", driver.?);
        const fontOpt = TTF_OpenFontRW(SDL_RWFromConstMem(fontMemory, @intCast(c_int, memSize)), SDL_FALSE, @intCast(c_int, ptSize));
        return self.wrapFont(fontOpt);
    }

    extern fn createTexture(driver: ?*KW_RenderDriver, surface: ?*KW_Surface) ?*KW_Texture {
        const self = @fieldParentPtr(Self, "driver", driver.?);
        if (surface) |surf| {
            const sdl_surface = @ptrCast(*SDL_Surface, @alignCast(@alignOf(*SDL_Surface), surf.surface));
            return self.wrapImage(GPU_CopyImageFromSurface(sdl_surface));
        }
        return null;
    }

    extern fn loadTexture(driver: ?*KW_RenderDriver, file: ?*const u8) ?*KW_Texture {
        const self = @fieldParentPtr(Self, "driver", driver.?);
        return self.wrapImage(GPU_LoadImage(file));
    }

    extern fn loadSurface(driver: ?*KW_RenderDriver, file: ?*const u8) ?*KW_Surface {
        const self = @fieldParentPtr(Self, "driver", driver.?);

        const kw_surface = self.allocator.create(KW_Surface) catch return null;
        kw_surface.surface = GPU_LoadSurface(file);

        return kw_surface;
    }

    extern fn releaseTexture(driver: ?*KW_RenderDriver, texture: ?*KW_Texture) void {
        const self = @fieldParentPtr(Self, "driver", driver.?);
        if (texture) |kw_texture| {
            GPU_FreeImage(castImage(kw_texture.texture));
            self.allocator.destroy(kw_texture);
        }
    }

    extern fn releaseSurface(driver: ?*KW_RenderDriver, surface: ?*KW_Surface) void {
        const self = @fieldParentPtr(Self, "driver", driver.?);
        if (surface) |surf| {
            SDL_FreeSurface(castSurface(surf.surface));
            self.allocator.destroy(surf);
        }
    }

    extern fn releaseFont(driver: ?*KW_RenderDriver, font: ?*KW_Font) void {
        const self = @fieldParentPtr(Self, "driver", driver.?);
        if (font) |kw_font| {
            TTF_CloseFont(castFont(kw_font.font));
            self.allocator.destroy(kw_font);
        }
    }

    extern fn getClipRect(driver: ?*KW_RenderDriver, clip: ?*KW_Rect) KW_bool {
        const self = @fieldParentPtr(Self, "driver", driver.?);
        // TODO
        return KW_bool.KW_FALSE;
    }

    extern fn getViewportSize(driver: ?*KW_RenderDriver, rectOpt: ?*KW_Rect) void {
        const self = @fieldParentPtr(Self, "driver", driver.?);
        var rect = rectOpt orelse return;
        var w: u16 = undefined;
        var h: u16 = undefined;
        GPU_GetVirtualResolution(self.gpuTarget, &w, &h);
        rect.w = w;
        rect.h = h;
    }

    extern fn setClipRect(driver: ?*KW_RenderDriver, clipOpt: ?*const KW_Rect, force: c_int) void {
        const self = @fieldParentPtr(Self, "driver", driver.?);
        const clip = clipOpt orelse return;
        _ = GPU_SetClip(self.gpuTarget, @intCast(i16, clip.x), @intCast(i16, clip.y), @intCast(u16, clip.w), @intCast(u16, clip.h));
    }

    extern fn releaseRenderDriver(driver: ?*KW_RenderDriver) void {
        const self = @fieldParentPtr(Self, "driver", driver.?);
        // doesn't do anything, needs to be freed from the driver
    }

    extern fn utf8TextSize(driver: ?*KW_RenderDriver, fontOpt: ?*KW_Font, textOpt: ?[*]const u8, widthOpt: ?*c_uint, heightOpt: ?*c_uint) void {
        const self = @fieldParentPtr(Self, "driver", driver.?);
        const kw_font = fontOpt orelse return;
        const font = castFont(kw_font.font.?);
        const text = @ptrCast([*]const u8, textOpt orelse return);

        var w: c_int = undefined;
        var h: c_int = undefined;
        _ = TTF_SizeUTF8(font, text, &w, &h);
        if (widthOpt) |width| {
            width.* = @intCast(c_uint, w);
        }
        if (heightOpt) |height| {
            height.* = @intCast(c_uint, h);
        }
    }

    extern fn getPixel(driver: ?*KW_RenderDriver, surface: ?*KW_Surface, x: c_uint, y: c_uint) c_uint {
        const self = @fieldParentPtr(Self, "driver", driver.?);
        // TODO
        return 0;
    }

    fn wrapSurface(self: *KW_GPU_RenderDriver, surface: *SDL_Surface) ?*KW_Surface {
        const kw_surface = self.allocator.create(KW_Surface) catch return null;
        kw_surface.surface = surface;
        return kw_surface;
    }

    fn wrapImage(self: *KW_GPU_RenderDriver, image: *GPU_Image) ?*KW_Texture {
        const kw_texture = self.allocator.create(KW_Texture) catch return null;
        kw_texture.texture = image;
        return kw_texture;
    }

    fn wrapFont(self: *Self, fontOpt: ?*TTF_Font) ?*KW_Font {
        const font = fontOpt orelse return null;
        const kw_font = self.allocator.create(KW_Font) catch return null;
        kw_font.font = font;
        return kw_font;
    }
};

fn castSurface(ptr: *c_void) *SDL_Surface {
    return @ptrCast(*SDL_Surface, @alignCast(@alignOf(*SDL_Surface), ptr));
}

fn castImage(ptr: *c_void) *GPU_Image {
    return @ptrCast(*GPU_Image, @alignCast(@alignOf(*GPU_Image), ptr));
}

fn castFont(ptr: *c_void) *TTF_Font {
    return @ptrCast(*TTF_Font, @alignCast(@alignOf(*TTF_Font), ptr));
}

fn kwRectToGPU(kw_rect: *const KW_Rect) GPU_Rect {
    return GPU_Rect{
        .x = @intToFloat(f32, kw_rect.x),
        .y = @intToFloat(f32, kw_rect.y),
        .w = @intToFloat(f32, kw_rect.w),
        .h = @intToFloat(f32, kw_rect.h),
    };
}
