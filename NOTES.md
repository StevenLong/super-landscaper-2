# Notes (task list)

Triaged dev notes. Each item: tag, size, the note, root cause or home file, FIX sketch,
open QUESTION. Numbers are stable (done items are deleted, not renumbered). `/handoff`
sorts this file: done items go, decided design items move to
`../game-dev/Super Landscaper.md`, the rest wait for a grill or sit parked with a date.

Tags: BUG / FEATURE / VISUAL / DESIGN (needs a call before building) / PARKED.
BLOCKS = spoils the next playtest.

### Build (no design call needed)

46. [FEATURE, small] Layout variety, what's left: the drive's shape (a bend or a wider
   mouth needs non-rectangle drives).
47. [BUG, small] Board: pad (and arrows) left/right step up and down the mower list
   (S4-PAD-MENUS). Home: `board.gd` `_mower_row`. Waits on the walkable hub, which may
   replace this menu.
55. [FEATURE, small] A park or playground as a neighbour type (`beyond.gd`). The empty lot's
   earth went curved in S8.
62b. [FEATURE, small] Leftover thoughts from ramming the car (not decided): a direct hit
   shoves the car a little; dents show on the sprite.
75b. [FEATURE, large] Venues, what's left after S8's mansion and churchyard: the loop drive
   doesn't join the road yet (`main.gd` `_loop_drive`); the golf course; community service
   (a tier 2 arrest's lost slot becomes a forced unpaid job, needs a litter-pick or prison
   venue); the week-4 finale (open in the design doc).
79b. [FEATURE, moderate] Objects, later batches (design doc Mowers and Equipment): medium
   things shoved by heavy mowers (RigidBody2D: chairs, parasols, a sandbox rim), a sapling
   that snaps, sandbox, paddling pools, lawn darts, litter, croquet hoops, more critters and
   their interactions (cats, birds, rats, pond fish), fire.

### Notes 2026-09-27 (S8 check fallout, and an idea dump; what's left after session 9)

88. [DESIGN, large] Every venue is still a rectangle with a building top-middle, so the
   ladder feels samey (a playtester said the same). The mansion reads as a McMansion: the
   dev wants a stately manor (reference images shared in session 9: a long straight
   approach down the middle through gates, lawn either side, gravel forecourt or loop in
   front of a wide symmetrical front, formal parterre beds and clipped topiary, estate
   parkland and woods around, no neighbouring plots, no picket fence or garage-and-drive).
   Ideas: non-rectangular plots, buildings not at the back, the golf course as 18 separate
   holes (a job each), mini golf (see 21b). Needs a grill; supersedes 46's drive shapes
   and part of 75b.
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

PROPOSED ORDER: play the S9 checks; a grill on 88 (venue shapes, the manor) before 75b or
46; then a grill on 91 and 96. Rationale: 88 decides what 46, 55 and 75b even are, and
it's the playtesters' main complaint.

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
