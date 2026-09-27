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
55. [FEATURE, small] A council playground as a neighbour type (`beyond.gd`), next to the
   terraces only (101). The empty lot's earth went curved in S8.
62b. [FEATURE, small] Leftover thoughts from ramming the car (not decided): a direct hit
   shoves the car a little; dents show on the sprite.
75b. [FEATURE, large] Venues, what's left after S8's mansion and churchyard (their relayout is
   102 and 103): the golf course (its own grill: 18 holes as separate jobs?); community service
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
91. [DESIGN, large] Mower types that play differently, three separable pieces:
   a. Push: walking pace by default, a sprint button reaches today's speed; walking drains
      less stamina, so longer and more precise (touches parked 30).
   b. Petrol: a ripcord mini-game to start it the first time; badly damaged and still run,
      it may stall.
   c. Ride-on: manual gears, stepped up and down, setting top speed and turning circle.
94. [DESIGN, moderate] A strimmer for edges: cut close to a bed without killing flowers.
   Equipment, design doc Mowers and Equipment.
96. [DESIGN, large] Optional subquests. Example: the pet rock escaped; bring any rock you find
   to the customer, who says whether it's theirs. Hand-ins go through "How am I doing?"
   (95, built in session 9).
100. [DESIGN, moderate] Weeds: the mower only half kills one, pulling it by hand pleases the
   customer. Maybe overgrown grass that takes more cutting (the dev is unsure of that one).

### Grilled 2026-09-27 (88: plot shapes, the manor, the churchyard, line of sight)

Decided in the design doc (Levels: plot shapes; The Customer: seen versus evidence).
Tech: plot outlines carve the grass grid with `lawn.gd` `_exclude_where` plus
`Geometry2D.is_point_in_polygon`; walls are `CollisionPolygon2D`; `lawn.keep_in` only
knows rectangles and needs the plot outline.

101. [FEATURE, large] Suburban plot shapes by neighbourhood: terraces (long and narrow) at
   the bottom band, semis with the house set forward (back garden) in the middle, the L at
   the top, rectangles mixed in. A building off the back fence fades while you're behind
   it (reuse the tree canopy fade). Homes: `main.gd` `_build_layout`, `_build_borders`,
   `game.gd` `make_job`. Sizes are mine to fit per shape (long-and-narrow at 1920 wide
   makes no sense).
102. [FEATURE, large] The manor replaces the mansion: railings and gates, a central gravel
   approach, loop drive or forecourt (per job), parterre as beds, breakable topiary, back
   lawn, tradesmen's entrance for the truck, parkland past a ha-ha. New art: the manor front
   (wide, symmetrical), ha-ha, railings and gates, topiary. Closes 75b's "loop drive
   doesn't join the road".
103. [FEATURE, moderate] The churchyard: church mid-plot and to one side, a wall behind it,
   a lychgate and a path to the porch, headstones in rows either side.
104. [FEATURE, moderate] Line of sight: `customer.sees()` becomes `sees(point)`, checked where
   the thing happened; blocked by anything taller than a person (the 80b heights), via
   `intersect_ray`. A window is a cone out from that window, with a faint highlight on the
   ground it sees. Highlight: Godot's `PointLight2D` plus `LightOccluder2D` may do it free
   (unverified: 2D shadows under the Compatibility renderer); else a cone polygon with
   the buildings clipped out (`Geometry2D.clip_polygons`). Brought into view counts at
   once, even after payment.
105. [FEATURE, moderate] The post-job summary screen, "After you left, the customer
   noticed:", replacing the small card (a new screen, space was the problem). Aftermath
   by ownership (their things, their dog injured or missing, bodies in view), one list
   with a plus or minus per entry and the total, reputation only. Replaces `customer.gd`
   `come_out`'s replay of everything unseen. Lands with or after 104. Future dog deaths
   (the mower, stoned and thrown over the fence) must leave evidence; a mulched dog always does.

PROPOSED ORDER: play the S9 checks; 101, 102, 103 (the playtest complaint); then 104 and
105 together (the witness rework); then a grill on 91 and 96.

### Parked

27b. [PARKED since 2026-09-26] A drive between jobs as its own segment (traffic, the police
   at high heat).
21b. [PARKED since 2026-09-26] Job types for variety, not pressure: mini golf, farm or
   botanical garden, infestation jobs. Add when 12 jobs of one lawn kind feel samey.
30. [PARKED since 2026-09-24] Stamina progression (S1-PUSH): level it up, better push mowers,
   drug or cybernetic enhancements.
30b. [PARKED since 2026-09-24] A dark path: the menace board (mafia dons, chasing enemies
   round a warehouse), a negative-reputation run, the loan shark as the way in.
37. [PARKED since 2026-09-24] Secret layer: collect enough hedgehogs or squirrels and a
   black-market hedgehog dealer turns up. Critters can now be carried (S8), so buildable.
