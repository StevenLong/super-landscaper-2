# Handoff

## Owed checks (rolling ledger)
The ledger lives in `CHECKS.txt` (answer on the `>` lines). A SessionStart hook opens it in
Notepad whenever an answer is still blank.

---

## Session 2 (2026-09-24): checks file, merge, garden edges, throwing
- Your first-play notes: critters walked over the house; the world just ended at the edge;
  critters should come from hedges/trees/over fences; throwing a carried stone. All done.
- CHECKS.txt now opens in Notepad at session start while any `>` answer is blank (ported
  from cube). It is the ledger itself, not a copy of this file.
- `long-horizon` fast-forwarded into `main` (`0911e57`); work continues on `main`. The
  branch is still on GitHub; delete it whenever.
- Built: hedge/fence borders outside the lawn with a road gap by the drive; hedgehogs from
  hedges, squirrels from trees or over fences, none behind the house; critters steer round
  the house, truck, trees and ponds; on foot you can't leave the garden; Q throws a stone.
- Verified: run_all green (11 checks; new edges test, and it fails if critter avoidance is
  switched off); screenshot of the borders. Not played.
- Fixed in passing: tools/__pycache__ had been committed; now ignored.
- Fixed the five editor warnings you pasted (two integer divisions, three shadowed names);
  started docs/TRIBAL.md with the warning traps (headless can't see warnings).

OWED CHECKS: CHECKS.txt (29 checks, six loads; load 6 is new).

NEXT:
1. Play CHECKS.txt (loads 1 to 6) and answer on the `>` lines.
2. Sign off or change the MY CALLS list in session 1.
3. Balance once felt (push mower first).

## Session 1 (2026-09-24): scaffold, the first slice, then a long-horizon experiment
- Built on `main`, one slice at a time with your feel checks: Godot 4.7 scaffold and test
  runner, mower and cutting, zoomed follow camera, fuel and truck, vertical fuel gauge, tree
  and flowerbed. Your verdicts: steering, speed, cut width, blocky grass, zoom and smoothing
  all good; empty tank is a fair punishment; truck easy to find.
- Then the experiment you asked for, on branch `long-horizon` (`d47035d`..): take it as far as
  possible without checking in, then refine. `main` is untouched since `69a0d8a` for comparison.
- Built on the branch: wildlife, the customer (face, mood, briefing, pay, firing), the run
  (title, job board, shop, reputation, bankruptcy), SNES-style art (all generated in code by
  `tools/`), synthesised audio and music, stones and mower damage, on-foot mode, the dog,
  knockouts and the wanted level, post-payment mischief, time nags, pixel font, attract mode,
  gamepad, sound toggles, hold-Tab zoom-out, ponds, a balance probe.
- Verified: `bash tests/run_all.sh` green (10 checks incl. a whole-run flow and a hazards test);
  screenshots of every screen reviewed. Nothing here has been played by a person yet.
- Bugs found and fixed on the way: 100% was unreachable (corner cells); scraping along a wall
  wrecked the mower (the balance bot found it); deferred focus errors; the gardener firing the
  bot for trampling.
- MY CALLS, NEED YOUR SIGN-OFF (the design doc doesn't cover them; I have not written them
  into `../game-dev/Super Landscaper.md`):
  - Empty tank: crawl, no cutting. Exhausted push mower: crawl, still cuts.
  - Six personas (nature lover, squirrel hater, gardener, busy, perfectionist, grump). Only
    the gardener has a stated instant-fail (3+ flowers).
  - Hand-in refused below 60% of their hidden target (sends you back, -10 mood).
  - Pay = base x quality (squared below target) x lateness (floor 40%) x mood (0.5 to 1.5),
    plus a 25% tip if delighted, on time and on target. Fuel, repairs and damages come off.
  - Reputation moves half-way to its trend each job; 3/2/1/0 offers at 45/20/0; medium lawns
    at 55, large at 75.
  - Wanted level: +1 per knockout (+2 if by mower), 12% arrest chance per level per job,
    decays a third per paid job. Arrest ends the run.
  - The dog is bowled over and limps home, never killed (I kept it slapstick).
  - Mischief after payment: -3 rep per squash, -2 per flower hit, -5 window, -8 dog or
    customer. A paid customer can't fire you.
  - Mower prices $180 / $650; upgrades: bigger tank $120, sharp blades $150.
- Not built (deliberately): the garden/meta track, leaderboards, truck inventory Tetris (the
  trailer is cosmetic), robot mowers, salting the lawn, the serial-killer run
  as a distinct thing.
- Housekeeping: early test runs wrote a stray best score ($140) to this machine's real save
  (`%APPDATA%\Godot\app_userdata\Super Landscaper\best.cfg`) before tests got their own file.
  Delete it if you want a clean slate.

OWED CHECKS: CHECKS.txt (26 checks, five loads).

NEXT:
1. Play the five loads and send notes (triage them in one pass).
2. Decide the experiment's verdict: merge `long-horizon` into `main`, cherry-pick, or rewrite.
3. Sign off or change the MY CALLS list, then fold the kept ones into the design doc.
4. Balance: the push mower is tight against most customers even for the bot
   (`tests/sim_balance.gd`); tune once you've felt it.
