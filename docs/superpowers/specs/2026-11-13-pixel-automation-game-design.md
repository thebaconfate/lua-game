# Pixel automation RPG — design

Date: 2026-11-13
Status: draft, awaiting approval

## Intent

Two goals, in this order:

1. **Learn graphics algorithms**, above all *concurrent animation*: many
   things moving at once, smoothly, each on its own timing. Previous
   (uni) games were turn-based and redrew static images each turn; this
   project exists to get past that.
2. **Long term, maybe ship on Steam** — only if the game turns out to be
   genuinely enjoyable. This is a direction, not a deadline.

Secondary goal: get better at **Lua** now, and **C** later where it pays off.

## The game (long-term vision)

A real-time, pixel-art **automation RPG** in **three-quarter view**
(camera tilted so you see characters' bodies and the fronts of walls, on a
square grid — not isometric diamonds).

- You play a **human character** walking around the world, not a mech.
- You start doing work by hand; **quests unlock** tools, buildings and
  recipes, giving progress direction and a steady supply of new things.
- You **automate mining, smelting and farming** with **machines and
  conveyors** first.
- Later expansion: **drone haulers** that fly items point-to-point (no
  pathfinding needed). Walking workers are not planned.

Prior art the player loves: *Dyson Sphere Program* (top 3), *Timberborn*.
*InfraSpace* was fun but became monotone — growth that stops bringing
anything new is the failure to avoid.

Setting/theme (medieval, sci-fi, frontier…) is deliberately **undecided**
until something is playable.

## Goals

- A software renderer the developer understands end to end: every pixel
  is written by our own code into our own framebuffer.
- Smooth, frame-rate-independent animation of many simultaneous things.
- A short ladder of milestones, each ending in something visible on screen.
- A first playable automation slice (milestone 6) to answer "is this fun?"

## Non-goals (for now)

- Quests, farming, drones, combat, story, saving/loading, audio, menus.
- Final art or a chosen theme.
- Windows/macOS builds and Steam packaging.
- Writing anything in C before there is a measured reason.

## Anti-goals (would be failure even if it "works")

- **Letting a library draw for us.** SDL's renderer is used only to put the
  finished framebuffer on screen; no `SDL_RenderTexture` per sprite, no
  SDL rotation/scaling of game objects. That would skip the learning.
- **Infrastructure before motion.** Weeks of engine plumbing with nothing
  moving on screen. Every milestone must end visibly.
- **Art blocking code.** Placeholder shapes/free assets until milestone 6.
- **Stutter.** Garbage-collection pauses from allocating per-frame objects
  in hot loops.

## Constraints

- **Language/runtime:** LuaJIT 2.1 (Lua 5.1 dialect + FFI), as installed
  on the dev machine (Fedora 44).
- **Platform layer:** SDL3 3.4, called directly through LuaJIT FFI
  (`ffi.cdef` declarations), no binding library and no framework (no LÖVE).
  The `SDL3-devel` package is not installed, so load by soname:
  `ffi.load("libSDL3.so.0")` (or install `SDL3-devel` for `libSDL3.so`).
- **Performance headroom (measured 2026-11-13 on the dev machine):** a
  LuaJIT benchmark clearing a 320×180 FFI framebuffer, updating/drawing
  5,000 particles from flat FFI arrays and blitting 1,000 transparent
  16×16 sprites took **1.15 ms/frame** (budget 16.67 ms at 60 fps). With
  the JIT disabled it took 27.8 ms — so hot loops must stay JIT-friendly
  (FFI arrays, no per-frame table allocation, no NYI functions in loops).
- **Image decoding:** SDL3_image (installed) may be used *only to decode*
  PNGs into pixel arrays; drawing them is our code.
- **Existing code:** github.com/thebaconfate/lua-game — `engine.lua`
  (SDL2 via FFI, 320×240 software framebuffer, fixed `SDL_Delay(16)` loop),
  `constants.lua`, immutable `position.lua`, and a `main.lua` that only
  exercises `Position`. Notes for the builder:
  - The texture format constant `0x16562004` is actually
    `SDL_PIXELFORMAT_XBGR8888` (the comment says RGBA8888). On little-endian
    that stores bytes as R,G,B,X, so the existing byte writes are correct;
    fix the comment or switch to the `SDL_PIXELFORMAT_RGBA32` alias.
  - `VRAM_SIZE = WIDTH * HEIGHT * SCALE` uses the window `SCALE` (4) as the
    bytes-per-pixel count. It works only because both are 4; split them.

## Approaches considered

| Approach | Trade-off |
|---|---|
| **Lua-first on the existing repo (LuaJIT FFI + SDL3), move hot paths to C later** — *chosen* | Builds on working code; Lua is a target language; FFI arrays make per-pixel writes fast. Less C up front; Steam packaging is manual. |
| C engine first, Lua scripting later | Most C practice, but a C core *and* a Lua binding layer before anything animates — the classic place hobby projects stall. |
| Pure C + SDL3 | Fastest runtime, maximum control; slowest to get moving, no Lua practice. |
| Lua + LÖVE | Fastest start, but LÖVE draws, scales and emits particles for you — the easy path skips exactly what's meant to be learned. |

The developer chose **Lua-first**. C enters only when profiling shows a
routine is too slow (likely candidates: sprite blitting, conveyor item
updates); that routine is written as a small C shared library and loaded
through the same FFI.

## Decided

By the developer:

- Real-time (not turn-based), three-quarter view.
- Lua-first on the existing repo; upgrade SDL2 → SDL3.
- Machines + conveyors are the first automation; drones are a later
  expansion.
- Human character; quests unlock content; mining, smelting, farming.
- Hot paths written imperatively (plain loops over flat arrays, mutated in
  place); functional style is fine for non-per-frame code.

Calls made by Claude (open to change):

- **Internal resolution 320×180** (16:9), integer-scaled to the window
  (×4 = 1280×720, ×6 = 1920×1080), replacing 320×240 (4:3) because modern
  monitors and Steam Deck are widescreen. Use SDL3's logical presentation
  with integer scaling for the final blit.
- **16×16 px tiles**, characters roughly 16×24.
- **Fixed-timestep simulation at 60 Hz** with an accumulator, timing from
  `SDL_GetPerformanceCounter`; rendering once per frame with vsync on.
- **Input:** WASD/arrow keys to walk (via `SDL_GetKeyboardState`), mouse to
  place/remove buildings.
- Placeholder art (coloured rectangles, then free CC0 pixel-art packs)
  until milestone 6.
- **Milestone 6 is a sandbox:** building is free (no costs/inventory to pay
  with), no hand-mining, no quests — just build the chain and watch it run.
- **Conveyors in milestone 6:** straight segments and 90° turns only; no
  splitters, mergers or priorities.

## Milestones

Each ends in something visible. "Learn" names the techniques it exercises.

1. **SDL3 + real game loop.** Port the FFI layer to SDL3. A square moves
   with the keyboard at the same speed regardless of frame rate.
   *Learn:* fixed timestep, accumulator, separating update from render.
2. **Sprites.** Decode a PNG into a pixel array; draw it into the
   framebuffer with alpha (at least 1-bit transparency), horizontal flip,
   and clipping at screen edges.
   *Learn:* blitting, alpha, clipping.
3. **Animation.** A character with idle and walk cycles in 4 directions,
   switching cleanly by state and facing.
   *Learn:* sprite sheets, frame timing independent of frame rate,
   animation state.
4. **The world.** A tile map larger than the screen (e.g. 64×64 tiles):
   floor tiles, walls with visible front faces, a camera following the
   player, objects (pillars/trees) the player can walk both behind and in
   front of.
   *Learn:* tilemaps, camera/world↔screen transforms, drawing order by
   y-position (painter's algorithm).
5. **Lots happening at once.** Pre-placed conveyors carrying many items;
   animated machines; particles (sparks, smoke) stored in flat arrays;
   eased motion (pop-in, settle) and a hit/flash effect.
   *Learn:* particle systems, easing/tweening, many independent timers,
   avoiding per-frame allocation.
6. **First playable: tiny factory.** Mouse-placed buildings snapped to the
   grid: a **drill** on an **ore node** → **conveyors** → **furnace** →
   **bars** collected into a visible counter.
   *Learn:* screen→grid picking, simulation of items on belts, machine
   state (idle/working/blocked).
   **Checkpoint: is it fun to build and watch?** Decide theme and next
   steps from here.

Later, roughly in order of likely value: quests & unlocks, farming (crop
growth over time), more resources and recipes, drone haulers, first C hot
path, lighting/darkness and palette effects, Steam packaging.

## Left to the builder

- Module/file layout and naming.
- Sprite sheet format and how animation data is described.
- How items on conveyors are represented (slots vs. continuous offset),
  within the "flat arrays, no per-frame allocation" rule.
- Whether to keep, adapt or drop the immutable `Position` class.
- Testing approach for pure-logic modules (timing, conveyor simulation).
- Which free asset packs to use for placeholders.
