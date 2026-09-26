# Notes (task list)

Triaged dev notes. Each item: tag, size, the note, root cause or home file, FIX sketch,
open QUESTION. Numbers are stable (done items are deleted, not renumbered). `/handoff`
sorts this file: done items go, decided design items move to
`../game-dev/Super Landscaper.md`, the rest wait for a grill or sit parked with a date.

Tags: BUG / FEATURE / VISUAL / DESIGN (needs a call before building) / PARKED.
BLOCKS = spoils the next playtest.

### From the 2026-09-24 play checks

**Build (no design call needed)**

46. [FEATURE, small] Layout variety, what's left: the drive's shape (a bend or a wider
   mouth needs non-rectangle drives). Detached garages, the car and houses across the road
   shipped in S6.

**Needs a grill (design calls, queued for one session)**

**Parked**

27b. [PARKED since 2026-09-26] A drive between jobs as its own segment (traffic, the police
   at high heat).

21b. [PARKED since 2026-09-26] Job types for variety, not pressure (21's leftovers, the
   season now supplies the pressure): mini golf (mow between holes, greens off-limits,
   awkward trips to the truck), farm or botanical garden (lots of no-go beds), infestation
   jobs (don't squash any, or squash them all). Add when 12 jobs of one lawn kind feel samey.
19. [PARKED since 2026-09-24] Stripe shade blends with heading instead of snapping light/
   dark (S1-STRIPES). You'd keep the current look; only if cheap. Home: `lawn.gdshader`.
30. [PARKED since 2026-09-24] Stamina progression (S1-PUSH): level it up, better push mowers,
   drug or cybernetic enhancements.
30b. [PARKED since 2026-09-24] A dark path: jobs for people who are themselves wanted.
   Mowing a mob boss's lawn, or mowing up a mob boss's enemies. Grown up 2026-09-26: a
   menace gets a seedy board (mafia dons, chasing enemies round a warehouse), a
   negative-reputation run, with the loan shark as the way in (design doc, The Run).
37. [PARKED since 2026-09-24] Secret layer: collect enough hedgehogs or squirrels and a
   black-market hedgehog dealer turns up. Needs 29 first.

PROPOSED ORDER: grilled 2026-09-26 (see 72 to 81); 46 and 55's leftovers are buildable any
time.

### Notes 2026-09-25b (session 4 play checks)

**Build (no design call needed)**

47. [BUG, small] Board: pad (and arrows) left/right step up and down the mower list
   (S4-PAD-MENUS). Home: `board.gd` `_mower_row`, Godot's default focus neighbours. The dev
   says it may not need a fix if 27's shop replaces this menu.

**Leftovers and a design call**

55. [FEATURE, small] The world past the garden, what's left: a park or playground as a
   neighbour type, and something nicer than rectangles of earth in the empty lot. The rough
   version (neighbours, woods, lot, treeline, houses across the road) shipped in S6.
(56 and 65 grilled 2026-09-26 into 79.)

PROPOSED ORDER: the dev lives with the voxel look first; then the grill (56 joins it); 47
waits on 27.
### Notes 2026-09-26 (session 6 play checks)

**Bugs (build, no call needed)**

72. [FEATURE, moderate] The season (decided in the 2026-09-26 grill, design doc The Run):
   4 weeks x 3 jobs, the loan shark's payment after each week ($120, $250, $450, $750 as
   one tunable table), the heavies repossess kit at a resale rate on a miss, selling kit in
   the shop, the dregs board at zero rep replacing "File for bankruptcy", a season-end win
   screen. Home: `game.gd` (new_run, offer_count, record_result), `board.gd`.
73. [FEATURE, small] Impatience signals (22, decided 2026-09-26): the watch glance on the
   face at 75% and 90% of patience, a sigh with the first nag when the tip goes, nags in
   three escalating steps as mood falls. Home: `customer.gd` `tick`, `face.gd`.
74. [FEATURE, moderate] Heat and the police (26, decided 2026-09-26, design doc The Run):
   the crime ladder (tiers 0 to 3), heat only from crimes, the in-job police call with a
   countdown shortened by heat, proportional punishment (fines, a lost job slot), heat
   cooling a level per week paid; delete the job-start arrest roll (`game.gd`
   `arrested_on_arrival`). Tier 3 waits until a customer can actually be killed. Needs 72
   for job slots and weeks. The police countdown is visible, with sirens.
76. [FEATURE, small] Rifle a knocked-out customer's pockets (25, decided 2026-09-26): hold
   to rifle, cash trickles out a few dollars a second from a wallet of 20 to 60% of the pay;
   +1 heat, the police always called, the worst rep hit. Needs 74's countdown.
77. [FEATURE, moderate] Seen versus evidence (38, decided 2026-09-26, design doc The
   Customer): the customer moves between patio, inside and a window by persona; unseen acts
   judged by their evidence when they come out; noise brings them out; the portrait greys
   out or shows a window pane. Home: `customer.gd`, `client.gd`, `face.gd`, `main.gd`.
78. [FEATURE, small] The payday scene (27, decided 2026-09-26): at each week's end the
   shark's man takes the payment or repossesses kit in front of you. Part of 72. The
   walkable hub is the destination (design doc Outside the Run), after its own grill.
79. [FEATURE, moderate] Objects by size (56 and 65, decided 2026-09-26, design doc Mowers
   and Equipment): small (carry, throw, mow with a consequence), medium (shoved by heavy
   enough mowers, RigidBody2D), big (solid). The petrol can becomes throwable; mowed, it
   spills and browns the lawn. First batch: gnome, flamingo, cone, decorative rocks, hose
   (the spill, water), tennis ball with fetch. Later: sandbox, paddling pool, more critters
   and their interactions, fish, fire. Lawn darts on the throwable list.
80. [FEATURE, small] Charged throws, step 1 (64, decided 2026-09-26): hold to wind up,
   locked in place, left/right rotate the aim (~90 deg/s), power fills to max, a landing
   marker, release throws, hop cancels; today's flat flight. Home: `main.gd` throw input,
   `walker.gd`. Step 2 (moderate): up/down set the vertical angle, flights become arcs with
   a shadow and every target gets a height.
81. [FEATURE, moderate] Critters in hand (29, decided 2026-09-26, design doc Mowers and
   Equipment): carry and throw the dog (wriggles free ~5 s), hedgehog (stuns bare-handed,
   gloves from the shop; thrown, a spiky stone), squirrel (bites free in a few seconds);
   animals as projectiles tier the crime up (+1 above the worse of target and animal, cap
   2, +1 heat). The crime half needs 74.

PROPOSED ORDER (2026-09-26 grill): 58 first (blocks), 59 to 61 as a bug batch, then 80
(charged throws, small, fixes a play complaint), then 72 with 78 (the season, the spine),
73, 74, 76, 77, 79, 81, 75 (venues, large) last. 62 rides with 74.
75. [FEATURE, large] Venues by reputation band (40, decided 2026-09-26, design doc Levels):
   first the mansion (top band: a big house, loop drive, expensive breakables, its own
   persona) and the graveyard (bottom band: gravestones as solid obstacles, flowers on
   graves, the vicar). Then the golf course. Community service (forced unpaid job after a
   tier 2 arrest, repairs rep) once a litter-pick or prison venue exists; needs 74.

58. [BUG, small, BLOCKS] On foot, the sprite flips upside down and is hard to face where you
   want (S6-FOOT). Diagnosed from code, not reproduced: `walker.gd` sets `rotation` every
   frame but only redraws every 9 px of stride (the `queue_redraw()` inside `_draw_held` runs
   during `_draw`, where Godot ignores it). Between redraws the cached drawing, counter-
   rotated for the old heading, turns with the new one; walk west and it's upside down.
   FIX: redraw whenever the heading changes (or every frame), drop the dead call.
59. [BUG, small] A knocked-out customer keeps turning to face you (S6-CUSTOMER). Home:
   `client.gd` `_draw` picks `toward` from `watch` even when `_out`. FIX: freeze the facing
   at knockout.
60. [BUG, small] The car's hitbox runs too far south of its sprite (S6-CAR). Root cause: the
   car model is 110 long, but ground depth projects at G = 0.6 (`tools/voxel.py`), so its
   footprint is 66 px deep on screen while `CAR_SIZE` (`main.gd`) is 52 x 110. FIX: size the
   collision from the projected footprint. Check the other voxel things' shapes for the same
   slip.
61. [FEATURE, small] A stone that hits a wall just vanishes (S6-WINDOW); it should bounce off
   and land. Home: `main.gd` `_on_stone_landed`: only "tree" and "mower" drop the stone. FIX:
   the same drop for wall, car, truck, customer and dog, bounced back off the surface.

**Needs a call (small ones can be settled in the grill's first minutes)**

62. [FEATURE, small] Ramming the car with the mower has no reaction (S6-CAR). The mower takes
   bump damage (`mower.gd` `_check_impacts`) but nothing else knows. DECIDED 2026-09-26: over
   the bump threshold it dents like a stone, $40 and "My CAR!"; a harder hit (a ride-on at
   full speed) costs more. Thoughts, not yet decided: a direct hit shoves the car a little,
   and dents show on the sprite.
63. [QUESTION, small] The 8 facings feel a touch late and point off-course (S6-FACINGS). Not
   a timing bug: `Facing.of` switches at the exact midpoint every frame. Likely the
   unconscious thing: the voxel sheets squash depth by 0.6, so a diagonal sprite points
   about 31 deg while you travel 45 deg, and flat-ish turns switch late relative to what the
   sprite shows. Options: (a) leave it and let it soak; (b) pick the row from the projected
   angle, which makes diagonals match but widens the N/S sectors (more "facing north while
   not going north"); (c) 16 facings, twice the sheet rows, halves both errors. Snapping the
   heading itself to 8 ways: agreed, no (it would fight mowing lines). DECIDED 2026-09-26:
   (a), leave it and let it soak.

66. [VISUAL, moderate] The pond and flower beds don't read as 3/4. Both are still drawn flat.
   FIX sketch: rim stones with a visible front face and a darker inner bank on the pond;
   flowers standing up in the beds. Both read as flat drawings on the ground. Fake a bit of
   perspective; no planter box (it would stop you driving over the bed). Change the beds from
   solid rectangles to more usual flower-bed shapes (curved borders, kidney shapes).
67. [VISUAL, small] Trees still read as cardboard cutouts: the trunk meets the ground in a
   flat line. FIX: a rounded, elliptical base (and a ground shadow ellipse). Home:
   `tree.gd`.
68. [VISUAL, small] Fences: the road-side run doesn't join the side runs well and differs in
   style; the back fence stops instead of running on behind the house; next door's fences
   sometimes overlap, poke into a neighbour's drive, or run past a corner and stop. Home:
   `main.gd` fences, `beyond.gd`. The back fence vanishes once it reaches the house: it
   should run the garden's full width, its top showing above the house sprite where it
   pokes out.
69. [VISUAL, small] The chimney looks wrong and in the wrong place. Home:
   `tools/art_sprites.py` `house()` (it sits behind the ridge at x 332). Right now it reads
   as a flat thing hanging off the back. Either placement is fine: up a gable end, or
   through the roof near the ridge; it just needs to read as 3/4.
70. [VISUAL, moderate] Garages are too shallow to hold the car in the drive. Deepening
   `house.gd` GARAGE_* and `art_sprites.py` `garage()` eats lawn (rerun sim_balance).
   Ties to S6-DEPTH: the strip behind a garage is never covered by it, which matches the
   "can't see it, can't go there" rule. DECIDED 2026-09-26: keep the rule (no fading
   garage roof); just deepen the garage.
71. [VISUAL, moderate] Next door and past the fences can still feel like a void: sparse trees
   on flat, featureless grass. FIX sketch: ground texture and variation (mow stripes, darker
   patches, paths, flower borders) on neighbour lots. Pairs with 55.

PROPOSED ORDER: 58 first (blocks the next playtest, one line), then 59 to 61 as one bug
batch; the grill takes 62 to 65 alongside 21, 22, 25, 26, 27, 29, 38, 40 and 56; 66 to 71
are a 3/4 art pass once the questions are answered.
