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

44. [DESIGN, large] Perspective and scale: the visual design session, NEXT (S4-VIEW).
   Decided and in the design doc: trees go top-down, the house keeps its face. Open: the
   dev finds the perspective and the scale all over the place (the house is a small
   rectangle, the drive is miles long). FIX: mock up the same garden in a few matching
   styles, with the house/drive/lawn scale corrected, and the dev picks: (a) pure
   top-down, the house's face a thin strip; (b) a shallow tilt on tall things only (house,
   garage, fences, truck); (c) full 3/4 like A Link to the Past / Stardew. Proposed: (b),
   since it keeps the mower and lawn art and still shows the windows. The tree redraw and
   54, 55, 56 wait on it. The dev may take over some pixel art later (not decided).

### Notes 2026-09-25b (session 4 play checks)

**Build (no design call needed)**

47. [BUG, small] Board: pad (and arrows) left/right step up and down the mower list
   (S4-PAD-MENUS). Home: `board.gd` `_mower_row`, Godot's default focus neighbours. The dev
   says it may not need a fix if 27's shop replaces this menu.

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

PROPOSED ORDER: the visual session (44), which unblocks the tree redraw and 54-56; the grill
queue (21...) is unchanged; 47 waits on 27.
