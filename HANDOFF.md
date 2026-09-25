# Handoff

## Owed checks (rolling ledger)
The ledger lives in `CHECKS.txt` (answer on the `>` lines). A SessionStart hook opens it in
Notepad whenever an answer is still blank.

---

## Session 4 (2026-09-25): every buildable NOTES item, the street, the tally, classifieds
- Your session-3 answers: 9 of 12 signed off (title flip, WASD, stamina, face duck, paid
  menu, cheats, spite, glug, stones). Three became NOTES 41-43 and are now built: pad A in
  menus (Godot's ui_accept has no pad button), pond splash (the hit test ignored hop height),
  reactions at the portrait.
- Your calls this session: talking mouth as a second face frame; garage attached left or
  right with the drive to it, truck at the kerb (more variety later, NOTES 46); ads read as
  ads with the customer's gimmick blended in; the tally shows only non-zero counts, as a
  surprise. Promoted to the design doc (veto any): street layout, reactions at the
  portrait, classifieds, the tally (game-dev 4322d86).
- My calls, flagged for your veto: trees went 3/4 (visible trunk, only the trunk is solid,
  canopy fades near you); the fired banner reads YOU'RE FIRED; the corner face no longer
  ducks, because with the camera always centred you can never be near it (it was your option
  b in session 3).
- Also built: splats that last and a red trail, spawn tells (rustle and leaves 0.9s before),
  a dog lead and hints, smashed windows, 16px critter hits, stones at your mower/trees/beds,
  title music/sound toggles, softer menu blips.
- New notes from you: 44 (one view for everything? a feel check), 45 (audio grates and
  leans NES not SNES; synth in the tool or real samples is your call after a listen).
- Verified: run_all green (16 checks; new test_street, test_tells, test_title); screenshots
  of every visual change; sim_balance after the trees and the street stays in the same
  range (push 85% 278s, petrol 189s, ride-on 130s). None of it played or listened to.

OWED CHECKS: CHECKS.txt (15 checks, four loads, about 20 min). S1-PAD is now S4-PAD-MENUS.

NEXT:
1. Play CHECKS.txt and answer on the `>` lines. S4-VIEW and S4-AUDIO feed 44 and 45.
2. A `/grill` session on the queued design items: 21 (escalation, the biggest), 22, 25, 26,
   27, 29, 38, 40.
3. 46, more layout variety, whenever a build session wants something concrete.

## Session 3 (2026-09-24): play-check triage, quick fixes, one rundown, fired stays in the job
- You answered all 29 checks. Signed off: briefing, engine audio, tank trade-off, condition
  gauge, ride-on, push-mower winnability, board fit, hand-in send-back, hanging about, spawns
  avoiding the house/truck/trees. Everything else became NOTES.md items (now the task list).
- Fixed: glug looped forever (one-shot sounds never loop now; ponds had it too); the truck
  refilled push-mower stamina; a g tail bled over the w (reproduced at a 1600x900 window, a
  1px atlas gap fixes it at five sizes); the attract mower's flip showed; WASD in menus.
- Cheats moved off F9 (the editor's pause key): board [1] cash, [2] rep; job [0] perfect
  finish. New CLAUDE.md rule: letters and number row only, no function keys, no backquote.
- One rundown: paying updates the truck menu; driving off goes straight to the board, whose
  Last job panel shows the outcome, money and rep change. The corner face ducks to the bottom
  right when you're near it (your call: option b).
- Fired no longer ends the job (you corrected my 1.5s-then-board version): no pay and the rep
  hit land at once, you stay, spite is mischief, you leave from the truck.
- Handoff now sorts NOTES.md: decided design goes to the doc, the rest waits for a grill or
  sits parked with a date. Promoted this time (veto any): fired stays in the job; tone (no
  punches pulled, gruesome only when you go absurd); the cop-call countdown. The tone call
  supersedes session 1's MY CALLS item "the dog is never killed".
- Verified: run_all green (13 checks; new test_polish and test_fired, both shown to fail with
  their fix removed); screenshots of the title, board rundown, paid and fired truck menus, and
  the ducked face. None of it played.

OWED CHECKS: CHECKS.txt (12 checks, four loads). S1-PAD (gamepad) has been owed since
session 1.

NEXT:
1. Play CHECKS.txt and answer on the `>` lines.
2. Build 12 with 39: the world past the garden (road, footpath, neighbours) and a sensible
   layout (truck on the street or in the drive, a drive and garage). Needs a few layout calls.
3. A `/grill` session on the queued design items: 21, 22, 25, 26, 27, 29, 38, 40.
4. Still open from session 1: sign off or change the rest of the MY CALLS list.

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
