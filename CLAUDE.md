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

## Verify (from the repo root; godot exits 0 even on errors, so grep)
- Parse check: `"$GODOT" --headless --editor --quit 2>&1 | grep -E "SCRIPT ERROR|Parse Error|SHADER ERROR"`
  No output = clean. It catches errors, not GDScript warnings.
- Nothing to run until `project.godot` exists.
- The parse check only proves the code parses. In the same session as the first playable scene,
  add a headless smoke test (load the main scene, run a few hundred frames, quit, fail on any
  error) and list its command here.

## Keeping this file useful
Aim to keep it under about 60 lines of current rules. Past incidents and "we tried X, it failed
because Y" go in `docs/TRIBAL.md` (create on first use), not here.

## Conventions
- Plain hyphens only in code, comments, commits and docs: no em or en dashes.
- No Co-Authored-By trailer on commits.
