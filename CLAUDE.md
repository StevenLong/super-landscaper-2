# CLAUDE.md

Super Landscaper: a coin-op-hard roguelite lawnmower game, remaking a college project. Godot 4.

## Design lives elsewhere
The design doc is `../game-dev/Super Landscaper.md` (the game-dev Obsidian vault, a sibling
repo). Read its **First Slice** section before building anything. Do not put design docs here;
if a session changes the design, edit the vault doc and push game-dev too.

## Session protocol
- Start: read `HANDOFF.md` (owed checks + latest session) and `git pull`.
- End: `/handoff` (repo skill in `.claude/skills/handoff`).
- This is an owned repo: HANDOFF.md is committed and pushed, so the other machine can read it.

## Environment
- Godot 4.x via Steam. The `GODOT` env var (Windows user variable) points at the editor exe;
  set it on each machine, it does not sync.

## Verify (from the repo root; godot exits 0 even on errors, so grep)
- Parse check: `"$GODOT" --headless --editor --quit 2>&1 | grep -E "SCRIPT ERROR|Parse Error|SHADER ERROR"`
  No output = clean. It catches errors, not GDScript warnings.
- Nothing to run until `project.godot` exists.

## Conventions
- Plain hyphens only in code, comments, commits and docs: no em or en dashes.
- No Co-Authored-By trailer on commits.
