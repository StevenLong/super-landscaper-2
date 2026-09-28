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

### Notes 2026-09-28 (S9 and S10 check fallout; what's left after session 11)

132. [VISUAL, large] The manor still reads McMansion: the dev wants stone and over-the-top
   grandeur (their references). Waits for the 137 grill (the dev may redraw it). Done in
   session 11: the square roof, the fade only behind a chimney; the back lawn was there.
133. [VISUAL, small] Topiary doesn't read (S10-TOPIARY): a cone, a ball on a stem and a
   peacock, and the chunk that comes out looks like a bubble popping. Waits for 137.
136. [DESIGN, large] Storylines that behaviour unlocks, unexplained at first. First: drive off
   with a critter in the truck, and a man turns up at the office wanting it and any more.
   It grows into requests (a stolen dog, for extra), and rare variants (an albino
   hedgehog). Critters by venue: peacocks and fancy things at the manor; country
   interlopers (pheasants, foxes, crows, ravens). The animal dealer (old 37) is this.
   Needs a grill; 79b's critter list joins it.
137. [DESIGN, large] An art pipeline, for this game and beyond: the dev redraws sprites in
   Aseprite, and wants parts (portraits, the character) so equipment (a hat, a backpack)
   doesn't mean redrawing eight facings. The inventory is built: docs/SPRITES.md (from
   tools/sprite_inventory.py), every sprite's size, grid and cell size. Options to grill:
   hand-drawn layered sheets per part with a per-facing draw order; voxel parts (the dev
   models in MagicaVoxel, the script renders); 3D in Blender rendered to pixels.
140. [DESIGN, moderate] Balance, from tests/sim_balance.gd per plot (session 11, bot times,
   a floor-ish measure, patience from the job): to 85% cut, default lawn push never (83%),
   petrol 262 s, ride-on 281 s against 165 s patience; terrace petrol 192 s, ride-on 184 s
   against 210 s; semi ride-on 244 s; L petrol 248 s; manor petrol 649 s against 810 s,
   push 47% in 12 min; churchyard ride-on only 44% (it can't fit between headstones).
   So: the ride-on isn't faster than petrol on open lawns (it turns wide), the push mower
   at walking pace is far off any patience, and the bot can't reach 85% within patience on
   the small plots with any mower. The dev's call (2026-09-28): play first and see if a
   person beats the bot; retune after (patience, push walk speed, the ride-on's turning).
   S11-GEARS (play): the ride-on feels worse to drive than before, maybe rightly (it was
   massively overpowered, every job fast and easy); top gear is a real risk, the wide turn
   offsets its strength on the straights. S11-PUSH: the walking pace felt right.

### Notes 2026-09-28b (S11 check fallout, and a notes dump)

141. [BUG, small, BLOCKS] A critter thrown into anything gets you wanted, even unseen and
   even for a customer who wants it hurt (S11-KOCARRY, and a squirrel into a fence). Cause:
   `main.gd` ~2041, a live critter into anything is tier +1 and +1 heat, unconditionally,
   and `_crime()` adds heat with or without a witness (only the police call needs one);
   both as the design doc says (The Run, the ladder). The dev's call: if the customer wants
   that critter harmed, how doesn't matter; it's only a crime into their car, through their
   window, or at them. FIX: skip the projectile tier and heat when the persona's weight for
   that kind is positive, unless the target is car, window, hole or customer. QUESTIONS:
   (a) should an unwitnessed crime add heat at all (today heat is your record, seen or not)?
   (b) does the dog count as off limits too (a squirrel at the dog)?
142. [FEATURE, small] Throwing a squirrel out of the yard, seen by a customer who hates
   squirrels, should earn mood. Home: the "gone" branch in `main.gd` ~1975 (a live critter
   over the boundary gets no reaction today); `customer.gd` beside `on_squash()`. FIX: an
   eviction seen scores the persona's weight for that kind times a share. QUESTION: does a
   nature lover mind seeing a hedgehog hurled over the fence (the sign follows the persona)?
   My lean: yes, at the knockout share (0.4).
143. [BUG, small] Picking up the same body again makes the customer react again (S11-CARRY).
   Cause: `main.gd` ~794 `_carried_into_view()`, `_carry_seen` clears when you put the body
   down, and a dropped body is respawned as a new Animal. FIX: a seen flag rides with the
   body (on the Animal, carried through `walker.carrying` and `_land`).
144. [BUG, small] A dead hedgehog doesn't prick bare hands (S11-CARRY). Cause: `main.gd`
   `_hold_critter()` returns early for "body_" kinds (not keys of CRITTERS). FIX: a
   hedgehog body pricks bare-handed like a live one.
145. [BUG, small] A body thrown into a live critter vanishes (S11-CARRY, dead hedgehog at a
   live one). Cause: `main.gd` "animal" hit branch: the live one is stoned, but only a live
   projectile lands (`if alive: _drop_bounced`). FIX: a body lands too.
146. [FEATURE, moderate] The hose cut mid-length: the far piece stays on the lawn and you
   can pick up its end and drag it clear (S11-HOSE). Today `hose.gd` `_cut_at()` drops
   everything past the cut. FIX: the cut-off links become a loose piece (no reel), grabbed
   by either end (my call).
147. [DESIGN, moderate] Using the hose: what's it for, helpful or mischievous (S11-HOSE)?
   Seed ideas, none decided: watering beds (the gardener's mood), soaking the customer or
   the dog, sluicing critters out, putting out fire (79b, 94). Grill alongside 94 and 100.
148. [VISUAL, small] A stone off a wall snaps to the ground (S11-HOUSE). Cause: `main.gd`
   `_drop_bounced()` lands it at once. FIX: it falls from the height it hit, with a
   little bounce back (FlyingStone already has z and vz).
149. [VISUAL, small] The ripcord needs a visible cord (S11-RIPCORD notes): a cord drawn out
   of the mower as you hold, snapping back on release, and PULL over the green. Home:
   `mower.gd` `_draw_cord()`.
150. [BUG, small] A mower out of fuel restarts by itself once refuelled. Cause: `mower.gd`
   ~301, running is just fuel > 0. FIX: running dry switches it off (petrol wants the
   cord, the ride-on its key).
151. [BUG, moderate, BLOCKS] A lag spike when the customer goes to a window, at least on the
   manor. Likely cause (not measured): `main.gd` `_show_cone()` casts 41 rays, and for
   every 12 px step out to 1400 px re-walks `_clear()` from the window, which re-filters
   every scenery node each call: quadratic per ray. FIX: march each ray once, filter the
   tall list once. Check: time `_show_cone()` on the manor before and after.
152. [VISUAL, small] The greyed portrait doesn't say "can't see you" (a watcher asked), and
   it snaps grey, flickering past tall things. Home: `face.gd` ~102, a binary tint. FIX:
   ease the tint over about 0.25 s; a label under the portrait while greyed, UNSEEN (my
   wording, open to the text pass, 159).
153. [BUG, small] Fired and police called by one act: both banners on top of each other.
   Cause: `hud.gd` `banner()` always draws mid-screen at the same height. FIX: a banner
   waits for the one showing to finish.
154. [BUG, small] "How am I doing?" still offered after you're paid or fired. `main.gd`
   `open_customer_menu()`. FIX: offered only while unsettled.
155. [BUG, small] The job's opening briefing often shows in a weird spot; the dev wants it
   on the player or the customer (it's the customer talking). Not reproduced: in a
   1280x720 window on the default job it sits screen-centre (`hud.gd` `open()`,
   PRESET_CENTER), over the player. QUESTION: a screenshot next time it's off, and what
   size the window was.
156. [VISUAL, small] The manor's chimney fade is pointless and distracting: you can barely
   get behind one, and the whole house fades (S11-MANOR). Chimneys stay walk-behind.
   Options (the dev's): no fade at all (let the player find it), or fade only the chimney
   you're behind. My lean: no fade (deletes `house.gd` `hides()` and its use).
157. [VISUAL, moderate] Corners and joins: the ha-ha's corners are rough, and round the L
   plot's notch some fences don't meet or stick out (S11-HAHA). Home: `main.gd` borders
   (~600 to 730). FIX: screenshot every plot shape's corners, then fix the joins.
158. [DESIGN, small] The summary's "All told" line will confuse (S11-SUMMARY); the dev has
   no better wording yet. Home: `summary.gd` ~89. Goes to the text pass (159) unless the
   presentation changes (say, standing before and after instead of a total).
159. [DESIGN, large] The Mad Libs session: rewrite all in-game text together in the dev's
   voice, with several variants per meaning. PREP (buildable first): pull every
   player-facing line into one text file, each meaning a list of variants picked at
   random, so the session is editing one file. QUESTION: what format the dev wants to edit
   in (plain text, a spreadsheet CSV, a markdown table).
160. [DESIGN, large] A season calendar of regular clients instead of one-off ads: customers
   book you monthly, you return to the same garden, the relationship matters, and firing
   costs a steady income; the ads become a way to find contacts or fill gaps. Touches the
   board, the week and the loan shark's cadence, what a garden remembers between visits,
   and 106. Needs a /grill before more board work (47, the hub).
161. [BUG, small] 21 GDScript warnings in the editor: shadowing (`game.gd` params `job` and
   `key` shadow the `job()` and `key()` functions; `board.gd` `size`; `flowerbed.gd` `shape`;
   `flying_stone.gd` `z`, `vz`, `velocity`), confusable locals (`beyond.gd` `x`, `main.gd`
   `t` and `e`), an unused param (`beyond.gd` `_lot(up)`). FIX: rename. QUESTION: add a
   run_all step that fails on any GDScript warning, so they don't pile up again? My lean: yes.

Also: S11-HEAP's target brackets stay for now; the dev is unsure of the look, to soak.
S11-SPAWN: nothing stuck seen since; the dev will say if it returns.

PROPOSED ORDER: 151 (the lag spoils the manor), then the small bug batch 141 (after its
questions), 143, 144, 145, 150, 153, 154, 161; then 152, 142, 148, 149, 156, 146, 157; 155
when it's caught on screen. Grill 160 before any more board work; 159's prep after 160,
since a calendar rewrites much of the board's text.

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
   Open parameters (my calls unless the dev says): the bed's and the trailer's grid sizes,
   each item's shape (petrol mower, robot mower, petrol can), how the screen is driven on a
   pad (move, rotate, drop).
107. [FEATURE, moderate] The robot mower: set down, mows straight until it bumps something
   or the edge, turns a random way; turns back at bed edges; flings stones and squashes
   critters as yours. Picked up and carried back like a body. Waits on 106.

PROPOSED ORDER: play the session 11 checks first (106 changes how mowers are chosen,
on top of this session's mower feel); then 106 and 107.

### Parked

27b. [PARKED since 2026-09-26] A drive between jobs as its own segment (traffic, the police
   at high heat).
21b. [PARKED since 2026-09-26] Job types for variety, not pressure: mini golf, farm or
   botanical garden, infestation jobs. Add when 12 jobs of one lawn kind feel samey.
30b. [PARKED since 2026-09-24, the dev kept it 2026-09-28] A dark path: the menace board (mafia dons, chasing enemies
   round a warehouse), a negative-reputation run, the loan shark as the way in.
