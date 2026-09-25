# Notes (task list)

Triaged dev notes. Each item: tag, size, the note, root cause or home file, FIX sketch,
open QUESTION. Numbers are stable (done items are deleted, not renumbered). `/handoff`
sorts this file: done items go, decided design items move to
`../game-dev/Super Landscaper.md`, the rest wait for a grill or sit parked with a date.

Tags: BUG / FEATURE / VISUAL / DESIGN (needs a call before building) / PARKED.
BLOCKS = spoils the next playtest.

### From the 2026-09-24 play checks

**Build (no design call needed)**

46. [FEATURE, moderate] More layout variety (after 12/39's attached garage, left or right):
   a detached garage, the drive's shape, the customer's car in the drive (one more thing
   to hit), houses across the road. Not formulaic, but not drastically different.

**Needs a grill (design calls, queued for one session)**

21. [DESIGN, large] Escalation (S1-WINNABLE). Right now only patience can end a run, so there
   is no real pressure. Ideas: job types with harder layouts, mini golf (mow between holes,
   greens are off-limits, awkward trips to the truck), farm or botanical garden (lots of
   no-go beds, precision plus time), infestation jobs (don't squash any, or squash them all).
   The biggest open question.
22. [DESIGN, moderate] Soft and hard impatience (S1-NAG). Soft: annoyed, leave now and lose
   the tip/bonus. Hard: told to leave, no pay, big rep hit, but you can stay and misbehave
   (same shape as being fired, now built). More than one nag, plus a watch-glance on the
   face, without a visible countdown. The dev is still finding the balance.
25. [DESIGN, moderate] Rifle the pockets of a downed customer for the pay (S1-STONES):
   money now, WANTED and a terrible rep after.
26. [DESIGN, moderate] What the wanted level does between jobs (S1-WANTED). The in-job cop
   call is decided (design doc, The Run); today's 12%-per-level arrest roll at job start
   never fired in play and may not fit.
27. [DESIGN, large] The between-jobs loop is seconds long and one-sided: no consequence after
   a job and no journey from one to the next; you pick from a short list you already know.
   Ideas (S1-BOARD): a walkable shop/showroom with kit on shelves, random stock per run
   (small early), investing in the shop between runs, a garage for upgrades. That part is
   the outside-the-run track the design doc defers.
29. [DESIGN, moderate-large] Pick up more than stones (S1-DOG): the dog wriggles free after
   a while, a hedgehog stuns you, a squirrel holds for a few seconds; hedgehog-proof gloves
   from the shop; throwing hedgehogs at things.
38. [DESIGN, large] Punishment needs a witness. Some customers stand on the patio watching the
   whole job, some go inside and don't care, some watch from the windows. What nobody saw
   doesn't cost you, but the aftermath can (a lawn left a bloody mess gets opinions).
   Ideation. Note the design doc currently says unseen mischief is always discovered when
   you leave; this would change that.
40. [DESIGN, large] High-end jobs: a mansion with a loop driveway and a golf course out back.
   Golf balls act like stones; sinking one in a hole is a secret achievement. Goes with 21.

**Parked**

19. [PARKED since 2026-09-24] Stripe shade blends with heading instead of snapping light/
   dark (S1-STRIPES). You'd keep the current look; only if cheap. Home: `lawn.gdshader`.
30. [PARKED since 2026-09-24] Stamina progression (S1-PUSH): level it up, better push mowers,
   drug or cybernetic enhancements.
30b. [PARKED since 2026-09-24] A dark path: jobs for people who are themselves wanted.
   Mowing a mob boss's lawn, or mowing up a mob boss's enemies. Throwaway.
37. [PARKED since 2026-09-24] Secret layer: collect enough hedgehogs or squirrels and a
   black-market hedgehog dealer turns up. Needs 29 first.

PROPOSED ORDER: a grill session on 21, 22, 25, 26, 27, 29, 38, 40 (eight waiting, and 21 is
the biggest open question); 46 is buildable any time.

### Notes 2026-09-25 (session 3 play checks, answered in session 4's S4-VIEW / S4-AUDIO)

44. [DESIGN, large] Perspective and scale: a visual design session (S4-VIEW, S4-TREES).
   The 3/4 trees are vetoed: the flat trunk reads as a cardboard cutout. Decided: trees go
   back to top-down, a round canopy that fades when you're under or near it, and a round
   trunk that is the obvious solid mass. The house keeps showing its face (you need to see
   the windows), but maybe a shallower tilt. Beyond that the dev finds the perspective and
   the scale all over the place: the house is a small rectangle, the drive is miles long.
   FIX: a session where the same garden is mocked up in a few matching styles (pure
   top-down; a shallow oblique on tall things only; full 3/4 like A Link to the Past /
   Stardew) with the house/drive/lawn scale corrected, and the dev picks. 54, 55, 56 and
   the tree redraw all redraw art, so they wait on this. The dev may take over some pixel
   art later (not decided).
45. [DESIGN, large] Audio (S4-AUDIO). Decided: the dev will do a music/sound session in
   Ableton later; until then `tools/make_audio.py` output stays as placeholders. All the
   music tracks are repetitive earaches; menu blips are better now. Two concrete bugs came
   out of the listen-through and are filed as 48 and 49.

### Notes 2026-09-25b (session 4 play checks)

**Build (no design call needed)**

47. [BUG, small] Board: pad (and arrows) left/right step up and down the mower list
   (S4-PAD-MENUS). Home: `board.gd` `_mower_row`, Godot's default focus neighbours. The dev
   says it may not need a fix if 27's shop replaces this menu.
48. [BUG, small] An audio pop the moment a job starts (S4-AUDIO). Not diagnosed. Suspect:
   `mower.gd:76` starts the engine loop at 0 dB in `_apply_visual`, before `_update_sound`
   sets its volume, so the first frames jump. Board sounds can't be the culprit (the Sfx
   pool is an autoload and survives the scene change). FIX: start the engine at -80 dB and
   let `_update_sound` bring it up; confirm by recording the first second of a job.
49. [BUG, small] The customer screams on every flower flattened, back to back (S4-AUDIO).
   `main.gd:1033` `_on_trampled` calls `_react()` for each fresh flower, and `_react` plays
   the voice every time. FIX: a voice/line cooldown (~1.5 s, the reaction window) in
   `_react`; the rep still counts every flower.
50. [FEATURE, moderate] Controller prompts (S4-SPLASH aside). Hints show keyboard keys only
   (`main.gd:432-448` hardcode [E]/[Q]). FIX: Game remembers the last input device; hints
   swap to pad glyphs (small pixel A/B/X/Y). QUESTION (defaulted): Xbox layout.
51. [BUG, small] A stone landing at the pond's edge: the splash rings (up to ~26 px across)
   will draw over the ground. Predicted from `main.gd:844` `_splash`, not seen in play:
   `_in_pond` tests only the landing point. FIX: cap the ring size by the distance to the
   pond's edge.
52. [VISUAL, small] The whole tree shakes when a stone hits it (S4-THROWS). Today only a
   loose leaf tuft rustles at the hit point (`main.gd` `_rustle`); `tree.gd` never moves.
   FIX: a short shake on the tree's canopy; reuse it when a squirrel's tell is in a tree.
53. [VISUAL, small] Talking (S4-TALKING): a slower reveal (`hud.gd:58`, 0.12 s per word) and
   a mouth frame you can actually see moving (`tools/make_faces.py`'s second frame).

**Needs the visual session (44) or a design call**

54. [VISUAL, moderate] Hedges need a rework now they sit off the world's edge (S4-TELLS):
   they read as border strips that lost their border.
55. [FEATURE, large] The plots around the garden are a green void (S4-STREET), a missed
   chance for variety: forest, a park, a playground, other houses, an abandoned empty lot,
   varying per job. Goes with 46.
56. [DESIGN, moderate] More obstacles and trees (S4-TREES): much smaller and larger trees,
   bushes out in the lawn, lawn games, litter, traffic cones, garden gnomes, plastic pink
   flamingos (the "lawn pelicans"). Each needs a call: solid, mowable, throwable, a rep
   cost if broken?

PROPOSED ORDER: 49, 48, 51, 52, 53 as one small build (art-independent, and 49 is the
painful one); 50 next; then the visual session (44), which unblocks 54-56; 45 waits on the
dev's Ableton time; the grill queue (21...) is unchanged; 47 waits on 27.
