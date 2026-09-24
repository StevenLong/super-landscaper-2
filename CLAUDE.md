# CLAUDE.md

Super Landscaper: a coin-op-hard roguelite lawnmower game, remaking a college project. Godot 4.

## Design lives elsewhere
The design doc is `../game-dev/Super Landscaper.md` (the game-dev Obsidian vault, a sibling
repo). Read its **First Slice** section before building anything. Do not put design docs here;
if a session changes the design, edit the vault doc and push game-dev too.

## Session protocol
- Start: a SessionStart hook (`.claude/settings.json`) injects the HANDOFF.md ledger and latest
  session, and warns if the clone is behind origin. Pull if warned.
- End: `/handoff` (repo skill in `.claude/skills/handoff`).
- Repo ownership: OWNED (the user's own GitHub account). HANDOFF.md is committed and pushed,
  so the other machine can read it.

## Environment
- Godot 4.x via Steam. The `GODOT` env var (Windows user variable) points at the editor exe;
  set it on each machine, it does not sync.

## Verify
- `bash tests/run_all.sh`: parse check, then `tests/smoke.gd` (runs the title 300 frames)
  and every `tests/test_*.gd`. Exit 0 = all pass. Commit only on a green run.
- Godot exits 0 even on script errors, so a test passes only if it prints a line starting
  `PASS` AND its output has no `SCRIPT ERROR`. Each test runs under a 60s timeout, since a
  failed assert halts the script but leaves godot idling.
- The parse check catches errors, not GDScript warnings, and only in scripts the project loads:
  a parse error in a test file passes it. The test run itself catches those.
- New test: a `tests/test_<name>.gd` extending SceneTree that prints `PASS ...` and calls `quit()`.
  Autoload names (`Game`, `Sfx`) don't compile inside a -s script: use `root.get_node("Game")`.
  Set `save_path` to a test file before anything records a result.
- Balance: `"$GODOT" --headless --fixed-fps 60 --path . -s tests/sim_balance.gd` (a bot mows
  with each mower and prints times to 50/70/85/95%; deterministic, not part of run_all).

## Project
- 2D, Compatibility renderer (keeps a web export open), 1280x720 viewport, stretch
  `canvas_items` with `keep` aspect. A 2x camera follows the player, bounded by the lawn.
- Flow: `title.tscn` -> `board.tscn` (job board + shop) -> `main.tscn` (one job) -> board.
- `game.gd` (autoload Game): run state, mower specs, customer personas, job generation.
  `customer.gd`: pure mood/pay logic. `main.gd`: the job scene, which builds its garden in code.
- Art and audio started out generated: `python tools/make_art.py`, `tools/make_faces.py`,
  `tools/make_font.py`, `tools/make_audio.py` (stdlib only), then `"$GODOT" --headless --editor
  --quit` to import. Once a PNG/WAV is hand-edited, stop regenerating it (the tool would
  overwrite it). Faces and the patio customer use key colours that `Face.swapped()` replaces.

## Keeping this file useful
Aim to keep it under about 60 lines of current rules. Past incidents and "we tried X, it failed
because Y" go in `docs/TRIBAL.md` (create on first use), not here.

## Conventions
- Plain hyphens only in code, comments, commits and docs: no em or en dashes.
- No Co-Authored-By trailer on commits.
