# Handoff

## Owed checks (rolling ledger)
The ledger lives in `CHECKS.txt` (answer on the `>` lines). A SessionStart hook opens it in
Notepad whenever an answer is still blank.

---

## Session 8 (2026-09-26): the whole grill order built (season, crime, objects, venues, art)
- Built, all unplayed: bug batch 58 to 61, charged throws step 1 (80), the season and
  payday (72, 78), impatience signals (73), heat and the police (74, with 62's car ram),
  rifling pockets (76), seen versus evidence (77), objects by size (79), critters in hand
  (81), the mansion and churchyard (75 first cut), and the 3/4 art pass (66 to 71).
- Verified: run_all green (exit 0) with new tests: throw, season, police, seen, objects,
  critters, venues. Every feature was also screenshotted headful and looked at. Nothing
  play-checked yet: 21 checks in CHECKS.txt.
- Calls I made while building (vetoable, not in the design doc):
  - Police are called for tier 2, or tier 1 once the job started at heat 3+, and only if
    the customer can see (robbery always). Countdown 60 s, 8 s less per heat level, floor
    20. Fines $50 (tier 1) / $150 (tier 2), x(1 + 0.25 per heat). A fine can put money
    negative. Vandalism after being fired counts once a job.
  - Only thrown stones are crimes; blade-flung ones are accidents (rep only).
  - Short on payday, the heavies take dearest kit first until covered and you keep the
    change; kit resells at half price. Heat cools a level per week paid.
  - Customer indoors share by persona: perfectionist 0.1, gardener 0.25, nature 0.3, grump
    0.35, squirrel hater 0.4, toff 0.5, busy 0.7.
  - Venues: 40% of offers at 75+ rep are a mansion (1.8x pay); 50% under 20 rep (not the
    dregs) are the churchyard (0.7x). Mansion windows cost 3x, urns $120.
  - Props per garden: gnomes (more for the gardener), 30% flamingo, 20% cone, 60% hose,
    a ball if there's a dog, 0 to 2 boulders.
- Side effects: the mower's collision is now its foreshortened footprint, so the ride-on
  got quicker in sim_balance (50% at 86 s, was 99 s). audio/splash.wav no longer matches
  tools/make_audio.py exactly; left as committed. Trap noted in docs/TRIBAL.md: a texture
  load()ed in _draw draws as a white box.
- New cheat: [4] on the board takes 20 rep off (to reach the churchyard).

OWED CHECKS: 21, in CHECKS.txt (5 loads, about 35 minutes).

NEXT:
1. Play the checks; triage what they turn up.
2. 80b, throwing step 2 (arcs), once S8-THROW has been played.
3. 75b (the loop drive joining the road, the golf course), 46, 55.

## Session 7 (2026-09-26): check triage and the big grill (the season, crime, venues, throwing)
- Checks: all 16 answered, CHECKS.txt cleared. Passed: the six S5 checks, S6-DEPTH, HEDGE,
  GARAGE, WINDOW, CUSTOMER, CAR (mostly). Problems triaged into NOTES 58 to 71: the on-foot
  sprite flips upside down (58, BLOCKS; diagnosed from code, not reproduced: walker.gd
  rotates every frame but redraws only every 9 px of stride), the knocked-out customer
  still turns (59), the car hitbox is 110 tall where the sprite's footprint is 66 (60),
  stones vanish on walls (61), and a 3/4 art pass (66 to 71: pond and beds, tree bases,
  fences, chimney, garage depth, featureless ground next door).
- Your calls (vetoable, all in the design doc, game-dev 948250a onward):
  - The run is a 4-week season, 3 jobs a week, a loan shark's payment each week ($120,
    $250, $450, $750, a guess); a miss sends his heavies to repossess kit; you can sell kit;
    zero rep gives the dregs, not "File for bankruptcy"; paying week 4 wins. Runs are years
    (leaning: the 1980s, starting 1980). Only the payments ramp: the rep tiers are the
    difficulty curve, unchecked.
  - Impatience keeps its rules, gains signals (watch glance, sigh, escalating nags).
  - Heat is separate from rep, only for crimes; a four-tier crime ladder with
    proportional punishment (fines, a lost job slot, season over only for killing); heat
    shortens a visible police countdown and cools a level per week paid; no job-start
    arrest roll. Rifling pockets trickles cash while held. Animals thrown into things tier
    the crime up.
  - Seen versus evidence: the customer moves between patio, inside and windows; unseen
    acts are judged by what's left; the portrait greys out.
  - Venues by rep band (mansion and graveyard first), community service later.
  - Between jobs: a walkable hub is the destination; a menu plus a payday scene for now.
  - Objects: small (carry, throw, mow), medium (shoved), big (solid); charged throws
    locked in place with a landing marker, vertical angle as step 2.
  - 8 facings left to soak (a diagonal sprite points about 31 deg while you travel 45).
  - The car: mower ramming dents it too, harder hits cost more.
- Promoted from NOTES to the design doc: 21, 22, 25, 26, 27, 29, 38, 40, 56, 63, 64, 65.
  Build items 72 to 81 replace them. Parked: 21b (job types), 27b (the drive), 30b grown
  into the menace board.
- No code changed. Verified: run_all green (exit 0).

OWED CHECKS: none (CHECKS.txt says nothing owed).

NEXT (NOTES has the full order):
1. 58, the on-foot sprite flip, then 59 to 61 as a bug batch.
2. 80, charged throws step 1.
3. 72 with 78, the season and the payday scene: the new spine.

## Session 6 (2026-09-25): the visual session, full 3/4, and the world past the garden
- Your calls: full 3/4 (you and your partner picked (c) from three mocked-up styles, over
  pure top-down and a tilt on fixed things); trees go 3/4 with the rest (replaces the
  top-down tree call); the house set into the plot with its ridge on the back fence ("if
  you can't see there, you can't go there"), which made the drive 40% shorter; 8 facings
  for things that turn. The voxel look is provisional until you've seen it in motion. All
  in the design doc's "Look and Sound" (game-dev aed9362, a234275, b147e5e, 4adb3de).
  Parked there: front and back yards.
- Built, NOTES 57 in five steps: a two-storey 3/4 house and garage (7f69cc8, e94e12f);
  fences, hedges, truck and trailer 3/4, the road-side run fading while you're behind it
  (2d67f27, covers 54); Y-sorting, house and garage sorting at their wall foot (a20aa1b);
  trees with a round trunk and roots (6794c1c); mowers, you on foot, critters, the dog and
  then the customer as voxel models at 8 facings from tools/voxel.py (9fe4c35, 33bf79f).
- Built, rough versions of 55 and most of 46: beyond.gd puts neighbours (house, woods or an
  empty lot), a treeline and houses across the road round every job (ff68092); detached
  garages and the customer's car in the drive (93ff326).
- My calls, flagged for your veto: a car dent costs $40 and -20 mood ("My CAR!"); the car
  is in half the generated jobs, never the first; a third of garages stand 80 px apart.
- Balance: the house footprint change cost about 9% of mowable area with patience
  unchanged; the bot's times moved within noise (push 278 to 261 s, petrol 189 to 180,
  ride-on 130 to 154 to 85%), so no retune.
- The 49 FPS was the laptop's hybrid-GPU present, not the game (da715d3, 7450952, TRIBAL).
- Tools: tools/shot.gd saves screenshots of the default job (in CLAUDE.md).
- Verified: run_all green (17 tests; test_street gained the car and detached garage, with a
  mutation check that its assert fires). Everything was eyeballed in screenshots; none of
  it was played.

OWED CHECKS: CHECKS.txt (16 checks, four loads, about 30 min). The six S5 checks have now
rolled twice.

NEXT:
1. Play CHECKS.txt, especially S6-LOOK and S6-FACINGS, and live with the voxel look.
2. A `/grill` on 21 (escalation, the biggest), 22, 25, 26, 27, 29, 38, 40 and 56 (the
   obstacle rules: what's solid, mowable, throwable, costly).
3. Leftovers buildable any time: 46 (drive shape), 55 (a park or playground, a better lot).

## Session 5 (2026-09-25): your session-4 answers, five small fixes, pad prompts
- Your session-4 answers: 11 of 15 were yes (settings, ads, squash, dog, tally, fired,
  splash, throws, talking, tells, pad menus mostly), several with notes; audio, street,
  trees and view were not. All of it became NOTES 44-56 (46e2220); 47 (board left/right)
  waits on the shop (27).
- Your calls: my 3/4 trees are vetoed (the flat trunk reads as cardboard): trees go back
  top-down, the house keeps its face. Audio is yours, in Ableton, later; the generated
  sounds are placeholders. Promoted to the design doc as "Look and Sound" (game-dev
  339e539), veto any. Perspective and scale overall go to a visual design session (44).
- Built (c6db936): one scream per burst of flowers (1.5 s cooldown, rep still counts every
  flower); the engine starts silent (its loops start at sample -2017/2250, so full volume
  at play() would click; the likely cause of the job-start pop, not heard); splashes fit
  inside the pond's water; a stoned tree's canopy sways and drops the leaves; talk is
  slower (0.18 s a word) with talk mouths that flip open/shut against the resting face.
- Built (e95a237): prompts follow the last device, [E] on keys, (A) on a pad, in hints,
  the first briefing and the title help. Text, not drawn icons, until the visual session.
- My call, flagged for your veto: Xbox button names.
- Verified: run_all green (17 checks; new test_prompts, and test_hazards gained the splash
  fit and the scream cooldown). The face sheet was eyeballed. None of it played or heard.

OWED CHECKS: CHECKS.txt (6 checks, two loads, about 10 min).

NEXT:
1. The visual design session (NOTES 44): the same garden mocked up (a) pure top-down,
   (b) a shallow tilt on tall things only, (c) full 3/4, with the house/drive/lawn scale
   fixed. I lean (b). The tree redraw and 54-56 wait on it.
2. Play CHECKS.txt whenever.
3. A `/grill` on the queued design items: 21 (escalation, the biggest), 22, 25, 26, 27,
   29, 38, 40, plus 56 (obstacle rules).

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
