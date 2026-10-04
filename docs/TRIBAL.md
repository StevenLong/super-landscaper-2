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
- A drift prop (a regular's garden gaining a gnome between visits) is placed by `_place`
  and silently skipped when a crowded garden has no room; a flow test on a random seed
  failed that way once. Tests that count placed props pin the seed (`new_run(7)`).
- "The dead stay dead" (season prototype, 2026-09-29) had nothing to act on: no garden
  resident dies for good. The dog only limps; hedgehogs and squirrels are fresh spawns each
  visit. It waits for something killable that belongs to the garden.
- A background comparison that `git stash`ed robot.gd and main.gd to run the old code was
  killed at its time limit mid-run (2026-10-02), leaving the work stashed. Compare old code
  by copying `git show HEAD:<file>` over the file and copying it back, in the foreground,
  never by stashing in the background.
- A new agent type in `.claude/agents/` loads only when a session starts: the session that
  wrote `verifier.md` had to run it as a general-purpose agent told to read the file.
- Robots used to drive in a straight line at any target the grid couldn't reach, which is
  how they "crossed the drive" (the drive is excluded ground) and also how they flattened
  flower beds. The drive is now an explicit crossable rect (Robot.crossable).
- `change_scene_to_file` and `reload_current_scene` take the current scene out of the tree
  at once, so an input handler that leaves and then calls `get_viewport()` hits null: the
  pad's B on the desk crashed that way (2026-10-04). Mark the input handled first (or hold
  the viewport, as pack.gd does). run_all now fails on engine `ERROR:` lines too, bar the
  "resources still in use at exit" each headless run prints.
- Fences between gardens broke three times (S15-FENCE, 219, then the dev's 2026-10-04
  screenshots) because two files lay the one boundary: main.gd _build_borders draws the
  garden's runs, beyond.gd draws next door. S15-FENCE moved the side run's art onto the lawn
  edge (8 wide for a fence, in a 24 border) but next door still started a full border out,
  leaving 16 of nobody's grass and a hole in the back fence line. Now beyond.sides(gap) is
  called from _build_borders with the art's real width, and tests/test_next_door.gd checks
  the meeting over 40 gardens. Change either file's geometry and run that test.
