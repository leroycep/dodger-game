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

    extern fn blitSurface(driver: ?*KW_RenderDriver, src: ?*KW_Surface, srcRect: ?*const KW_Rect, dst: ?*KW_Surface, dstRect: ?*const KW_Rect) void {
        const self = @fieldParentPtr(Self, "driver", driver.?);
    }

    extern fn createSurface(driver: ?*KW_RenderDriver, width: c_uint, height: c_uint) ?*KW_Surface {
        const self = @fieldParentPtr(Self, "driver", driver.?);
        return null;
    }

    extern fn getSurfaceExtents(driver: ?*KW_RenderDriver, surface: ?*const KW_Surface, width: ?*c_uint, height: ?*c_uint) void {
        const self = @fieldParentPtr(Self, "driver", driver.?);
    }

    extern fn getTextureExtents(driver: ?*KW_RenderDriver, texture: ?*KW_Texture, width: ?*c_uint, height: ?*c_uint) void {
        const self = @fieldParentPtr(Self, "driver", driver.?);
    }

    extern fn renderCopy(driver: ?*KW_RenderDriver, src: ?*KW_Texture, clip: ?*const KW_Rect, dst: ?*const KW_Rect) void {
        const self = @fieldParentPtr(Self, "driver", driver.?);
    }

    extern fn renderText(driver: ?*KW_RenderDriver, font: ?*KW_Font, text: ?*const u8, color: KW_Color, style: KW_RenderDriver_TextStyle) ?*KW_Texture {
        const self = @fieldParentPtr(Self, "driver", driver.?);
        return null;
    }

    extern fn loadFont(driver: ?*KW_RenderDriver, fontFile: ?*const u8, ptSize: c_uint) ?*KW_Font {
        const self = @fieldParentPtr(Self, "driver", driver.?);
        return null;
    }

    extern fn loadFontFromMemory(driver: ?*KW_RenderDriver, fontMemory: ?*const c_void, memSize: c_ulong, ptSize: c_uint) ?*KW_Font {
        const self = @fieldParentPtr(Self, "driver", driver.?);
        return null;
    }

    extern fn createTexture(driver: ?*KW_RenderDriver, surface: ?*KW_Surface) ?*KW_Texture {
        const self = @fieldParentPtr(Self, "driver", driver.?);
        return null;
    }

    extern fn loadTexture(driver: ?*KW_RenderDriver, file: ?*const u8) ?*KW_Texture {
        const self = @fieldParentPtr(Self, "driver", driver.?);
        return null;
    }

    extern fn loadSurface(driver: ?*KW_RenderDriver, file: ?*const u8) ?*KW_Surface {
        const self = @fieldParentPtr(Self, "driver", driver.?);

        const kw_surface = self.allocator.create(KW_Surface) catch return null;
        kw_surface.surface = GPU_LoadSurface(file);

        return kw_surface;
    }

    extern fn releaseTexture(driver: ?*KW_RenderDriver, texture: ?*KW_Texture) void {
        const self = @fieldParentPtr(Self, "driver", driver.?);
    }

    extern fn releaseSurface(driver: ?*KW_RenderDriver, surface: ?*KW_Surface) void {
        const self = @fieldParentPtr(Self, "driver", driver.?);
        if (surface) |surf| {
            SDL_FreeSurface(@ptrCast(*SDL_Surface, @alignCast(@alignOf(*SDL_Surface), surf.surface)));
            self.allocator.destroy(surf);
        }
    }

    extern fn releaseFont(driver: ?*KW_RenderDriver, font: ?*KW_Font) void {
        const self = @fieldParentPtr(Self, "driver", driver.?);
    }

    extern fn getClipRect(driver: ?*KW_RenderDriver, clip: ?*KW_Rect) KW_bool {
        const self = @fieldParentPtr(Self, "driver", driver.?);
        return KW_bool.KW_TRUE;
    }

    extern fn getViewportSize(driver: ?*KW_RenderDriver, rect: ?*KW_Rect) void {
        const self = @fieldParentPtr(Self, "driver", driver.?);
    }

    extern fn setClipRect(driver: ?*KW_RenderDriver, clip: ?*const KW_Rect, force: c_int) void {
        const self = @fieldParentPtr(Self, "driver", driver.?);
    }

    extern fn releaseRenderDriver(driver: ?*KW_RenderDriver) void {
        const self = @fieldParentPtr(Self, "driver", driver.?);
    }

    extern fn utf8TextSize(driver: ?*KW_RenderDriver, font: ?*KW_Font, text: ?*const u8, width: ?*c_uint, height: ?*c_uint) void {
        const self = @fieldParentPtr(Self, "driver", driver.?);
    }

    extern fn getPixel(driver: ?*KW_RenderDriver, surface: ?*KW_Surface, x: c_uint, y: c_uint) c_uint {
        const self = @fieldParentPtr(Self, "driver", driver.?);
        return 0;
    }
};
