# Handoff

## Owed checks (rolling ledger)
The ledger lives in `CHECKS.txt` (answer on the `>` lines). A SessionStart hook opens it in
Notepad whenever an answer is still blank.

---

## Session 14 (2026-09-29): the season prototype built (162 to 166)
- **Built all five steps** of the old SEASON_PLAN (50e46fa): days from Tuesday 1 April 1980,
  a month-grid board (calendar, today's job or "On to the next job", the week's paper to
  book, regulars with Drop, the shop); Friday's vig plus keep, with buttons to pay extra
  off the debt; regular offers after the summary (accept, haggle for 20% more, decline);
  carried mood as the visit's start and the face on arrival; a token drift prop per visit;
  the ironman save (Continue / New business, the blackout on a quit job); the winter stub.
  SEASON_PLAN.md deleted as it asked; its lessons are in TRIBAL.
- **My calls, not the dev's (veto any):**
  - Booking puts an ad on the week's first free day (no day picker); no unbooking.
  - The paper covers today to Friday: Tuesday to Friday for the first week.
  - A regular's clash tries the day, +1, then -1; none free and that visit's missed, on to
    the next cadence (no mood hit). Only the next visit is on the calendar at a time.
  - Anything but a paid visit, or an end mood under 35, loses a regular. "End mood"
    subtracts what they found after you left (noticed rep x 5).
  - Cadence and ask-chance per persona in `Game.REGULAR` (busy and toff weekly; grump
    four-weekly and rarely asks).
  - The winter charges 26 weeks of keep ($1,300) and no vig; the part-week after the last
    Friday has no payday. Regulars come back at a chance of carried mood / 100; reputation
    drifts 20% toward the middle.
  - The blackout: -15 on the rep trend, -7.5 now; a regular blacked out on is dropped.
  - A night in the cells now takes tomorrow (a "Cells" day on the calendar); a regular
    booked then moves on a cadence.
  - The business save sits beside `save_path` (`best_business.save`), so tests' own
    save_path keeps them off the real save. Bankruptcy deletes it.
- **Not built:** "the dead stay dead" (nothing in a garden dies for good: the dog only
  limps, critters respawn; see TRIBAL). The start month is `Game.start_month`, a code knob,
  no in-game switch.
- Arithmetic, not measured: at a Fair name the paper has 3 small ads a week at about $70
  to $85, so a perfect week clears the $150 due by about $60 to $100. Paying down $1,000
  from that is slow by design; S14-PACE asks how it feels.
- Verified: run_all green (parse, smoke, 32 tests) under the strict gate; test_season
  rewritten (money, paper, regulars, cells, save and blackout, winter), test_run_flow
  drives title to board to job to offer to a regular's visit to quit, blackout and payday.
  Screenshotted and looked at: the board (1 and 5 regulars, the right column scrolls, long
  surnames clip), payday, after payday, winter, the offer, the blackout. Not played.

OWED CHECKS: 15, in CHECKS.txt (3 loads, about 50 minutes; LOAD 3 is the prototype).

NEXT:
1. Play the prototype (LOAD 3) and the S13 checks; triage.
2. Retune the first numbers from S14-PACE (principal, vig, keep, ads a week).
3. The text pass (159, with 158) over the board, payday, winter and offer text.
4. Grills waiting: 168 (hired help), 147 with 94 and 100, 136, 137, 96; 140's retune after
   play; 167 (the record) is next to build once the prototype has been played.

## Session 13 (2026-09-29): the 160 grill (a business, not a roguelite), S12 fallout built
- **Grilled 160** (design doc, The Business and Season Prototype; NOTES 162 to 168). The dev
  pivoted the game: a small gardening business season after season, not a roguelite run
  (the 4-week run was only an on-ramp: best kit by week 2 or 3). Paperboy as the reference.
  Settled: real months April to September, one job a day, Sundays too, a month grid, 1980;
  the shark as a principal plus a weekly vig (paid off, you're free); a weekly living cost;
  a weekly paper at payday; regulars offered after a good job (a hidden chance, accept /
  decline / haggle, cadence-only requests auto-scheduled, carried mood as the
  relationship, a floor that cancels, no tips); the garden remembers (the dead stay dead,
  drift); ironman saves with the "blacked out" penalty for a quit job; one winter screen;
  sell up and retire as the win, the shark's patience as the loss; heat becomes a record
  of convictions, with summonses, a bought lawyer's roll, sentences as calendar days, and
  prison by accumulation. Back pocket, all on record: multi-day jobs, grass length by
  cadence, referrals, the compounding vig, wear and overheads, winter work, save-scum
  escalation, hired help (its own grill, 168).
- My calls the dev confirmed: the bad ending where bankruptcy fires now; jail at once,
  community service on the next free day; old heat numbers as conviction weights; cells
  cost the next day; the week-4 finale dropped; score is the pot at selling up.
- S12 checks: all 16 answered. Passed: UNSEEN, WALLDROP, DONE, LAG, CHIMNEY, HAHA, DRY (with
  175). PORTRAIT reads clear (the dev's partner to see it). BANNERS not reproduced and
  LFENCE "some better", both on the dev to report with a screenshot. BODY: an unconscious
  hedgehog pricking is meant. The rest became NOTES 169 to 177, all built (c28205b).
- Found while building: a critter thrown over a hedge landed as "ground" next door, so no
  eviction ever fired (only "gone", off a roof's back slope, did); and a hedge is clearable
  only from about 35 to 190 px back at full power (the test checks 100 px and 8 px; the
  range is arithmetic). If that feels too hard, the lever is the hedge's throw clearance.
- The patio slabs were the bottom 24 rows of the house art, drawn upright; now ground
  (z -2), so a hose or body lies on them.
- The dev's calls, in the design doc (42636e2): a second hit on a critter out cold kills
  it; an empty ride-on won't budge; a running engine standing still burns 30%; pockets
  hold 0 to 20% of the pay once they've paid you; the ripcord as a hand on the meter.
- Prototype prep: `docs/SEASON_PLAN.md` maps the code it replaces, a five-step build order
  with a test each, and first numbers (principal $1,000, vig 10% a week, living $50 a
  week: guesses, not measured).
- Verified: run_all green (parse, smoke, 32 tests) under the strict gate; new
  `test_slam.gd` fires real throws; fuel and police tests extended. Screenshotted and
  looked at: the hose on the slabs, the ripcord at rest, drawing, mid-yank. Not played.

OWED CHECKS: 9, in CHECKS.txt (2 loads, about 25 minutes).

NEXT:
1. The season prototype, 162 to 166, by `docs/SEASON_PLAN.md` (step 1: dates and the vig).
2. Play the S13 checks when convenient; triage.
3. The text pass (159, with 158), after the prototype rewrites the board's text.
4. Grills waiting: 168 (hired help), 147 with 94 and 100, 136, 137, 96; 140's retune after play.

## Session 12 (2026-09-28): the S11 checks triaged and built, no witness no heat
- All 24 S11 checks answered. Passed as written: S11-ARC ("much better"), S11-HOLE, S11-OVER,
  S11-LEAD, S11-DOOR, S11-DOGHOME, S11-HOUSE (the look), S11-MOTOR, S11-PUSH (pace right),
  S11-STALL, S11-ENGINE, S11-RUNOVER, S11-PAD, S11-BOARD, S11-SPAWN (nothing stuck since;
  the dev will say if it returns). S11-HEAP: brackets stay, the dev is unsure of the look.
  S11-GEARS: feels worse to drive, maybe rightly (it was overpowered); noted on NOTES 140.
  The rest, plus a notes dump, became NOTES 141 to 161 (591d64f).
- The dev's calls (promoted to the design doc, 6fab5b0, vetoable): no witness, no heat
  (seen, heard, or a neighbour for a robbery); a critter a customer wants hurt is no crime
  whatever it hits, bar them, their car, window or dog; a critter thrown out in their sight
  moves mood by 40% of its death; the loose hose piece; an engine run dry dies and wants
  restarting; the greyed portrait eases and says UNSEEN; buildings never fade (chimneys).
- My calls (vetoable): a broken pane counts as their window; a cut-off hose piece can't be
  cut again (a `ponytail:` in hose.gd); an empty mower is still pushable; the ripcord's cord
  and PULL; wording for UNSEEN, PULL, "Out of petrol" until the text pass.
- Built (a39ec5f, unplayed): 141 to 146, 148 to 154, 156, 157, 161. The manor lag measured:
  `_show_cone()` 190 ms worst per window change, now 6 ms (headless timing, a test guards it).
- New gate: run_all copies `tests/strict.cfg` to `override.cfg`, so every GDScript warning
  fails the tests (the editor's parse step never saw warnings). It found three more the
  editor hadn't shown (summary.gd, two tests).
- Text pass prep: `docs/TEXT.md` from `tools/text_inventory.py`, 417 lines by script and
  function. The dev's format for it: line by line together, I show the scenario and the
  current text, they reword and give variants.
- 155 (the briefing in a weird spot) not reproduced: screen-centre in a 1280x720 window.
- Verified: run_all green (parse, smoke, 32 tests) under the strict gate; new or extended
  tests venues (cone timing), critters (heat and eviction), stunned (bodies), fuel, fired,
  talk, hose (loose piece), fallout (wall drop). Screenshotted and looked at: UNSEEN, the
  ripcord cord, the ha-ha corner, the L notch join. Not measured: anything by feel.

OWED CHECKS: 16, in CHECKS.txt (3 loads, about 40 minutes).

NEXT:
1. /grill on 160 (a season calendar of regular clients: the dev's pick for next).
2. The text pass (159, with 158's "All told"), line by line with the dev.
3. Play the S12 checks; triage.
4. Then 140's retune if play agrees, 106 and 107; grills on 137, 136, 147 with 94 and 100, 96.

## Session 11 (2026-09-28): the S9 and S10 checks triaged and built, each mower's feel
- All 28 checks answered. Passed as written: S9-HEAD, S9-HEDGEHOG, S9-GRIT, S9-CAR, S9-TREES,
  S9-VICAR ("better"), S10-TERRACE, S10-SEMI, S10-SIGHT, S10-CONE, S10-UNSEEN, S10-CHURCH.
  The rest turned up work (NOTES 113 to 139, triaged at the start); S10-CARRY couldn't be
  tried (no intact body) and rolls on as S11-CARRY.
- The dev's calls this session (promoted to the design doc, vetoable): the throw shows its
  whole arc to the first hit (reverses "no path line"); things thrown off the plot land next
  door, never fetchable; critters live past the boundary and walk in, a hedge rustling as
  they pass; knocked out stays knocked out; running one over knocks it out, likelier the
  smaller the mower, the ride-on always splats; a critter thrown hard into something solid
  is knocked out; the hose green on a reel, only the end and reel are grips, no kinks; the
  pad layout (A on, B off and back, X throw, the stick only steers); the door knock moment;
  the lead on when you choose; the summary as two books; once-a-job things as events; no
  stamina levelling (a consumable kept as an idea); the manor's back lawn kept; the ha-ha
  redrawn before railings.
- Calls I made (vetoable): interact does the target nearest the spot in front of you,
  outlined (options were A/X, a cycle button, a pick list); run-over knockout 70% push,
  30% petrol; the house fades only while its art covers you (it had nothing behind it);
  the manor roof square-ended; sprint on R/RB, gears R/C and RB/LB; walking drains stamina
  0.6x, sprinting 1.5x; ripcord sweet spot at 62% of the meter, 6 to 20% wide by
  condition, a stall on half of knocks under 40%; ride-on gears 30/50/75/100% speed.
- Built (all unplayed): the bug batch (throw arc, windows, thuds, fired-after-paid,
  knockouts carried, spawns, off-plot flights), controls, the hose and reel, interact
  targets, the door, the summary, the manor fade and roof, the ha-ha, 108 to 110 (each
  mower's feel), 112 (sim_balance per plot), and docs/SPRITES.md (137 prep).
- Found on the way: squirrels "climbed down" rocks, headstones and topiary (the tree filter
  took any round obstacle); a critter spawned inside next door's corner spun forever; the
  hose chain blew up to infinity when yanked taut (the anti-kink step kept stretched
  lengths); a flaky test pair fixed; a spawn spot could still land against a building when
  ten random tries all did (now forty, else no spawn that time). Once a commit (9471c66) went in over two failing
  tests: both were test flaws, fixed in 80bfe24.
- Balance (NOTES 140, sim numbers not play): no mower gets the bot to 85% within patience
  on the small plots; the ride-on isn't faster than petrol on open lawns; the push at
  walking pace is far off; the ride-on can't mow the churchyard. Nothing retuned.
- Verified: run_all green twice in a row at the end (parse, smoke, 31 tests); new tests throw_path, fallout,
  controls, mower_feel; hose, tells, talk, records, animals rewritten or extended. Every
  visual change screenshotted and looked at (arc, facade, hose and reel, door, ha-ha,
  ripcord meter, summary). Not measured: anything by feel.
- After the handoff, the dev's calls (built, 4ae2567): Shift (pad A) sprints; the ride-on
  shifts on Shift and Ctrl (pad RB, LB); powered mowers start switched off and interact
  switches them off to save fuel (ride-on key on; petrol by ripcord). The pad's A is also
  interact, so from the mower the truck opens only off the throttle (my call). CLAUDE.md
  now allows Shift and Ctrl. NOTES 140: play first, then retune. 30b stays parked.
- 106 (packing) not started on purpose: it changes how mowers are chosen, on top of this
  session's unplayed mower feel, and its grid sizes and shapes are still open.

OWED CHECKS: 24, in CHECKS.txt (3 loads, about 50 minutes).

NEXT:
1. Play the checks; triage what they turn up.
2. Retune from the checks and NOTES 140's numbers if play agrees; then 106 and 107.
3. /grill on 137 (the art pipeline: blocks the manor and topiary redraws), then 136
   (storylines and the animal dealer), 96 (subquests), 94 (strimmer) with fire, 100 (weeds).

## Session 10 (2026-09-27): grills on 88 and 91, plot shapes, the manor, churchyard, line of sight
- No checks answered: all 16 S9 checks roll on (S9-BODY and S9-BOARD reworded for this
  session's rule changes). 12 new, 28 owed.
- Grill on 88 (the dev chose each; design doc Levels and The Customer): a layout per venue
  (golf course to its own grill); a building off the back fence fades while you're behind
  it, the churchyard walls that ground off instead; suburban shapes by neighbourhood
  (terraces, semis set forward, an L; corner plot, wedge and bent drive parked); the manor
  from the dev's references with the truck at the tradesmen's entrance, only the formal
  gardens mowable, a ha-ha on the park sides, railings by the gates, parterre as beds,
  topiary breakable, a fixed skeleton with details per job, loop or forecourt per job;
  the churchyard's church to one side; a playground next to the terraces.
- The dev reworked seen versus evidence mid-grill (their idea, better than my proposal):
  during the job they only know what they see happen; line of sight (anything taller than
  a person blocks it; a window is a cone with its ground faintly lit; upstairs windows
  seeing over things parked); afterwards ownership decides what they notice, bodies in
  view count, on a new post-job summary screen that moves reputation only; carried into
  view counts at once, even after payment. Balancing evidence-hiding waits for play (first
  lever: squashing costs a little mower damage). This reverses part of an older rejection
  ("sight lines and neighbours as witnesses"): neighbours stay rejected.
- Grill on 91 (design doc Mowers and Equipment): packing the truck as inventory Tetris
  (cab: push mower free; bed; a trailer a ride-on fills, or 2 to 4 robot mowers; the
  trailer bought, bundled with a ride-on), a packing screen before every job, swap
  anywhere with the unused mower recalled to the truck, "Pack up and leave" brings it all
  home unless the police were called; the robot mower (bounces, stops at bed edges, flings
  stones as yours); push: hold to sprint; petrol: a timed ripcord, stalls on a knock below
  about 40%; ride-on: four instant gears. "Best at a plot" is emergent, never a penalty.
- Built, all unplayed: 101 (shapes), 55 (playground), 102 (the manor, new art: front,
  coach house, topiary, railings, piers), 103 (churchyard, new art: walls, lychgate),
  104 and 105 (line of sight, the cone, the greyed portrait, the aftermath list, the
  summary screen; the board's rundown moved onto it). Fixed on the way: critters came out
  of a wall a building stands against; mulched bodies counted as bodies for 12 s.
- Calls I made (vetoable): terraces under reputation 40, semis 40 to 70, the L from 70, a
  rectangle 30% of the time; terrace 560x1600 (about a small lawn's area), house 64 px off
  the road, no car; the manor 1760x1340 (grass measured within 2% of the old mansion's),
  topiary $60 a chunk; the window cone 100 degrees; a noticed item's reputation is its mood
  hit over 5, "Every blade cut" +2; bodies they already saw aren't counted again.
- Verified: run_all green (exit 0; parse, smoke, 27 tests), new test_shapes, extended
  venues, seen, stunned, run flow, each checked failing without its fix where it guards a
  bug. Every visual change screenshotted and looked at. Not measured: terrace mowing time
  against patience (sim_balance only runs the default lawn, NOTES 112).
- Promoted to the design doc this session (vetoable): everything above under the two
  grills; also "a body is found after you've gone" replacing "when they come out".

OWED CHECKS: 28, in CHECKS.txt (6 loads, about 60 minutes).

NEXT:
1. Play the checks; triage what they turn up.
2. Build 108, 109, 110 (each mower's feel), then 106 and 107 (packing, the robot mower).
3. /grill on 96 (subquests), then 94 (strimmer) with fire, and 100 (weeds).

## Session 9 (2026-09-27): S8 checks cleared, triage 82 to 100, fixes, throw arcs, talking
- S8 checks: all 21 passed. Comments became NOTES 82 to 89; the dev's idea dump 90 to 100.
  The dev answered the triage questions: grit for stones the blades grind up, a car bump
  is a crime only at speed, pad triggers plus the stick, wants in the pause menu and in
  "How am I doing?", the truck keeps "Drive off (no pay)"; stones knock critters out
  (thrown: KO, else a body; flung: splat, else KO), and a stone kill leaves a body you can
  hide or mow. The dev shared manor reference images for 88 (summarised in NOTES 88).
- Built, all unplayed: 98 (header in two rows; the real overflow was the rundown's rep
  line shoving the shop off, so rundown lines wrap), 84, 85, 89, 92, 87, 82, 86, 97,
  80b (throw arcs), 95 and 93 (talk to the customer), 99 (ticker, records), 83 (the hose).
- Verified: run_all green (exit 0) with new tests: stunned, talk, records, hose, plus
  extended critters, throw, hazards, police, venues, mower drive. Each visual change was
  screenshotted headful and looked at. Nothing play-checked yet.
- Promoted to the design doc (vetoable): paid face to face, wants stay readable, car bump
  vs ram, personal bests and worsts, stones knock critters out, the hose on its tap, pad
  triggers. Throwing step 2 was already there.
- Calls I made while building (vetoable, not in the design doc):
  - Knockouts: thrown 80% KO / 20% body, flung 75% splat / 25% KO; KO lasts 6 s and costs
    40% of a death's mood; an unseen KO leaves nothing to find. Seen mulching a body
    counts as a death again. A body in the pond is hidden too.
  - Arcs: gravity 600; tilt 6 to 90 degrees at 60 a second, starting about 29 and kept
    between throws; power scaled so 45 degrees carries the old reach. Heights: fence or
    hedge 29, a person 30, car 36, truck 60, parked mower 20, critters 10, dog 16, rocks
    and headstones 24, the canopy a ball round the crown, a 45 degree roof, over the ridge
    gone. New side effect: a low throw at the fence now bounces back instead of leaving.
  - The ball never hits the dog. A ram is a crime above impact 200 (petrol near top
    speed, the ride-on).
  - Talking: within 36 px of the patio spot (the door's there); knocking brings them out.
    "Wants it" comes from persona patience and target.
  - Records: the most per job of each count, saved; firsts don't count; best for dogs
    walked home, fetches, stones picked or binned, cans; everything else is a worst.
  - Hose: orange so it reads on grass, tap on the side away from the garage, 18 links of
    16 px, cut once (the far end shredded).
  - Vicar: "Reverend" plus surname, a clerical shirt (never picked at random), a collar
    tab drawn on the portrait only (not the standing sprite).
- New cheat: none. New tally names: knocked out, bodies disposed of and mulched, stones on
  your own head.

OWED CHECKS: 16, in CHECKS.txt (3 loads, about 30 minutes).

NEXT:
1. Play the S9 checks; triage what they turn up.
2. /grill on 88 (venue shapes and the manor, from the reference images); it decides 46,
   55 and 75b.
3. /grill on 91 (mower types that play differently) and 96 (subquests); 94 and 100 when
   there's room.

## Session 8 (2026-09-26): the whole grill order built (season, crime, objects, venues, art)
- Built, all unplayed: bug batch 58 to 61, charged throws step 1 (80), the season and
  payday (72, 78), impatience signals (73), heat and the police (74, with 62's car ram),
  rifling pockets (76), seen versus evidence (77), objects by size (79), critters in hand
  (81), the mansion and churchyard (75 first cut), and the 3/4 art pass (66 to 71).
- Verified: run_all green (exit 0) with new tests: throw, season, police, seen, objects,
  critters, venues. Every feature was also screenshotted headful and looked at. Nothing
  play-checked yet: 21 checks in CHECKS.txt.
- Calls I made while building (vetoable, not in the design doc):
  - Police are called for tier 2, or tier 1 once the job started at heat 3+, and only if
    the customer can see (robbery always). Countdown 60 s, 8 s less per heat level, floor
    20. Fines $50 (tier 1) / $150 (tier 2), x(1 + 0.25 per heat). A fine can put money
    negative. Vandalism after being fired counts once a job.
  - Only thrown stones are crimes; blade-flung ones are accidents (rep only).
  - Short on payday, the heavies take dearest kit first until covered and you keep the
    change; kit resells at half price. Heat cools a level per week paid.
  - Customer indoors share by persona: perfectionist 0.1, gardener 0.25, nature 0.3, grump
    0.35, squirrel hater 0.4, toff 0.5, busy 0.7.
  - Venues: 40% of offers at 75+ rep are a mansion (1.8x pay); 50% under 20 rep (not the
    dregs) are the churchyard (0.7x). Mansion windows cost 3x, urns $120.
  - Props per garden: gnomes (more for the gardener), 30% flamingo, 20% cone, 60% hose,
    a ball if there's a dog, 0 to 2 boulders.
- Side effects: the mower's collision is now its foreshortened footprint, so the ride-on
  got quicker in sim_balance (50% at 86 s, was 99 s). audio/splash.wav no longer matches
  tools/make_audio.py exactly; left as committed. Trap noted in docs/TRIBAL.md: a texture
  load()ed in _draw draws as a white box.
- New cheat: [4] on the board takes 20 rep off (to reach the churchyard).
- Parked items reviewed (parked about 6 sessions): 19 (stripe blending) dropped; 30, 30b
  and 37 kept, still parked.

OWED CHECKS: 21, in CHECKS.txt (5 loads, about 35 minutes).

NEXT:
1. Play the checks; triage what they turn up.
2. 80b, throwing step 2 (arcs), once S8-THROW has been played.
3. 75b (the loop drive joining the road, the golf course), 46, 55.

## Session 7 (2026-09-26): check triage and the big grill (the season, crime, venues, throwing)
- Checks: all 16 answered, CHECKS.txt cleared. Passed: the six S5 checks, S6-DEPTH, HEDGE,
  GARAGE, WINDOW, CUSTOMER, CAR (mostly). Problems triaged into NOTES 58 to 71: the on-foot
  sprite flips upside down (58, BLOCKS; diagnosed from code, not reproduced: walker.gd
  rotates every frame but redraws only every 9 px of stride), the knocked-out customer
  still turns (59), the car hitbox is 110 tall where the sprite's footprint is 66 (60),
  stones vanish on walls (61), and a 3/4 art pass (66 to 71: pond and beds, tree bases,
  fences, chimney, garage depth, featureless ground next door).
- Your calls (vetoable, all in the design doc, game-dev 948250a onward):
  - The run is a 4-week season, 3 jobs a week, a loan shark's payment each week ($120,
    $250, $450, $750, a guess); a miss sends his heavies to repossess kit; you can sell kit;
    zero rep gives the dregs, not "File for bankruptcy"; paying week 4 wins. Runs are years
    (leaning: the 1980s, starting 1980). Only the payments ramp: the rep tiers are the
    difficulty curve, unchecked.
  - Impatience keeps its rules, gains signals (watch glance, sigh, escalating nags).
  - Heat is separate from rep, only for crimes; a four-tier crime ladder with
    proportional punishment (fines, a lost job slot, season over only for killing); heat
    shortens a visible police countdown and cools a level per week paid; no job-start
    arrest roll. Rifling pockets trickles cash while held. Animals thrown into things tier
    the crime up.
  - Seen versus evidence: the customer moves between patio, inside and windows; unseen
    acts are judged by what's left; the portrait greys out.
  - Venues by rep band (mansion and graveyard first), community service later.
  - Between jobs: a walkable hub is the destination; a menu plus a payday scene for now.
  - Objects: small (carry, throw, mow), medium (shoved), big (solid); charged throws
    locked in place with a landing marker, vertical angle as step 2.
  - 8 facings left to soak (a diagonal sprite points about 31 deg while you travel 45).
  - The car: mower ramming dents it too, harder hits cost more.
- Promoted from NOTES to the design doc: 21, 22, 25, 26, 27, 29, 38, 40, 56, 63, 64, 65.
  Build items 72 to 81 replace them. Parked: 21b (job types), 27b (the drive), 30b grown
  into the menace board.
- No code changed. Verified: run_all green (exit 0).

OWED CHECKS: none (CHECKS.txt says nothing owed).

NEXT (NOTES has the full order):
1. 58, the on-foot sprite flip, then 59 to 61 as a bug batch.
2. 80, charged throws step 1.
3. 72 with 78, the season and the payday scene: the new spine.
