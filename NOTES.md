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
80b. [FEATURE, moderate] Charged throws step 2: up/down set the vertical angle, flights
   become arcs with a shadow, every target gets a height (lob over the fence, onto the roof,
   through an upstairs window, straight up onto your own head). Build after S8-THROW is played.

### Notes 2026-09-27 (S8 check fallout, and an idea dump)

From the S8 checks (all 21 passed; these are the extras):

82. [DESIGN, small] S8-BOUNCE: stones sometimes vanish under the mower. Intended in code
   (`main.gd` `_on_stone_mowed`: 70% fling, `Stone.LAUNCH_CHANCE`, else just freed), but
   nothing shows where it went. FIX: the 30% leave grit (a small `_burst`), or always fling.
   QUESTION: which?
83. [FEATURE, moderate] S8-PROPS: the hose should be fixed to a tap on the house wall, and
   you drag it out of the way by the end or a point in the middle (awkward on purpose).
   Home: the `hose` kind in `stone.gd` becomes its own node (a chain of points); mowing it
   still splashes.
84. [BUG, small, BLOCKS fetch] S8-FETCH: the second throw hits the dog because it stands
   next to you. Root cause: the flight's hit test returns "dog" for any flying kind
   (`main.gd` near line 1191). FIX: the ball never hits the dog; better, if it passes
   through the dog, the dog catches it.
85. [VISUAL, small] S8-CRITTERS: a bare-handed hedgehog should reach your hands for a beat
   before the OW, so it reads. FIX: `walker.carrying = "hedgehog"` for about 0.3 s, then
   drop and stun.
86. [DESIGN, small] S8-CAR: ramming the car both bills the dent and raises heat (`main.gd`
   `_on_mower_bumped`: bill plus `_crime(1)`). Same as throwing a stone at it. By the
   "blade-flung is an accident" rule, a bump could be bill only, with the crime only above
   some speed. QUESTION: bill only, crime above a speed, or keep both?
87. [FEATURE, small] S8-DREGS / S8-CHURCH: the vicar doesn't read as a vicar. FIX: a dog
   collar and black shirt on the face (`tools/make_faces.py` key colours), and priestly
   reaction lines ("May God forgive you" on a squashed critter, "Bless you" on good work).
   Home: the `vicar` persona in `game.gd` (it has brief lines, not reaction lines). Noted,
   no change: the churchyard beats the dregs job at the bottom of the ladder; the dev is
   happy with that, and with the headstone-weaving trade-off.
88. [DESIGN, large] S8-MANSION + S8-CHURCH + idea dump: every venue is still a rectangle with
   a building top-middle, so the ladder feels samey (a playtester said the same). The
   mansion reads as a McMansion: wanted a stately manor, no neighbouring plot, no picket
   fence or garage-and-drive. Ideas: non-rectangular plots, buildings not at the back, the
   golf course as 18 separate holes (a job each), mini golf (see 21b). The dev offered
   reference images of the manor. Needs a grill before building; supersedes 46's drive
   shapes and part of 75b.
89. [VISUAL, small] S8-TREES: with the canopy faded, the trunk ends in a flat cut. FIX: the
   trunk top fades out, or branch stubs in the sprite. Home: `tree.gd` (the fade) and the
   trunk art.

From the idea dump:

90. [PARKED since 2026-09-27] Character and company creation: pick the character's look,
   name the company, design a logo. QUESTION when unparked: where does it show (truck
   livery, board header, the ads)?
91. [DESIGN, large] Mower types that play differently, three separable pieces:
   a. Push: walking pace by default, a sprint button reaches today's speed; walking drains
      less stamina, so longer and more precise (touches parked 30).
   b. Petrol: a ripcord mini-game to start it the first time; badly damaged and still run,
      it may stall.
   c. Ride-on: manual gears, stepped up and down, setting top speed and turning circle.
92. [FEATURE, small] Controller: right trigger accelerates, left trigger reverses, stick or
   d-pad turns. Now the left stick's Y is the throttle and X the turn (`project.godot`
   `move_forward` etc.); the triggers (axes 4 and 5) are unbound. FIX: add them to
   `move_forward` / `move_back`. QUESTION: does stick Y stay as a throttle too?
93. [FEATURE, moderate] The customer's wants should be readable during play (likes or hates
   squirrels, quick or thorough), not memorised from the briefing. Home: `hud.gd`.
   QUESTION: always on screen, in the pause menu, or behind 95's "How am I doing?"
94. [DESIGN, moderate] A strimmer for edges: cut close to a bed without killing flowers.
   Equipment, design doc Mowers and Equipment.
95. [DESIGN, moderate] Talk to the customer to end the job: walk up to them, or their front
   door if they're in, and interact: "Ask to be paid", and "How am I doing?" (a mood probe,
   and where subquests are handed in). Now "Ask to be paid" lives in the truck menu
   (`main.gd` `open_truck_menu`). QUESTION: does the truck keep "Drive off (no pay)"?
96. [DESIGN, large] Optional subquests. Example: the pet rock escaped; bring any rock you find
   to the customer, who says whether it's theirs. Needs 95 first.
97. [DESIGN, small] A stone (or anything bladeless) knocks a critter out instead of
   splatting it, a smaller mood hit; a knocked-out critter can still be mowed. Root cause:
   the "animal" target in `main.gd` `_on_stone_landed` calls `squash()`. FIX: `Animal.stun()`
   lying still for a few seconds, then it wakes and runs. QUESTION: blade-flung stones too?
98. [BUG, small, BLOCKS] The board header runs off the screen. Root cause: `board.gd` puts
   six labels in one HBox (week, owed, money, earned, reputation with "(sliding)", WANTED)
   with no wrap. FIX: two rows, or drop "Earned this run" from the header.
99. [FEATURE, moderate] "Also counted" becomes a scrolling ticker of each stat, marking
   personal bests, and personal worsts for the frowned-upon ones ("most flowers run over").
   Needs per-stat records in the save. Home: `board.gd` `_rundown`;
   `tests/test_run_flow.gd` checks the "Also counted:" prefix.
100. [DESIGN, moderate] Weeds: the mower only half kills one, pulling it by hand pleases the
   customer. Maybe overgrown grass that takes more cutting (the dev is unsure of that one).

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

PROPOSED ORDER: a small-fix batch first (98 header, 84 ball and dog, 85 hedgehog in hand,
89 trunk tops, 92 triggers, 87 vicar), then 80b (S8-THROW passed), then a grill on 88
(venue shapes, with the dev's manor images) before 75b or 46, then a grill on the job-flow
set (95, 93, 96, 97, 82, 86). Rationale: the fixes are quick and visible, 80b is unblocked,
and 88 decides what 46, 55 and 75b even are.
