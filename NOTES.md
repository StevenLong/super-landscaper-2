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
   S12-DRY: the ride-on still has too many advantages (a dry one now can't move, 175).

### Notes 2026-09-28b (S11 check fallout, and a notes dump; what's left after session 12)

Built in session 12 (unplayed, see CHECKS.txt): 141 to 146, 148 to 154, 156, 157, 161.

147. [DESIGN, moderate] Using the hose: what's it for, helpful or mischievous (S11-HOSE)?
   Seed ideas, none decided: watering beds (the gardener's mood), soaking the customer or
   the dog, sluicing critters out, putting out fire (79b, 94). Grill alongside 94 and 100.
   A cut-off piece isn't cut again (a `ponytail:` in `hose.gd`); decide with this.
155. [BUG, small] The job's opening briefing often shows in a weird spot; the dev wants it
   on the player or the customer (it's the customer talking). Not reproduced: in a
   1280x720 window on the default job it sits screen-centre (`hud.gd` `open()`,
   PRESET_CENTER), over the player. QUESTION: a screenshot next time it's off, and what
   size the window was.
158. [DESIGN, small] The summary's "All told" line will confuse (S11-SUMMARY); the dev has
   no better wording yet. Home: `summary.gd` ~89. Goes to the text pass (159) unless the
   presentation changes (say, standing before and after instead of a total).
159. [DESIGN, large] The text pass ("Mad Libs"): all in-game text rewritten in the dev's
   voice, with variants per meaning. The dev's format: run through it together, line by
   line; I show the scenario and the current text, the dev rewords it and gives variants.
   PREP done: `docs/TEXT.md` (from `tools/text_inventory.py`) lists every line by script
   and function. Open: where the variants live in code (inline arrays picked at random,
   like the personas' `lines`, is the lazy start). After the season prototype, which
   rewrites the board's text.
Also: S11-HEAP's target brackets stay for now; the dev is unsure of the look, to soak.
S11-SPAWN: nothing stuck seen since; the dev will say if it returns.

155 when it's caught on screen.

### Notes 2026-10-01 (S13 and S14 check fallout: LOAD 1 to 3 played, and the dev's notes)

Fixed during the play (session 15): the packing screen's crash on driving off (17dec2f);
fence and wall corners at next door's corner and the churchyard wall (dc5e08f).
Built after (session 15, unplayed): 178 to 188, 190 to 192, 195; and 189's robot as
decided (stripes, stops for critters, grinds stones). See CHECKS.txt once the handoff
writes them.

189. [DESIGN, moderate] Robot mowers, what's still open after the rework: tiers (cheap
   bouncers that run till they die, dear ones upgradeable or cleverer round critters),
   consumable vs permanent vs destroyable, speed and price. My calls in the rework (veto
   any): lanes along the way it's set down facing; it waits 2 s for something in its way,
   then gives that spot up and goes round; -10 condition a stone, broken for the rest of
   the job at 0, fresh next job; it crosses a drive to reach the rest of the lawn.
   S15-ROBOT (2026-10-02): $150 is pocket change after the first month, and cheap doesn't
   make it good: price it with the tiers (and 193's pace), once 200 and 201 make it useful.
193. [DESIGN, large] Pace and escalation (S14-PACE, the dev's biggest concern). One big job
   and you're set: the loan's paid, tens of thousands by month two, nothing to buy, no
   pressure. The week fills with the same big venue reshuffled: well paid, easy, samey.
   S14-RING ties in: the bars are 3 or 4 steps (0, 20, 55, 75), no gradual climb. The dev's
   lead, unsure: escalation inside the jobs (more critters and trouble per visit, maybe the
   longer you stay), not only outside them; or back toward the coin-op shape. Needs a grill
   before any retune of PAPER, REACH, the vig or pay.
194. [VISUAL, moderate] Fences and walls: more broken bits to come as the dev plays (the
   corner fix is dc5e08f). Collect screenshots here; side runs still leave a thin strip of
   outside grass between the fence and the lawn (judged fine, unconfirmed). Seen
   2026-10-02 (screenshots): the churchyard's left wall runs on past the side chapel into
   the open grass behind the church, a stub ending in nothing; it should stop at the
   chapel's back, as the right wall stops at the nave.
Also: S14-CAL, the board reads but will be redone when things split out (no item). S13-CORD
reads a bit better (no item). The rest of S13 and S14 passed.

PROPOSED ORDER: play what session 15 built; grill 193 (pace); 189's tiers after.

### Notes 2026-10-02 (S15 check fallout, LOAD 1 to 3 mostly played, and the dev's notes)

Fixed during the play (session 16): a robot crashed the job once the dog was handed home
(dcfaf99: the blocked check passed the freed dog through a typed lambda param).
Passed: S15-TRUCK, SAVEQUIT, PAY, OFFER; S15-PORTRAIT and PAPER pass bar 203 and 196.
Built in session 16: 196 (the shop's text wraps).

197. [FEATURE, small] The truck's reach is too wide; mark where you stand to refuel. Home:
   `main.gd` `at_truck()`, `$Truck/RefuelZone` (180 x 150 at (0, -80), set near line 255),
   which also opens the truck menu. FIX: shrink the zone and paint it faintly on the
   ground (z < 0) by the truck. Decided: one smaller zone for both refuel and the menu.
198. [DESIGN, small] Ride-on: start with two gears (today's bottom two, 0.3 and 0.5 of top
   speed), a third as an upgrade. Home: `mower.gd` GEARS, `game.gd` upgrades. Decided: two
   upgrades, the third gear (0.75) then the fourth (1.0), so today's top speed stays
   reachable. Prices are my call when built (veto then).
199. [DESIGN, moderate] Ride-on horn: scares critters near it; heavy use might annoy the
   customer (the dev's unsure of that part). Decided: build the scare now on H, the
   customer's annoyance left for later.
200. [BUG, moderate, BLOCKS] Robots mow grass that's already cut, so they add nothing. Home:
   `robot.gd` `plan()`, which plans every open cell whatever its state. FIX: plan only
   cells still uncut (lawn `_cell` == UNCUT), crossing cut ones by A* only to reach the
   next; when the route runs out, replan on what's still uncut (you and other robots cut
   too), and stop (green light) when none is left.
201. [BUG, moderate, BLOCKS] Robots deadlock: two parked facing each other, or facing
   something forever. Stopping for a gnome until you clear it is fine (the dev's call: it
   keeps you watching them); deadlock isn't. Home: `robot.gd` `_skip`. Guess
   (unverified): when its own cell is solid, or the detour's first step still sees the
   blocker ahead, `_skip` returns without a new route, and it waits on the same spot
   forever; two robots each wait for the other. FIX: reproduce two robots head on in
   test_robot, then fix `_skip` (give way by order, or route round the other robot).
   Seen: one stuck at a gnome (fine, by the call above), and two robots facing each other
   (the deadlock to fix).
202. [FEATURE, small] Ramming a robot with the ride-on (maybe any mower) damages both.
   Home: `mower.gd` collision loop (near line 248, it already finds the collider and knocks
   its own condition); `Robot.damage()`. Decided: any mower, by impact like other knocks.
203. [VISUAL, small] The face at the window reads as a translucent customer in front of
   the glass; the glass should be what's see-through (S15-PORTRAIT). Home: `house.gd`
   `_draw_house`, which draws the face over the opaque pane art then the pane again at
   PANE_OVER 0.45. FIX: a dark room inside the pane, the face over it, then only a faint
   sheen and the glazing bars on top; same for the walk past.
204. [VISUAL, small] The customer slides backwards to the door, still facing you
   (S15-DOOR). Home: `client.gd` `_draw`, which always turns `_toward` the watched mower.
   FIX: while walking, face the way they walk; watch you again once they stop.
205. [FEATURE, small] Packing: take an item straight off the truck, without carrying it
   back to the tray (S15-PACK, otherwise much better). Home: `pack.gd` `_unhandled_input`,
   `put_back`. Decided: the put-back key with empty hands on an item sends it home.

PROPOSED ORDER: the robot pass, 200, 201, 202 (the robot's
useless until it finds uncut grass and gets out of jams); the small pass, 204, 203, 205,
197; 198 and 199; then the grills (193, then 189's tiers and price).

### Grilled 2026-09-29 (160: the season calendar, regular clients)

Decided in the design doc (Direction, The Business, Season Prototype). The game is now a
small business across seasons, not a roguelite run. 162 to 166 (the season prototype) and
167 (the record) were built in session 14; the rest wait.

168. [DESIGN, large] Hired help: its own grill (wages, a helper's pace, off-screen jobs).
   Later layers on record in the doc: upfront pay and raises, evidence surfacing, the
   off-season events, selling up, the front page, referrals, wear and overheads.

### Grilled 2026-09-27 (91: packing the truck, robot mowers, how each mower plays)

Decided in the design doc (Mowers and Equipment: packing the truck, each mower's feel).

106 and 107 built in session 14.

### Parked

27b. [PARKED since 2026-09-26] A drive between jobs as its own segment (traffic, the police
   at high heat).
21b. [PARKED since 2026-09-26] Job types for variety, not pressure: mini golf, farm or
   botanical garden, infestation jobs. Add when 12 jobs of one lawn kind feel samey.
30b. [PARKED since 2026-09-24, the dev kept it 2026-09-28] A dark path: the menace board (mafia dons, chasing enemies
   round a warehouse), a negative-reputation run, the loan shark as the way in.
