# Handoff

## Owed checks (rolling ledger)
Grouped by what you load, so one sitting covers it. Run from the `long-horizon` branch.
Board cheat for testing: F9 on the job board adds $500 (debug builds only).

**LOAD 1 of 5: title and board (2 min)** (S1)
- [ ] Title: the attract-mode mower stripes the lawn behind the menu; the text stays readable
- [ ] The pixel font reads well everywhere (title, board, HUD, panels); nothing clipped
- [ ] Board: offers, shop and header fit; F9 money cheat works; buying/using mowers updates
- [ ] Menu music plays; button move/select blips are not annoying

**LOAD 2 of 5: a first job with the push mower (8 min)** (S1)
- [ ] Briefing shows the customer, their hints and (first job only) the controls
- [ ] Push mower: speed, 28px cut, stamina (PEP/ZZZ gauge) and resting feel right; exhausted it crawls but still cuts
- [ ] Stripes: mowing up/right gives light bands, down/left dark; re-mowing restripes
- [ ] Hedgehogs/squirrels readable at a glance; squashes read (splat, squeak, shake, face reaction, speech)
- [ ] The corner face changes with mood and reacts to events; the patio customer turns to watch and hops
- [ ] Past their patience they nag ("Are you nearly done?"). Is that enough of a clue to the hidden time?
- [ ] Hand in at the truck: refused if far short; when paid you can hang about; the pay screen makes sense
- [ ] Is a push-mower job winnable? The balance bot says 70% takes ~4 min on a small lawn (see NEXT)

**LOAD 3 of 5: petrol mower job (6 min)** (S1)
- [ ] Engine note rises with speed; low-fuel beep; glug while refuelling at the truck
- [ ] Tank (60s) and refuel trips feel like a real trade against the push mower
- [ ] Mower condition gauge (OK/BUST): head-on hits hurt, scraping along walls doesn't; repairs at the truck
- [ ] Mow over a stone: clonk, damage, and usually it flies. Watch it hit a window (glass, -$40), the wall, the truck (-$20), wildlife, the customer (hurt face)
- [ ] Hop off [F]: camera follows you, the parked mower shows empty; carry a stone to the truck [E]; fetch the fuel can from the truck menu and pour it [E]
- [ ] Dog jobs: the dog gets out, bounds about; catching it on foot and walking it home earns thanks; bowling it over with the mower is a disaster
- [ ] Tree edges: can you get tight to a trunk? Trees hide what's under the canopy: fair or annoying?

**LOAD 4 of 5: misbehaving (5 min)** (S1)
- [ ] After being paid, squash/trample/smash something: "Rep -N" pops, and the result screen charges it
- [ ] Run the customer over on the patio: knocked flat, KO face, "Leave quietly" only, no pay
- [ ] The board then shows WANTED; a later job may open with ARRESTED and end the run
- [ ] Getting fired (a gardener's flowers, or mood to zero) ends the job with the buzzer

**LOAD 5 of 5: ride-on and a whole run (10 min)** (S1)
- [ ] Ride-on: huge cut, fast, turns like a barge; the trailer shows behind the truck once owned
- [ ] Bigger lawns unlock as reputation rises; the job board shrinks as it falls; bankruptcy at zero
- [ ] Pause menu: music and sound toggles work and are remembered
- [ ] Gamepad: stick/d-pad drive, A interact, X hop, Start pause

---

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
  gamepad, sound toggles, a balance probe.
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
  trailer is cosmetic), robot mowers, salting the lawn, water features, the serial-killer run
  as a distinct thing.
- Housekeeping: early test runs wrote a stray best score ($140) to this machine's real save
  (`%APPDATA%\Godot\app_userdata\Super Landscaper\best.cfg`) before tests got their own file.
  Delete it if you want a clean slate.

OWED CHECKS: the five loads above.

NEXT:
1. Play the five loads and send notes (triage them in one pass).
2. Decide the experiment's verdict: merge `long-horizon` into `main`, cherry-pick, or rewrite.
3. Sign off or change the MY CALLS list, then fold the kept ones into the design doc.
4. Balance: the push mower is tight against most customers even for the bot
   (`tests/sim_balance.gd`); tune once you've felt it.
