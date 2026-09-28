# Notes (task list)

Triaged dev notes. Each item: tag, size, the note, root cause or home file, FIX sketch,
open QUESTION. Numbers are stable (done items are deleted, not renumbered). `/handoff`
sorts this file: done items go, decided design items move to
`../game-dev/Super Landscaper.md`, the rest wait for a grill or sit parked with a date.

Tags: BUG / FEATURE / VISUAL / DESIGN (needs a call before building) / PARKED.
BLOCKS = spoils the next playtest.

### Build (no design call needed)

47. [BUG, small] Board: pad (and arrows) left/right step up and down the mower list
   (S4-PAD-MENUS). Home: `board.gd` `_mower_row`. Waits on the walkable hub, which may
   replace this menu.
62b. [FEATURE, small] Leftover thoughts from ramming the car (not decided): a direct hit
   shoves the car a little; dents show on the sprite.
75b. [FEATURE, large] Venues, what's left after the manor and churchyard: the golf course (its
   own grill: 18 holes as separate jobs?); community service
   (a tier 2 arrest's lost slot becomes a forced unpaid job, needs a litter-pick or prison
   venue); the week-4 finale (open in the design doc).
79b. [FEATURE, moderate] Objects, later batches (design doc Mowers and Equipment): medium
   things shoved by heavy mowers (RigidBody2D: chairs, parasols, a sandbox rim), a sapling
   that snaps, sandbox, paddling pools, lawn darts, litter, croquet hoops, more critters and
   their interactions (cats, birds, rats, pond fish), fire.

### Notes 2026-09-27 (S8 check fallout, and an idea dump; what's left after session 9)

90. [PARKED since 2026-09-27] Character and company creation: pick the character's look,
   name the company, design a logo. QUESTION when unparked: where does it show (truck
   livery, board header, the ads)?
94. [DESIGN, moderate] A strimmer for edges: cut close to a bed without killing flowers.
   Equipment, design doc Mowers and Equipment. Now a packable item in the truck bed (106);
   its own grill: what counts as an edge. Fire (the Molotov) wants one too (79b).
96. [DESIGN, large] Optional subquests. Example: the pet rock escaped; bring any rock you find
   to the customer, who says whether it's theirs. Hand-ins go through "How am I doing?"
   (95, built in session 9).
100. [DESIGN, moderate] Weeds: the mower only half kills one, pulling it by hand pleases the
   customer. Maybe overgrown grass that takes more cutting (the dev is unsure of that one).

### Session 10 loose ends

112. [FEATURE, small] `tests/sim_balance.gd` only mows the default lawn: run it per plot shape
   and venue (terrace, semi, L, manor, churchyard) for each mower, so "which mower is best
   where" is measured, not hoped (the 91 grill's retune rule), and terrace patience is checked.

### Notes 2026-09-28 (S9 and S10 check fallout, and a notes dump)

113. [BUG, moderate, BLOCKS] The throw's ring lies. It sits where the stone would land on the
   ground if nothing were in the way (walker.gd `_draw_marker`, main.gd `_throw_reach`). Aim
   at an upstairs window and the ring's ground spot is behind the wall, so on screen it
   overlaps the window; but the stone crosses the wall's foot first, low, and hits the
   bottom of the house (`_building_hit`, `_up_the_front`). Same reason the roof felt
   unreachable (S9-HOUSE). FIX: step the flight exactly as FlyingStone does against
   `_stone_hit_test`, draw the whole arc as dots (each lifted by its height), and put the
   ring where it first hits (on the wall at that height, or the ground). One test: the
   predicted target equals the landed target for a few pitches at the house.
114. [BUG, small] Anything that leaves the plot vanishes the moment it crosses ("gone" frees
   it): stones and bodies over a fence, into the ha-ha, over the churchyard wall (S9-LOB,
   S9-BODY, S10-HAHA, S10-L). The dev: it should keep flying and lie out there. FIX: finish
   the flight past the edge and leave it lying beyond, drawn but out of reach. Decided
   (2026-09-28): never fetchable.
115. [BUG, small] One window smashes again and again, billed each time: `_building_hit`
   returns "window" for a broken pane. FIX: a broken pane is a hole, the stone goes in the
   house ("gone" indoors, a crash, no bill).
116. [VISUAL, small] The house front's slanted brown grid (the dev's partner spotted it):
   `tools/art_sprites.py` `facade()` darkens every pixel where (x + y) % 17 == 0, a
   diagonal. FIX: drop it; plain render with the courses, or brick. Regenerate house.png
   (not hand-edited).
117. [BUG, small] A stone on the house wall makes an odd noise: the thud plus `_react()`,
   which always plays the customer's voice, even when they're indoors and can't see you.
   FIX: indoors, a muffled shout and a "!" at the nearest window, so it reads as them.
118. [BUG, small] Picking up a knocked-out critter wakes it: `walker.carrying` keeps only the
   kind, and `_land` spawns it awake. FIX: carry its seconds left out cold and stun it again
   on landing. A bare-handed hedgehog still pricks you.
119. [BUG, moderate, BLOCKS] Critters spawn in walls and spin (the church's back wall, the L
   plot's corner, S10-L). `_spawn_spot` puts them 10 px outside the edge with no grace;
   where the outside is blocked (`_notch`, next door's corner or the church's wall run),
   every step is blocked, so they turn forever. The rustle draws leaves on brick because
   the pool falls back to any edge and the tell is always leafy. FIX: a short grace so they
   walk in (as squirrels out of trees do), never from inside `_notch`; the tell by edge
   kind (hedge: leaves; fence: a board rattles; wall: one pops over the top). The notch
   case is read in the code; the dev also saw it on plain side edges, not yet explained.
120. [FEATURE, moderate] The hose, simplified (the dev's list; I agree with all four): green;
   a hose reel by the tap you walk to and wind it in (first, regardless); links that
   can't fold back or kink sharply (an angle limit in the rope solve, drawn as a smooth
   curve); and only two grips, the reel and the far end. Also: it draws under things
   (`z_index = -1`), and the tap looks weak (bigger, a wall plate, the reel beside it).
121. [FEATURE, small] The mower's motor sounds the same anywhere in the level: mower.gd uses
   a plain AudioStreamPlayer. FIX: AudioStreamPlayer2D (falls off and pans from you on foot).
122. [FEATURE, small] Pad remap: A interact and get on, B get off and back out (the pause
   menu, cancelling a throw), X throw, Y look (today A=interact, B=throw, X=hop, Y=look).
   On the mower the stick only steers: forward/back off the stick, triggers drive (S9-PAD);
   W/S still drive on keys. Homes: project.godot, hud.gd (cancel), main.gd, mower.gd.
123. [DESIGN, moderate] Several things in reach at once (a gnome, the knocked-out customer and
   the hose) and you can't pick which: `_hint` takes the first by a fixed order. Options:
   the nearest thing in front of you wins, outlined; A first thing, X second; a button that
   cycles; a small pick list. Recommend nearest-in-front, outlined: no extra button.
124. [BUG, small] Fired after being paid: customer.gd `fire()` doesn't check `paid`, so mood
   keeps falling after payment, flips `fired`, and the "Fired: no pay" hint shows. main.gd
   skips the settlement (line 915), so no money moves; the message is wrong. FIX: `fire()`
   returns if paid (mischief after payment already goes on reputation).
125. [BUG, small] Returning the dog while the customer's indoors gives no mood:
   `on_dog_returned` needs them to see it. FIX: they get their dog back, so they know;
   count it, and they come to the door to say thanks (126).
126. [FEATURE, moderate] The door (S9-TALK): calling them out means interacting where they
   stood, and they appear only after the window closes. FIX: knock on the door itself, it
   opens, they're in the doorway, then the talk. A door-shut sound when they go back in
   off screen.
127. [FEATURE, small] The lead goes on by itself when you walk into the dog, so you can't
   throw the ball for it twice (S9-FETCH). FIX: putting the lead on is an interact; walking
   into it does nothing. Feeds 123.
128. [VISUAL, moderate] The summary screen: reputation in two places reads as two totals
   (S10-SUMMARY; replaces 111). FIX: two blocks, money (pay, tip, bills, fuel, total) and
   reputation (the job, after payment, what they noticed, total), one final figure each.
   Home: `summary.gd`.
129. [VISUAL, small] Records for things that can happen once a job (the hose cut, the dog
   walked home, the customer knocked out): a count and PERSONAL WORST are silly (S9-BOARD).
   FIX: the ticker names one-offs as events ("Cut the hose"); records only for countables.
130. [BUG, small] Buying on the board sends the cursor back to the top. Home: `board.gd`
   (remember the focus across the rebuild). Low value: the board is to be replaced.
131. [FEATURE, moderate] Knockouts, decided 2026-09-28. Today a moving mower always splats a
   critter (animal.gd `_on_body_entered`), stones by hand kill 20% (THROWN_KO 0.8), a
   thrown critter always lands alive, a mower-flung stone splats 75% (FLUNG_SPLAT).
   Changes: running one over can knock it out, likelier the smaller the mower (push
   mostly, petrol sometimes), the ride-on always splats; a knocked-out one is flung out
   from under the deck (knockback) and can't be run over for about a second (i-frames), so
   the knockout is seen and not undone on the same pass; a critter thrown hard into a wall
   (or anything solid) is knocked out. The S10-CARRY retest doesn't wait on this: after
   113 you can aim, and a hand-thrown stone kills one in five. Home: animal.gd, main.gd
   `_on_squashed`, `_stone_critter`, `_on_stone_landed`.
132. [VISUAL, large] The manor still reads McMansion: the dev wants stone, over-the-top
   grandeur (their references). The roof fades when you're behind it but the dev saw no
   lawn there, and its angled ends leave unreachable grass triangles in the corners. The
   code does lay a back lawn 260 px deep (main.gd MANOR_BACK) between the ha-ha and the
   ridge: screenshot first to see why it wasn't found (hidden, unreachable, or too thin).
   Decided (2026-09-28, my rec): keep the back lawn and the fade if it's really there and
   reachable, else make it so; square the roof's ends so no corner grass is cut off.
   Home: `art_sprites.py` mansion(), main.gd `_manor`. The redraw waits for 137.
133. [VISUAL, small] Topiary doesn't read (S10-TOPIARY), and the chunk that comes out looks
   like a bubble popping. Waits for 137.
134. [VISUAL, moderate] The ha-ha reads as a broken hedge (S10-HAHA). Decided (2026-09-28):
   try a redraw (the lawn edge dropping into a ditch, a low wall face beyond); if it still
   doesn't read, swap it for something familiar (railings). Also 114.
135. [DESIGN] Parked items answered (2026-09-28): stamina levelling dropped (30, a consumable
   kept as an idea); the animal dealer kept (37, grown in 136); the menace board stays
   parked (30b, the dev didn't recall it).
136. [DESIGN, large] Storylines that behaviour unlocks, unexplained at first. First: drive off
   with a critter in the truck, and a man turns up at the office wanting it and any more.
   It grows into requests (a stolen dog, for extra), and rare variants (an albino
   hedgehog). Critters by venue: peacocks and fancy things at the manor; country
   interlopers (pheasants, foxes, crows, ravens). Needs a grill; 79b's critter list joins it.
137. [DESIGN, large] An art pipeline, for this game and beyond: the dev redraws sprites in
   Aseprite. Wants: an inventory of every sprite (what, size, frame grid, where drawn) that
   imports into Aseprite as a same-scale reference; portraits and the character built from
   parts, so equipment (a hat, a backpack) doesn't mean redrawing eight facings. Needs a
   grill before any redraw (132, 133 wait on it).

PROPOSED ORDER: the bug batch first (113, 115, 118, 119, 124, 114), since 113 and 119 spoil
every playtest; then controls (122, 127, 123); 120 the hose; 128 and 129 the summary; 125 and
126 the door; a grill on 137 before any art (116 is safe now); then the old NEXT (108 to 110).

### Grilled 2026-09-27 (91: packing the truck, robot mowers, how each mower plays)

Decided in the design doc (Mowers and Equipment: packing the truck, each mower's feel).

106. [FEATURE, large] Packing the truck: a packing screen after taking a job (grids for the
   bed and the trailer, items as rotatable shapes, starting as you left it); the cab's push
   mower free; at the job, take kit out at the truck (the unused mower recalled); "Pack up
   and leave" brings everything home unless the police were called; the trailer a shop
   item, bundled with a ride-on if you haven't one; petrol cans as cargo. Homes: `game.gd`
   (owned kit, the packed layout), a new packing scene between `board.gd` and `main.gd`,
   `main.gd` (the truck, leaving). Question zero: GLoot (a Godot 4 inventory addon with a
   grid and rotation) from memory, not checked; likely too general for two small grids.
107. [FEATURE, moderate] The robot mower: set down, mows straight until it bumps something
   or the edge, turns a random way; turns back at bed edges; flings stones and squashes
   critters as yours. Picked up and carried back like a body. Waits on 106.
108. [FEATURE, small] Push mower: walk at about 60% speed, hold sprint (a free letter key, a
   pad trigger) for today's speed at a faster stamina drain. Unparks part of 30: better
   push mowers replace it in the cab.
109. [FEATURE, moderate] Petrol mower: a timed ripcord pull each job (a sweeping marker,
   release in the sweet spot, narrower the worse its condition); below about 40% a knock
   can stall it.
110. [FEATURE, moderate] Ride-on: four gears, instant shifts, each a top speed, higher gears
   a wider turning circle.

PROPOSED ORDER: play the S9 checks and the 101 to 105 builds; 108, 109, 110 (small, each
mower's feel, no packing needed); then 106 and 107; a grill on 96, then 94 and fire.

### Parked

27b. [PARKED since 2026-09-26] A drive between jobs as its own segment (traffic, the police
   at high heat).
21b. [PARKED since 2026-09-26] Job types for variety, not pressure: mini golf, farm or
   botanical garden, infestation jobs. Add when 12 jobs of one lawn kind feel samey.
30. [PARKED since 2026-09-24] Stamina: the dev drops levelling it up (2026-09-28). Kept as an
   idea: a consumable (an energy drink?) that takes a packing slot (106) for more stamina
   for a while.
30b. [PARKED since 2026-09-24] A dark path: the menace board (mafia dons, chasing enemies
   round a warehouse), a negative-reputation run, the loan shark as the way in.
37. [PARKED since 2026-09-24] Secret layer: the animal dealer. The dev keeps it (2026-09-28)
   and wants it grown into a storyline: see 136.
