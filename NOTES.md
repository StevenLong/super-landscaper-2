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
   like the personas' `lines`, is the lazy start). Likely after 160, which rewrites the
   board's text.
160. Grilled 2026-09-29: see "Grilled 2026-09-29" below (162 to 168).

Also: S11-HEAP's target brackets stay for now; the dev is unsure of the look, to soak.
S11-SPAWN: nothing stuck seen since; the dev will say if it returns.

ORDER (revised after the 160 grill, confirmed 2026-09-29): play the S12 checks;
the season prototype (162 to 166); then the text pass (159, with 158), since the
prototype rewrites the board's and the summary's text; 155 when it's caught on screen.

### Notes 2026-09-29 (S12 check fallout, and two notes)

Passed as written: S12-UNSEEN, WALLDROP, DONE, LAG, CHIMNEY, HAHA. S12-PORTRAIT reads clear
to the dev (their partner to see it; they'll say if it objects). S12-BANNERS not
reproduced (the dev will say if it recurs). S12-LFENCE: some better, a screenshot next
time. S12-BODY: an unconscious hedgehog still pricks bare hands, as meant. S12-DRY passed
(dies, pushable, restart), with 175 and a 140 note from it.

169. [BUG, small] A critter thrown into the house wall angers a hater ("Careful!", -5), and
   one slammed into a wall or hedge and knocked out moves nobody (S12-HATER). Root: the
   "wall" case calls `customer.on_stone("wall")` whatever was thrown (`main.gd` ~2029,
   `customer.gd` 233); the slam knockout in `_drop_bounced` never tells the customer.
   FIX (the dev's call): no wall complaint when the thrown thing is a critter they want
   hurt; a slam knockout seen moves mood by KO_SHARE via `on_squash`, like a stoned one.
   The window, car and dog stay crimes.
170. [BUG, small] A stone that hits a critter vanishes (S12-BODY). Root: the "animal" case
   drops back only a live critter or a body (`main.gd` ~2053, `if alive or body_`). FIX:
   the stone drops beside it too.
171. [FEATURE, small] Killing takes two hits (the dev's call; they struggled to kill at
   all: a thrown stone knocks out 80%, `THROWN_KO`, and a slam only ever knocks out). A
   stone, a slam or a thrown critter on a critter already out cold kills it. Home:
   `_stone_critter`, `_drop_bounced`, the critter-on-critter hit. One throw stays mostly a
   knockout.
172. [BUG, moderate] Throws bounce off hedges, so nothing gets evicted over one
   (S12-EVICT, the hedge half of S12-HATER: it bounced back onto the lawn). Root: crossing
   the boundary below `BORDER_UP` (29 px) bounces (`main.gd` 1953). Not known: whether a
   full throw can clear 29 px at the boundary from any distance. FIX: first a test that
   traces the highest throw; if it can't clear, the arc or the hedge's clearance changes.
173. [BUG, small] The hose dragged onto the porch (the paving round the house) disappears
   under it (S12-HOSE, the rest works). Z order: `hose.gd` against the house's paving.
   Mentioned before but never filed.
174. [VISUAL, moderate] The ripcord, again (S12-CORD: the cord drawn out of the engine reads
   odd, nothing attached). The dev's picture: a hand and the cord over the meter bar; on
   release it pulls; in the sweet spot it starts, a miss as now. Home: `mower.gd` ~207.
175. [FEATURE, small] An empty ride-on can't move at all: fetch the can (the dev's call,
   S12-DRY). The petrol mower stays pushable. Home: `game.gd` MOWERS rideon
   `empty_speed_scale` 0.2 to 0. S12-DRY also: the ride-on has too many advantages (140).
176. [FEATURE, small] Pockets after payment hold less (the dev's note, then call): knocked
   out once they've paid you, the wallet is 0 to 20% of the pay (small change); before,
   20 to 60% as now. Home: `_knock_out`, `main.gd` 2223, `settled`.
177. [FEATURE, small] Fuel by work (the dev's note, then call): an engine running with the
   mower still burns about 30%; moving, the full rate. Home: `mower.gd` 310.

ORDER (proposed): the fallout first, before the season prototype (small, in code the
prototype doesn't touch, and the next check load plays better for it): 170, 169, 171, 172
(one pass over the throw code), 173, 175, 176, 177, then 174; then 162 to 166.

### Grilled 2026-09-29 (160: the season calendar, regular clients)

Decided in the design doc (Direction, The Business, Season Prototype). The game is now a
small business across seasons, not a roguelite run. 162 to 166 are the season prototype;
the rest wait.

162. [FEATURE, large] The calendar and the weekly payday, replacing 4 weeks of 3 jobs:
   months April to September (start month a knob), one job a day, empty days skip; each
   week the vig on a principal plus a living cost, overpayment cutting the principal.
   Homes: `game.gd` (`PAYMENTS`, `JOBS_PER_WEEK`, `week`, `job_of_week`, `payday_due`,
   `settle_payday`), `board.gd` (the payday scene). Repossession stays as is.
163. [FEATURE, moderate] The weekly paper: at payday, book the coming week's ads into free
   days; reputation sets how many and how good (`offer_count`, `make_job`). Waits on 162.
164. [FEATURE, large] Regulars: after a good classifieds job, a hidden chance (visit and
   persona) of an offer right after the results, with accept / decline / haggle; carried
   mood as each visit's starting mood; cadence-only requests placed on free days, clashes
   shifted a day; drop a regular; cancel below a mood floor; no tips for regulars. The
   garden kept by its seed, the dead staying dead, one token drift between visits.
   Homes: `game.gd`, `summary.gd`, `customer.gd` (starting mood), `main.gd`.
165. [FEATURE, moderate] Ironman autosave between days, one per business; a job started
   and not finished loads as the blackout (client lost, job failed, a reputation hit).
   New: a save file (the run state is all in `game.gd` today).
166. [FEATURE, small] A stub winter screen at the season's end (living costs out, who's
   back), then the next April.
167. [FEATURE, large, after the prototype] The record replacing heat: convictions weighted
   by tier, summons after an escape, court with a bought lawyer's roll, sentences as
   calendar days (community service on the next free day, jail at once), prison as an
   ending by accumulation. Homes: `game.gd` (`HEAT`, `HIGH_HEAT`, `police_time`, `fine`,
   the cooling in `settle_payday`), `main.gd` (~1737, the call), `board.gd` (WANTED).
168. [DESIGN, large] Hired help: its own grill (wages, a helper's pace, off-screen jobs).
   Later layers on record in the doc: upfront pay and raises, evidence surfacing, the
   off-season events, selling up, the front page, referrals, wear and overheads.

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
