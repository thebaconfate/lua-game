-- engine.lua
local ffi = require("ffi")

-- 1. Tell LuaJIT exactly which C structures and functions we want to steal from SDL2
ffi.cdef [[
    typedef struct OptionWindow SDL_Window;
    typedef struct OptionRenderer SDL_Renderer;
    typedef struct OptionTexture SDL_Texture;

    typedef union {
        uint32_t type;
        uint8_t padding[56];
    } SDL_Event;

    int SDL_Init(uint32_t flags);
    SDL_Window* SDL_CreateWindow(const char* title, int x, int y, int w, int h, uint32_t flags);
    SDL_Renderer* SDL_CreateRenderer(SDL_Window* window, int index, uint32_t flags);
    SDL_Texture* SDL_CreateTexture(SDL_Renderer* renderer, uint32_t format, int access, int w, int h);

    int SDL_UpdateTexture(SDL_Texture* texture, const void* rect, const void* pixels, int pitch);
    int SDL_RenderClear(SDL_Renderer* renderer);
    int SDL_RenderCopy(SDL_Renderer* renderer, SDL_Texture* texture, const void* srcrect, const void* dstrect);
    void SDL_RenderPresent(SDL_Renderer* renderer);

    int SDL_PollEvent(SDL_Event* event);
    void SDL_DestroyTexture(SDL_Texture* texture);
    void SDL_DestroyRenderer(SDL_Renderer* renderer);
    void SDL_DestroyWindow(SDL_Window* window);
    void SDL_Quit(void);
    void SDL_Delay(uint32_t ms);
]]

-- 2. Load the native Linux shared library
local SDL = ffi.load("SDL2")

-- Initialize Video Subsystem
if SDL.SDL_Init(0x00000020) ~= 0 then error("SDL Init Failed") end

-- Constants
local WIDTH, HEIGHT = 320, 240
local SCALE = 4
local VRAM_SIZE = WIDTH * HEIGHT * 4 -- RGBA

-- Create Window, Accelerator Renderer, and a Streaming VRAM Texture
local window = SDL.SDL_CreateWindow("Pure Rawdog Lua Engine", 450, 450, WIDTH * SCALE, HEIGHT * SCALE, 0)
local renderer = SDL.SDL_CreateRenderer(window, -1, 0x00000002)
-- 0x16562004 is SDL_PIXELFORMAT_RGBA8888
local texture = SDL.SDL_CreateTexture(renderer, 0x16562004, 2, WIDTH, HEIGHT)

-- 3. Allocate our raw, pure software VRAM array
local vram = ffi.new("uint8_t[?]", VRAM_SIZE)

-- Primitive Draw Function
local function draw_pixel(x, y, r, g, b)
    if x >= 0 and x < WIDTH and y >= 0 and y < HEIGHT then
        local index     = (y * WIDTH + x) * 4
        vram[index]     = r
        vram[index + 1] = g
        vram[index + 2] = b
        vram[index + 3] = 255
    end
end

-- 4. Main Loop
local running = true
local event = ffi.new("SDL_Event")

local px, py = 160, 120

while running do
    -- Handle OS window event polling
    while SDL.SDL_PollEvent(event) ~= 0 do
        if event.type == 0x100 then -- SDL_QUIT (clicking the X button)
            running = false
        end
    end

    -- Clear VRAM state manually (Paint background dark green)
    ffi.fill(vram, VRAM_SIZE, 0)
    for i = 0, VRAM_SIZE - 1, 4 do
        vram[i] = 15; vram[i + 1] = 35; vram[i + 2] = 15; vram[i + 3] = 255
    end

    -- Simple procedural logic: make our pixel bounce around
    px = px + math.random(-1, 1)
    py = py + math.random(-1, 1)

    -- Draw a small 4x4 block representing our player
    for y = 0, 3 do
        for x = 0, 3 do
            draw_pixel(px + x, py + y, 255, 200, 0)
        end
    end

    -- Shovel our CPU-managed memory straight over to the graphics window context
    SDL.SDL_UpdateTexture(texture, nil, vram, WIDTH * 4)
    SDL.SDL_RenderClear(renderer)
    SDL.SDL_RenderCopy(renderer, texture, nil, nil)
    SDL.SDL_RenderPresent(renderer)

    -- Cap it roughly near 60fps so your CPU doesn't melt screaming at 4000fps
    SDL.SDL_Delay(16)
end

-- Clean up memory allocations directly
SDL.SDL_DestroyTexture(texture)
SDL.SDL_DestroyRenderer(renderer)
SDL.SDL_DestroyWindow(window)
SDL.SDL_Quit()
