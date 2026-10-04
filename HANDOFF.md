# Handoff

## Owed checks (rolling ledger)
The ledger lives in `CHECKS.txt` (answer on the `>` lines). A SessionStart hook opens it in
Notepad whenever an answer is still blank.

Verifier tally (the adversarial agent, scored by /handoff): 7 runs, 47 real finds (1 of them
a regression of mine it caught before the dev did), 0 false alarms, 0 misses so far. Cost
per run: about 95k to 240k tokens, 9 to 20 minutes.

---

## Session 21 (2026-10-04): solo, the small batch, the clock face, hired help slice 1
- **Built 211 to 216**: the dog keeps its side of the house fetching, and a dog put down
  past it runs back round (never through); a back-patio house's front door can be knocked
  (they answer it, go back in, come out the back later); the day from 6am, no window before
  8am (every job's window unchanged); the reputation book shows gains already cut, no minus
  line; the day's news a headline on the paper's page; a clock face in the job's HUD.
- **Built 209, hired help slice 1**: situations wanted at the back of the paper, vans and
  crew mowers in the shop, a Crew page (helpers, kit, raises, who goes, their day's report),
  the helper's day at the day's end on your clock's rules, wages at payday, the winter
  layoff. My calls (veto any) are in the design doc, Hired help, "Slice 1 as built"; the
  big one: **the wage scales with your name** (about $1,000 a week for a good helper at a
  Fair name), because job pay does; 193d's inflation makes that look odd beside $50 rent.
- **Tuned by sim**: new tests/sim_crew.gd (fully booked, a helper brings in 2 to 3 times
  the wage); sim_season gained SIM_CREW=n (its bot's overflow keeps each helper on 5 to 8
  jobs a week, about break-even; missed regular visits fall from 28 a month to 5).
  Modelled, not played.
- **Verifier run 7** (154k tokens, 11 minutes): 9 real finds, all fixed in 60c3c2c. The
  crew's day accepted your own pending offer and left a set-off time on regulars it won
  (later visits became no-shows); a thrown dog still snapped through the house; the Crew
  page overflowed with 5+ helpers; a sent booking couldn't be taken back once unreachable;
  a crew-only day said "Nothing booked"; the paper's heading ignored the wanted column; an
  old save had no situations wanted; a quit-on-summary offer resurfaced later (older bug).
- Verified: run_all green, 47 PASS lines (new test_doors, test_dial, test_help,
  test_crew_board); screenshots looked at for each screen changed.
- Rolling: S16-RIDEON and S16-ROBOT have been owed since session 16. Play them or drop them;
  robot tiers (210) wait on S16-ROBOT.

OWED CHECKS: 6, in CHECKS.txt (4 loads, about 55 minutes).

NEXT:
1. Play LOADs 1 to 4, LOAD 4 (hired help) first if short of time.
2. 210 (help slice 2, robot tiers) once S16-ROBOT and S21-CREW are answered.
3. A grill on the office/hub (217, 208, S14-CAL, 47): three or more items wait on it.

## Session 20 (2026-10-04): help and robots grilled, LOAD 3 played and triaged
- **Grilled 168 with 189** (the dev's calls, all in the design doc, The Business, Hired
  help, and the robot mowers bullet, rejected options listed): helpers are sent out alone
  to jobs off screen; ability plus kit (kit from what you own, more than one of a mower);
  they grow, carried over the winter; a weekly wage at payday; your name counts, not your
  record (a crime loses you the helper); found in the paper's "situations wanted"; tuned
  so a busy helper brings in about twice their wage; a van each; some regulars want you,
  by persona, always shown (the dev: never silently punish a reasonable choice). Robots:
  time savers in a job and kit for helpers, permanent tiers. Filed as 209 (slice 1) and
  210 (slice 2). My calls, veto: helpers keep your clock exactly; an evening report.
- **LOAD 3 played**: S16-WINDOW, S16-BAY, S17-TERMS yes; S17-GAMBLE works okay; S17-EVENTS
  fine, subtler than expected; S17-PACE retired till the day has more in it. Triaged into
  NOTES 211 to 217: the dog runs through the house and teleports back (diagnosed, BLOCKS);
  only the back door can be knocked on back-patio houses; the day from 6am, no window
  before 8am (the dev's call); the reputation book's cut shown as a smaller gain, not a
  minus line (1a); a clock face in the job's HUD (2a); the event news on the paper's page
  (3a); a real newspaper and the board's redesign to the office/hub grill.
- 193d's lever still open: LOAD 3 didn't settle it (the dev wants more in the day first).
- Verified: run_all green (43 PASS lines). No code changed since faeaa10.

OWED CHECKS: 3, in CHECKS.txt (2 loads, about 25 minutes).

NEXT:
1. 211 and 212 (the bugs), then 213, 214, 216 as one small batch.
2. 215, the clock face in the job.
3. 209, hired help slice 1 (board UI the bulk; reuse tests/sim_season.gd's job model).

## Session 19 (2026-10-03): solo, the economy measured, litter, hoops and a sapling
- No dev at the keyboard again: worked what needs no play or call. Nothing in CHECKS
  answered, so nothing cleared.
- **193d measured, not retuned** (d802275): new `tests/sim_season.gd` runs seasons through
  Game with each job's result modelled. What it says is in NOTES 193d: regulars decide
  everything, and offers need an end mood over 60 (a MOOD 75 player has 20 regulars and
  $31k a month by July, a MOOD 55 player 2 or 3 and $2k to $4k); money is tight for about
  three weeks, then piles up with nothing to buy ($1M in about 3 seasons for a strong
  player); time is scarce in summer only with regulars (the paper alone can't fill a day);
  fuel eats 25 to 90% of pay, the ride-on's about a small lawn's pay. It flatters income
  (every job meets its target). No numbers changed: which lever is the dev's call, with
  LOAD 3. It also prices 189/168: a good player's money is $20k to $40k a month.
- **79b, part** (5870f62, cb9a0ea): litter (a third of gardens, minded only if seen
  shredded, never found later, binned for a tally), croquet hoops on the manor (4 to 6),
  a staked sapling (a quarter of gardens) that snaps if rammed over 110 (theirs). My calls,
  veto any. New check S19-LITTER. Left in 79b: medium shoved things, pools, darts, fire.
- **194 and 155 tried**: whole-garden screenshots of 3 seeds per plot showed no fence
  breaks; the briefing is centred at 4 window sizes (155 still wants a screenshot).
- **Verifier, run 6** (on the whole batch): claims held, 4 real finds, all fixed (a37dbac):
  the new props shifted rocks and the dog's ball in existing gardens (now placed last on
  their own draws, tested); TEXT.md stale again; the sim's header and NOTES ranges off.
  Not changed: a ride-on in first gear (90) stops dead on a sapling without snapping it;
  a snapped stump still blocks critters within 8 px (harmless). About 106k tokens, 10 min.
- Verified: run_all green (parse, smoke, 40 tests, 42 PASS lines). Screenshots looked at:
  18 whole gardens, the briefing at 4 sizes, litter and a hoop at play zoom, a sapling
  before and after a scripted drive into it.
- After the wrap, the dev: 155 was the camera, not the panel (paused under the briefing,
  it sat where the mower stood in the scene file, then jumped to you). Fixed with a test
  (test_camera). S15-POLICE dropped (the dev will raise the siren again if it's too loud).

OWED CHECKS: 12, in CHECKS.txt (3 loads, about 55 minutes; LOAD 3 is the clock).

NEXT:
1. Play LOAD 3 (the clock, terms, event days, the slower climb); LOAD 1 and 2 when there's time.
2. Pick 193d's lever from the sim and play: pay, PAPER_SIZE, the offer's mood threshold,
   fuel, or pricing 189/168 at this scale.
3. Grill 189 (robots) and 168 (hired help) together, as ways to buy time; then 207 with 136.

## Session 18 (2026-10-03): solo, S15-FENCE settled, the name builds slowly
- No dev at the keyboard: worked what needs no play or call. Pulled clean; nothing in
  CHECKS answered, so nothing cleared.
- **S15-FENCE settled without play** (8a90f9e): new test_reach shows every lawn cell on
  every plot is in reach of every mower (boundary and next door's corner only; solid things
  not modelled). But side fences stood mid-way through their 24 px strip, so 8 to 9 px of
  next door's long grass showed inside them and looked uncut: the dev's strip, almost
  certainly. Side runs now stand on the lawn's edge. NOTES 194's strip note closed.
- **193d, reputation's climb** (36c721a), from the dev's "it shouldn't saturate so early":
  a job's gains are cut by (1 - trend/100) squared, losses whole. Simulated: great jobs
  reach the top band after about 20 (was 3), typical play about 34, 90 after about 80.
  Claude's call, in the design doc as built, veto any. The cost: fired at 80, about 24
  great jobs to win back; near the top a great job with a small mishap nets a loss. New
  check S18-CLIMB. The rest of 193d waits for play.
- **Verifier, run 5** (on both): claims held, 5 real finds, all fixed (864dbc1, the fixes
  commit): losses inside a good job were cut with its gains; the standing line promised
  "the rest later" when bad word was arriving; a declined offer's +2 was unscaled; the cut
  line sat above the noticed lines; a road-fence run shorter than its tile overhung a
  terrace's drive mouth. Not changed: a winter's drift from 85 takes about 21 great jobs
  to win back (with the 193d retunes). About 120k tokens, 20 minutes.
- Verified: run_all green (parse, smoke, 40 tests). Screenshots looked at: L corners
  (fence and fence, fence and hedge, hedge and fence) before and after, a fenced rect, a
  terrace and the churchyard's corners, the summary's reputation book, a terrace's mouth.
- S15-POLICE has now rolled three sessions (the siren's loudness): play it or drop it.

OWED CHECKS: 12, in CHECKS.txt (3 loads, about 55 minutes; LOAD 3 is the clock).

NEXT:
1. Play LOAD 3 (the clock, terms, event days, the slower climb); LOAD 1 and 2 when there's time.
2. 193d's other retunes from what play says (the paper's size, REACH, pay, the vig, the clock).
3. Grill 189 (robots) and 168 (hired help) together, as ways to buy time; then 207 with 136.

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
