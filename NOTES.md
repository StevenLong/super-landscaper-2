# Notes (task list)

Triaged dev notes. Each item: tag, size, the note, root cause or home file, FIX sketch,
open QUESTION. Numbers are stable (done items are deleted, not renumbered). `/handoff`
sorts this file: done items go, decided design items move to
`../game-dev/Super Landscaper.md`, the rest wait for a grill or sit parked with a date.

Tags: BUG / FEATURE / VISUAL / DESIGN (needs a call before building) / PARKED.
BLOCKS = spoils the next playtest.

### From the 2026-09-24 play checks

**Build (no design call needed)**

12. [FEATURE, moderate-large] Camera never clamps; the world carries on past the garden
   (S2-BORDERS): footpath and road to the south, next door's gardens either side, seen but
   not reachable. The player stays centred. Critters then spawn where the player can see
   them but can't already be, which ends the unavoidable one-pixel-step-into-the-blades hit.
   Home: `main.gd` camera limits, garden build in `main.gd`. Build with 39.
13. [VISUAL, moderate] Trees (S1-TREES): they don't read as trees; things under canopies got
   hit unseen. Bigger canopies that fade when you get close or under, much bolder trunks
   that read as solid, varied trunk sizes. Variety of objects expected later, not now.
18. [FEATURE, small] Throw stones at your own truck or mower (damage), a tree or flower bed
   (some effect) (S2-THROW).
20. [FEATURE, small] Settings on the title screen (S1-ATTRACT). The pause menu's music/sound
   toggles already exist to reuse.
28. [FEATURE, moderate] The job board as newspaper classifieds (S1-BOARD): text ads, no
   picture or quote, rough lawn size, pay, and subtle hints ("careful applicants only").
36. [FEATURE, moderate] Run stats: critters run over or picked up, stones collected, and the
   rep or money each earned or cost. A funny tally after the job and at run end.
39. [FEATURE, moderate-large] Layouts that make sense: the truck parks on the street at the
   end of the drive or in the drive, not on a random patch of concrete on the lawn. Houses
   get a drive and a garage, and maybe the customer's car in the drive, one more thing to
   crash into. Build with 12.

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

PROPOSED ORDER: 12 with 39 (both reshape the garden edge), then 11, 13, 14. A grill session
on 21, 22, 25, 26, 27, 29, 38, 40 before any of those are built.

### Notes 2026-09-25 (session 3 play checks)

43. [VISUAL, small] The mouth moves while the customer talks (S3-FIRED). Speech under the
   portrait (typed a word at a time), rep pops by it and the YOU'RE FIRED banner are built;
   `face.gd` has no mouth animation yet. QUESTION: a second face frame with the mouth open
   in `tools/make_faces.py` (recommended), or flap the existing mouth region?

PROPOSED ORDER: 43 once the mouth is decided, then 12 with 39.
