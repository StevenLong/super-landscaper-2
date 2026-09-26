# Tribal knowledge

Traps and "we tried X, it failed because Y". Current rules live in CLAUDE.md.

- GDScript warnings never show headless (not in the parse check, not in tests). Only the
  dev's editor console sees them, so ask for pasted warnings after a feature lands.
- `Vector2i / int` still raises INTEGER_DIVISION, same as `int / int`. Where dropping the
  remainder is intended, put `@warning_ignore("integer_division")` on the line above.
- A local named like a member, a method, or an Object method (`tr`, `panel`, `name`, `size`)
  raises SHADOWED_VARIABLE. Pick another name.
- The job scene "running at 49 FPS" (2026-09-25) was the OMEN laptop's hybrid graphics, not
  the game: an empty tree gave the same 49, every API on the RTX 5080 blocked ~20 ms in
  present, and Vulkan on the AMD iGPU (which drives the panel) ran the job at 1785 FPS
  uncapped. Fix: OMEN Gaming Hub GPU mode "Discrete" (60.0 FPS after). Check `tools/fps.gd`
  (and `EMPTY=1`) before hunting game code for frame rate.
- A texture `load()`ed inside `_draw` and not kept anywhere draws as a solid white box: the
  resource is freed once `_draw` returns while the canvas still points at it. `stone.png`
  hid this for a while because other scripts preload it. Keep a reference (`Stone.texture`).
