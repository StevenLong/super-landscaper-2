# Notes (task list)

Triaged dev notes. Each item: tag, size, the note, root cause or home file, FIX sketch,
open QUESTION. Design decisions still go to `../game-dev/Super Landscaper.md` once made;
this file holds the work and the undecided ideas.

### Notes 2026-09-24 (play-check answers, CHECKS.txt loads 1 to 6)

Tags: BUG / FEATURE / VISUAL / DESIGN (needs a call before building) / PARKED / ANSWER.
BLOCKS = spoils the next playtest. DONE items stay until the handoff that records them.

**Bugs and quick fixes**

1. [DONE] [BUG, small, BLOCKS] Fuel-can glug plays forever after pouring (S1-ONFOOT).
   Root cause (read, not observed): `tools/make_audio.py:146` writes glug.wav with loop
   points for the truck's continuous player (`truck.gd:27`), but `main.gd:409` (pour) and
   `main.gd:667` (stone into a pond, "plop") play the same looping WAV one-shot through
   `Sfx.play`, which never stops it. Not about the tank being full. Ponds have the same bug.
   FIXED in `Sfx.play`: a one-shot never loops (covers every caller).
2. [DONE] [BUG, small, BLOCKS] The truck refills push-mower stamina (S1-PUSH). `truck.gd:21-23`
   calls `add_fuel` on any body in the zone, and stamina is stored in `fuel`.
   FIX: refuel only `power == "fuel"`; stamina recovers by resting only.
3. [DONE] [VISUAL, small] A little line like an accent over the W on the title (S1-ATTRACT,
   S1-FONT). Root cause (reproduced: the old font at a 1600x900 window shows it, the new one
   doesn't at any of five sizes): in `art/font.png` the `g` descender sits on the last row of its cell, directly above the `w` cell, and cells
   touch, so sampling at some window scales pulls it in. FIXED: a 1px gap between cells.
4. [DONE] [VISUAL, small] The attract mower visibly flips at each row end (S1-ATTRACT).
   `attract.gd:43` turns 60px past the screen edge, less than the sprite's half-length.
   FIX: turn further off screen.
5. [DONE] [BUG, small] F9 (board cash cheat) is also the editor's pause-the-running-game key
   (S1-BOARD). Cheats moved to the number row. Rule now in CLAUDE.md: letters and number
   row only, no function keys, no backquote, numpad last.
6. [DONE] [FEATURE, small] WASD should drive menus too (S1-MENU-AUDIO). `project.godot` has no
   `ui_up/down/left/right` overrides. FIXED: `game.gd` adds W/S/A/D to them at startup.
7. [DONE] [FEATURE, small] Dev cheat for the high end (S1-RUN): boost rep, and instantly complete a
   job with max pay and rep. Lets you see medium/large lawns and ponds without grinding.
   FIXED, debug builds only: board [1] +$500, [2] +20 rep (redeals offers); in a job [0]
   ends it delighted, on time, whole lawn.
8. [VISUAL, small] Menu blips: a bit lower in pitch, less hiss (S1-MENU-AUDIO). Optional.
   Home: `tools/make_audio.py` ui_move / ui_select.

**Feel and readability**

9. [DONE] [FEATURE, moderate] One results screen, not two (S1-HANDIN, S1-MISCHIEF). Now: the
   "Paid!" panel at the truck (`main.gd:509`) then "Job done" on leaving (`main.gd:574`).
   Wanted: payment at the truck is just the money (the +$ pop, maybe the quote); leaving
   shows one rundown on the board screen (paid, spent, rep change). Mischief is enough as
   the "Rep -N" pop above the head.
   DONE: paying updates the truck menu (quote, amount, Drive off / Keep going); leaving
   goes straight to the board, whose top-left panel is the rundown (face, outcome, paid,
   costs, net, rep change, mischief, wanted). A firing holds 1.5s for the buzzer first.
10. [VISUAL, small] The corner face can cover the player (S1-FACE). FIX options: (a) move
   the face to the corner nearest the customer (your idea), (b) move it to the opposite
   corner, or fade it, whenever the player gets near it. DECIDED: (b).
11. [FEATURE, small] Spawn tells (S2-BORDERS, S2-SPAWNS): a tree or hedge rustles, a few
   leaves drop, a moment before a critter comes out. A little telegraphing, not a lot.
12. [FEATURE, moderate-large] Camera never clamps; the world carries on past the garden
   (S2-BORDERS): footpath and road to the south, next door's gardens either side, seen but
   not reachable. The player stays centred. Critters then spawn where the player can see
   them but can't already be, which ends the unavoidable one-pixel-step-into-the-blades hit.
   Home: `main.gd:67-70` camera limits, garden build in `main.gd`.
13. [VISUAL, moderate] Trees (S1-TREES): they don't read as trees; things under canopies got
   hit unseen. Bigger canopies that fade when you get close or under, much bolder trunks
   that read as solid, varied trunk sizes. Variety of objects expected later, not now.
14. [VISUAL, moderate] A squash leaves a lasting splat, and the mower trails red for a short
   distance after (S1-CRITTERS).
15. [FEATURE, small] Dog pickup/walk-home isn't clear that you're interacting (S1-DOG).
   FIX: a visible lead or held state and a prompt.
16. [VISUAL, small] Broken windows have no smashed sprite (S1-STONES).
17. [FEATURE, small] Thrown stones hard to land on critters (S2-THROW). Not a bug: hit radius
   is 10px (`main.gd:617`) and the stone moves ~8px a frame, so no tunnelling; the target is
   just small and moving. FIX: bigger critter hit radius for stones.
18. [FEATURE, small] Throw stones at your own truck or mower (damage), a tree or flower bed
   (some effect) (S2-THROW).
19. [VISUAL, moderate] [PARKED since 2026-09-24] Stripe shade blends with heading instead of snapping light/
   dark (S1-STRIPES). You'd keep the current look; only if cheap. Home: `lawn.gdshader`.
20. [FEATURE, small] Settings on the title screen (S1-ATTRACT). The pause menu's music/sound
   toggles already exist to reuse.

**Design calls (decide before building)**

21. [DESIGN, large] Escalation (S1-WINNABLE). Right now only patience can end a run, so there
   is no real pressure. Ideas: job types with harder layouts, mini golf (mow between holes,
   greens are off-limits, awkward trips to the truck), farm or botanical garden (lots of
   no-go beds, precision plus time), infestation jobs (don't squash any, or squash them all).
   The biggest note in the batch. Wants its own design session.
22. [DESIGN, moderate] Soft and hard impatience (S1-NAG). Soft: annoyed, leave now and lose
   the tip/bonus. Hard: told to leave, no pay, big rep hit, but you can stay and misbehave.
   More than one nag, plus a watch-glance on the face, without a visible countdown.
   Merges with 23.
23. [DESIGN, moderate] Fired shouldn't end the job abruptly (S1-FIRED): stay and cause
   mischief at a rep cost. Same shape as the hard cutoff in 22.
24. [DESIGN] Tone (S1-KO): a lawnmower wouldn't just knock someone out; the PG result
   disappoints. The design doc already says "a customer you have killed". Touches the MY
   CALLS item "the dog is never killed". DECIDED (to be felt out): no punches pulled. Not
   over the top by default, but deliberate absurdity (running the customer or the dog over
   again and again) gets properly gruesome, with punishment to match. A heinous act makes
   someone call the cops: a countdown (or sirens getting closer) starts. Reach the truck in
   time and you escape with a wanted level and a wrecked rep; get caught and the run is over.
25. [DESIGN, moderate] Rifle the pockets of a downed customer for the pay (S1-STONES):
   money now, WANTED and a terrible rep after.
26. [DESIGN, large] WANTED doesn't land and ARRESTED never fired (S1-WANTED, S1-FIRED).
   Your idea: a portly cop sometimes turns up and chases you while you mow, or chases you
   out after a firing. Direction agreed: the cop-call countdown in 24 is the main form.
27. [DESIGN, large] Shop and board as separate places (S1-BOARD): a walkable shop/showroom
   with the kit on shelves, random stock per run (small early), investing in the shop
   between runs, and a garage for upgrades, also upgraded between runs. This is the
   outside-the-run track the design doc defers. Not un-deferred; the underlying concern is
   real though: the between-jobs loop is seconds long and one-sided. What happens on the
   lawn is interesting, but there's no consequence after it and no journey from one job to
   the next; you pick from a short list you already know.
28. [FEATURE, moderate] The job board as newspaper classifieds (S1-BOARD): text ads, no
   picture or quote, rough lawn size, pay, and subtle hints ("careful applicants only").
29. [DESIGN, moderate-large] Pick up more than stones (S1-DOG): the dog wriggles free after
   a while, a hedgehog stuns you, a squirrel holds for a few seconds; hedgehog-proof gloves
   from the shop; throwing hedgehogs at things.
30b. [PARKED since 2026-09-24] A dark path: jobs for people who are themselves wanted. Mowing a mob boss's
   lawn, or mowing up a mob boss's enemies. Throwaway.
30. [PARKED since 2026-09-24] Stamina progression (S1-PUSH): level it up, better push mowers, drug or
   cybernetic enhancements.

**Answers and still owed**

31. [ANSWER] Pools: there are none. What you saw was the sound-player pool in `sfx.gd`.
   Ponds are real but only on medium and large lawns (rep 55 and 75); item 7 gets you there.
32. [ANSWER] The font: yes, hand-drawn for this game (`tools/make_font.py`, 5x7).
33. [OWED] Gamepad untested (S1-EXTRAS). Stone hits on every target not all seen (S1-STONES).
   Ponds not seen (S1-EXTRAS, S2-SPAWNS).
34. Signed off as fine: briefing, engine audio, tank trade-off, condition gauge, ride-on,
   push-mower winnability, board fit, hand-in send-back, hanging about, spawns avoiding the
   house/truck/trees.

PROPOSED ORDER: (1 to 7 and 9 done 2026-09-24), then 10, 12, 11, 13, then a
design session on 21 to 27 before any of them are built. Rationale: clear the bugs and give
you the cheat so the next playtest reaches ponds and large lawns; then the readability items
that cause unfair hits; escalation is the real open question and needs deciding, not building.
