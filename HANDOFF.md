# Handoff

## Owed checks (rolling ledger)
The ledger lives in `CHECKS.txt` (answer on the `>` lines). A SessionStart hook opens it in
Notepad whenever an answer is still blank.

Verifier tally (the adversarial agent, scored by /handoff): 4 runs, 29 real finds (1 of them
a regression of mine it caught before the dev did), 0 false alarms, 0 misses so far. Cost
per run: about 95k to 240k tokens, 9 to 15 minutes (all 2026-10-02).

---

## Session 17 (2026-10-02): the 193 grill (time is the scarce thing), the clock built
- **Grilled 193** (pace and escalation, the dev's biggest concern), all in the design doc
  (The Business, "Time is the scarce thing", rejected options listed): the squeeze changes
  as the business grows, money in April, time in summer, stakes from season 2; money's
  lasting use is buying time (so 189 robots and 168 help get priced as that); difficulty
  is not the dial. One clock (a booking is a window, patience is that window); outside a
  job actions cost time and walking doesn't, shown before you commit; demand follows the
  season; regulars change softly, never churn; loyalty compounds; upfront pay only from
  loyal regulars; jobs stay fresh by variety and event days, not more on screen. The
  dev's reasons: the money number isn't the fun; Vampire Survivors' power curve doesn't
  fit (kit makes jobs easier); a hub without a clock is a task list. Build order the
  dev's call: the clock first, with the corkboard screen built as the screen the office
  will open.
- **Filed from the dev's dumps**: 207 (taking things from gardens pays, a market so
  hoarding can't win; conflicts with "afterwards, ownership decides") and 208 (your own
  garden: time frozen inside, seeds growing across visits).
- **Built** (my calls in the doc's "as built" bullets, veto any): 193a the day's clock and
  the corkboard (600a03f), 193b regulars change softly, the raise, upfront pay, loyalty
  (1e68685), 193c critters by month and event days (7158b48). Old saves load and get
  their windows. New tests: test_terms; big additions to test_season; tools/shot_board.gd
  for the board's screenshots.
- **Verifier, 2 runs** (3 and 4 of the tally): run 3 on the clock, 13 real finds (worst:
  being nicked didn't end the day; time after being paid was free; Ring could turn a sure
  yes into a no; court lost classifieds silently; the board ran off screen when busy);
  run 4 on terms and events, 8 real finds (worst: upfront money paid back twice and below
  zero at the winter; a stale offer crashed a summary; an event day's critters leaked into
  a new regular's every visit). All fixed with a test (65b7e12, da85a9c). 0 false alarms.
- Verified: run_all green (parse, smoke, 39 tests). Screenshots looked at: each board page,
  crowded (8 regulars, 6 jobs, an event day), the job's HUD clock and briefing, the raise
  and upfront screens. Not played: whether the clock is fun is the dev's (LOAD 3).
- Not done: 193d's retunes wait for play (reputation tops out in about 3 jobs, now day
  one with free booking; the dev says the exact number doesn't matter, it just shouldn't
  saturate so early). S15-POLICE and S15-FENCE have now rolled two sessions.

OWED CHECKS: 12, in CHECKS.txt (3 loads, about 60 minutes; LOAD 3 is the clock).

NEXT:
1. Play LOAD 3 (the clock, the terms, event days); LOAD 1 and 2 when there's time.
2. 193d's retunes from what play says (reputation's climb, the paper's size, pay, the vig).
3. Grill 189 (robots) and 168 (hired help) together, as ways to buy time; then 207 with 136.

## Session 16 (2026-10-02): verify-first, the verifier, the robots fixed, the small pass built
- **Played (dev):** S15 mostly answered. Passed: TRUCK, SAVEQUIT, PAY, OFFER; PORTRAIT and
  PAPER pass bar the window glass (203) and the shop overflow (196). Raised: DOOR (slid
  backwards, 204), ROBOT (re-mowed cut grass, jammed; $150 cheap), PACK (send home, 205),
  and notes triaged into 196 to 206. A crash (robot after the dog went home) fixed at once
  (dcfaf99).
- **Process, the dev's call:** verify everything I can myself; a play check is owed only
  for what needs a person (feel, fun, pace, loudness, "does it read"); the rest goes in
  CHECKS.txt's VERIFIED section. The dev dogfoods daily, so no frame-by-frame rigs for
  motion. In CLAUDE.md (Verify) and the handoff skill (06731a4).
- **The verifier agent** (`.claude/agents/verifier.md`, in the repo so both machines have
  it; loads by name from the next session, this one ran it as general-purpose reading that
  file): 2 runs, 8 real finds, 0 false alarms. Run 1 (robots): unreachable grass driven at
  in straight lines for ever, 59 to 62 flowers flattened on a parterre, a corridor
  deadlock, solid shapes bigger than their no-mow areas. Run 2 (small pass): my own
  regression (Drive on the packing screen unpacked the item under the cursor), a customer
  invisible at a smashed window, an orphaned fourth gear, critters walking out of next
  door's terrace houses. All fixed and rechecked with its scripts. The dev wants its value
  tracked: the tally is in the ledger block. Keep it to one run per build batch.
- **Built** (all pushed; my calls in the design doc and the commits, veto any): 196, 200 to
  202 (the robots), 197 (truck bay), 198 (gears), 199 (horn), 203, 204, 205, the churchyard
  wall stub (194). Also a rare spawn bug (critters grazing the house corner; test_shapes
  flaked 1 in 7).
- **Promoted to the design doc** (the dev's calls this session): the customer faces the way
  they walk and is behind the glass at a window; two ride-on gears, the third and fourth as
  upgrades; the horn scares critters (annoyance open, 206); the truck's reach is one painted
  bay; send home on the packing screen; robots mow only uncut grass, stop when done, never
  deadlock, rammed takes damage both ways (stopping at a gnome is fine).
- **Lessons:** never run a background job that stashes project files (one got killed
  mid-stash; restored). A new agent type in `.claude/agents` only loads at session start.
- Verified: run_all green (parse, smoke, 40 tests; new test_porch, test_robot_jam,
  test_horn; additions in test_controls, test_pack, test_seen, test_mower_feel,
  test_robot, test_prompts). Robot coverage measured by sim; screenshots looked at for the
  board, window, bay, packing, horn, fences. Not played.

OWED CHECKS: 6, in CHECKS.txt (2 loads, about 30 minutes).

NEXT:
1. Grill 193 (pace and escalation), now, after clearing context.
2. Then grill 189 (robot tiers, price, speed) and 168 (hired help).
3. Play LOAD 1 and 2 of CHECKS.txt when there's time.

## Session 15 (2026-10-01): S13 and S14 played and triaged, the fallout built, the robot redone
- **Played (dev):** all 19 checks answered. Passed: S13-WALL, KILL, STONE, PATIO,
  POCKETS, CORD (a bit better), RIDEDRY, IDLE; S14-PAYDAY, VISIT, COURT, BLACKOUT (seen
  for free through a crash). Raised issues, all triaged into NOTES 178 to 195: S13-HEDGE,
  S14-CAL (readable, to be redone later), RING, OFFER, PACK, ROBOT (useless: it ping-ponged
  in a corner and bowled the dog off screen, police and all), PACE.
- **Fixed during play:** pack.gd crashed driving off (17dec2f: `change_scene_to_file`
  takes the scene out of the tree at once in 4.2+, so get the viewport first); fence and
  wall corners (dc5e08f: the side runs' art is a column mid-strip, so ends met nothing).
- **The dev's calls** (folded into the design doc, 3ae9a5f and 7cc843c in game-dev, veto
  there): the robot like a real one (knows the garden, straight stripes, never runs
  critters over, stops; destroys stones for a little wear); ringing the police fires you;
  seeing the throw is enough to react; pick the figure for the haggle and the debt; payday
  shows what a payment does instead of defining the vig; the regular's offer as a win on its
  own screen, a polite no still earns a little name; the customer walks, never jumps;
  the portrait's where and seen as separate discrete states; packing cursor per item.
- **Built after** (178 to 192, 195, all pushed, unplayed): see the commits 550b718 to
  e2fb9e2. **My calls, veto any:** the robot plans on a 20 px AStarGrid2D from the lawn
  grid, lanes along the way it's set down facing, waits 2 s then gives a spot up, -10 a
  stone, broken for the job at 0, crosses a drive to reach the rest of the lawn; the haggle
  slider runs to 1.5x their rate, each 10% under 1.2x adds 25% to the yes; declining gives
  +2 reputation; the debt slider steps $5 to $25 by what you can spare, its top end exact;
  the siren peaks at -16 dB (was -6); a customer's hitbox is 16 px round their feet; the
  portrait switches after 0.2 s held, no fade; they walk the door at 50 px/s and indoors at
  70 px/s, glimpsed through the panes; Start or [P] drives from packing (Esc stays put back).
- **Process:** the dev's free-form notes go in a NOTES section at the top of CHECKS.txt;
  the handoff skill now triages and empties it (6b7dcf0).
- Verified: run_all green (parse, smoke, 37 tests); new or changed assertions in
  test_pack (drive through real input; item stops), test_controls (the paper's last ad),
  test_police (fired on the call, not when out cold), test_robot (rewritten: plan covers
  every open cell, lanes straight, stone ground, stops for a body then goes round, wear
  carried), test_season (ask odds, decline rep), test_run_flow (the offer screen),
  test_seen (stroll), test_throw (seen throw). Screenshotted and looked at: the truck menu,
  the board, payday, the offer and its decline, the portrait states, the face at and
  passing behind the glass, the door walk, the packing cursor, a robot's stripes after a
  few game minutes, fence corners on six L plots and two churchyards. Not played.

OWED CHECKS: 14, in CHECKS.txt (3 loads, about 40 minutes).

NEXT:
1. Play LOAD 1 to 3 of CHECKS.txt; keep catching broken fences (194).
2. Grill 193 (pace and escalation, the dev's biggest concern) before retuning PAPER,
   REACH, the vig or pay; it may also reshape S14-RING's stratified bars.
3. Then 189's open parts (robot tiers), and the text pass (159, with 158).
4. Grills still waiting: 168 (hired help), 147 with 94 and 100, 136, 137, 96.

## Session 14 (2026-09-29): the season prototype, ringing the ads, the record, packing, robots
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
- **Ringing the ads** (the dev's call, after the build; design doc, The Business): the
  paper prints six ads spread round your name (`PAPER`: two below, two around, two above);
  each has a bar from its size, plot and venue (the dregs and churchyard 0, else at least
  20); ringing is instant and free, a yes books the first free day, a no stamps the ad for
  the week. The dev's note: play below the bar, so the chance falls to 0 over `REACH` = 15
  points. My calls: the bar numbers reuse make_job's old reputation band edges; the
  caller's lines are placeholders for the text pass.
- **The record (167)**, built after the prototype, unasked but decided in the doc: heat is
  gone. A witnessed crime goes on the job's `charge` (the old weights, `Game.RECORD`);
  only a conviction adds to `Game.record`. Caught: court in the morning. Escaped with the
  police called: a summons, court on the first free day `SUMMONS_DAYS` (3) on. No police,
  no court. Court is a calendar day: yourself or three lawyers ($60, $200, $600) for a 10,
  30, 50 or 75% chance to walk; guilty is `fine()` at the record before, the charge onto
  the record, and `sentence()`. Community service is `service_job()`, the churchyard
  unpaid with +5 rep when signed off ("Duty" on the calendar); jail days block at once
  and push a regular a day, else a missed visit and -10 mood. My numbers, all guesses:
  a nuisance is the fine only until the record reaches 2; assault is service (a day more
  if caught), jail from a record of 4; `MENACE` 8 turns service into jail; `PRISON` 16
  ends the business; a winter takes 1 off the record. Court and service left when
  September ends come first in April. New `test_court.gd`; test_season covers the rest.
- **Packing the truck (106)**, decided in the doc: `pack.gd` between the board's Go and
  the job. The cab holds the push mower; a 4 x 3 bed and a 4 x 4 trailer (a shop item,
  $100, bundled with a ride-on); kit is rectangles (petrol 2 x 3, ride-on 4 x 4 trailer
  only, can 1 x 1), turned to fit; a cursor picks up, turns, drops, puts back (mouse too).
  New kit packs itself; sold or repossessed kit leaves the truck; the board's "Use" is gone
  (the job starts on the best mower packed). At the truck, "Take out the ..." swaps: the
  other is recalled, keeping its fuel. Driving off with the police called while on foot,
  a mower not at the truck is lost. My calls: the grid and shape sizes; the truck still
  refuels a mower driven up to it, and packed cans are only the fuel you carry on foot
  (the old unlimited can is now what you packed). New `test_pack.gd`.
- **The robot mower (107)**, decided in the doc: `robot.gd`, a body with the mower's
  fields (`cut_radius`, `knock_out`, `damage()`), so stones, critters and beds treat it as
  a mower through the existing code: its flings and squashes count as yours. 55 px/s,
  12 px cut; straight until it bumps something solid or would leave the lawn's rectangle,
  then a random turn (90 to 270 degrees); it treats a bed's edge (plus its cut radius) as
  the wire. Bought any number ($150, `Game.robots`), packed 2 x 2; taken off the truck on
  foot ("Take out a robot mower"), set down with interact, picked up like a thing, can't
  be thrown; left on the lawn when you flee the police, it's lost. Drawn in code (a grey
  shell, green lid): a placeholder for the art. New `test_robot.gd`.
- **Not built:** "the dead stay dead" (nothing in a garden dies for good: the dog only
  limps, critters respawn; see TRIBAL). The start month is `Game.start_month`, a code knob,
  no in-game switch.
- Arithmetic, not measured: at a Fair name the paper has 3 small ads a week at about $70
  to $85, so a perfect week clears the $150 due by about $60 to $100. Paying down $1,000
  from that is slow by design; S14-PACE asks how it feels.
- Verified: run_all green (parse, smoke, 35 tests with test_court, test_pack, test_robot) under the strict gate; test_season
  rewritten (money, paper, regulars, cells, save and blackout, winter), test_run_flow
  drives title to board to job to offer to a regular's visit to quit, blackout and payday.
  Screenshotted and looked at: the board (1 and 5 regulars, the right column scrolls, long
  surnames clip), payday, after payday, winter, the offer, the blackout. Not played.

OWED CHECKS: 19, in CHECKS.txt (3 loads, about 75 minutes; LOAD 3 is everything built in S14).

NEXT:
1. Play the prototype (LOAD 3) and the S13 checks; triage.
2. Retune from play: S14-PACE and S14-RING (principal, vig, keep, PAPER, REACH), S14-COURT
   (LAWYERS, MENACE, PRISON, sentence()), S14-PACK and S14-ROBOT (GRIDS, SHAPES, prices).
3. The text pass (159, with 158): docs/TEXT.md is regenerated with all of S14's screens.
4. Grills waiting: 168 (hired help), 147 with 94 and 100, 136, 137, 96; 140's retune after
   play. Nothing buildable is left without a call from the dev.

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
