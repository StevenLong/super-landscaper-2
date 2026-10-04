# Handoff

## Owed checks (rolling ledger)
The ledger lives in `CHECKS.txt` (answer on the `>` lines). A SessionStart hook opens it in
Notepad whenever an answer is still blank.

Verifier tally (the adversarial agent, scored by /handoff): 10 runs, 70 real finds (1 of them
a regression of mine it caught before the dev did), 0 false alarms, 0 misses so far. Cost
per run: about 95k to 240k tokens, 9 to 20 minutes.

---

## Session 24 (2026-10-04): the hub grilled and built (228 to 234), verifier run 9
- Dev's answers: S23-PAD yes, bar the Calendar's ad Ring being hard to reach (moot: that
  page is gone). S23-RAISE: "considerably slower"; the trouble was growing fast (cheats
  showed better hires), not asking. Plus a new ask: a "finish the day" beat (became 229).
- The hub grill (design doc, Outside the Season, The hub): tangible things live in space,
  paper things stay screens; office as home with doors; walkable office, yard and shop; the
  calendar is its tiles (rolling 5 weeks, a day panel, state in words and colour, who goes
  from a list); the paper a newspaper with a front page; a client book; the day's end every
  day, nothing skips; crew acts where their objects are (no Crew page); storage as a
  resource (the yard's floor, auto-placed for now, more bought); leaving is the truck; the
  shop a 30-minute drive; raises: growth a fifth, an ask only on a card point. The dev
  overturned two of my picks: the calendar's tiles over a second list, and all three
  places walkable (my "office walkable, yard and shop as screens" was the tabs in a room).
- Built 228 to 234 (5353157, 8f755a5, 3a48a91, bf41f09, then the verifier's fixes). New:
  hub.gd/hub.tscn, test_hub, tools/shot_hub.gd, 8 sprites in tools/art_sprites.py (group
  "hub"). Claude's calls in the doc's "As built" (yard 10 by 8, +4 rows at $300 then
  dearer; footprints in truck cells; upgrades on kit cards; the phone has nothing yet).
- Verifier run 9 (990995d..bf41f09): calendar and paper held, raises, day's end and the
  places refuted in part; 12 real finds, all fixed or decided: raise asks came in pairs (pace and care
  tick days apart; now only a pace point asks, care rides along), payday and the winter leaked into the next day's money, jobs lost
  to jail/court/the cells missing from the day's end, cheat [3]'s skipped jobs listed as
  missed, last season's tally on April's front page, an empty page headed Situations
  Wanted, selling a van from a helper's card let the last hire go, driving to the shop from
  jail, the overflow van on the signpost, a big crew pushing the day's end off screen (now a
  line a helper), vans hiding the walker (now see-through when you're behind). Decided, not
  fixed: letting a helper go (or losing them over the winter) can overflow the yard; their
  mower stands over the edge till sold. Unchecked: a front page with every tally key full
  pushes the page buttons off screen (not a realistic week).
- Verified: run_all green (49 PASS incl. the new test_hub); sim_season SIM_CREW=0/1/2 clean (one
  seed with 2 helpers bought yard); screenshots of every new screen looked at.
- Modelled, not played: a busy helper now asks about every 50 jobs (a pace point), 2 to 3
  weeks; reaching the top takes about a season.

- After the handoff, the dev: helpers, vans and crew mowers should be three things, each
  removable alone. Built (d41fa63) on Claude's picks the dev took: the mower is the van's,
  a vanless hire is paid and waits in the yard (tinted, its own card), hiring or buying a
  van seats someone waiting. Old saves' van counts become the fleet (test_help checks).
- Verifier run 10 (f5b2f83..d41fa63): the logic held (37 Game checks); 10 real finds in the
  UI, all fixed: the ride-on card sold the first van's ride-on, not its own (test_hub now
  checks); a disabled-looking-but-silent "put the ride-on in" with no room for the petrol;
  an engine ERROR every frame in the yard (get_child on a thing with no children, from
  run 9's see-through fix; run_all only greps SCRIPT ERROR, so it passed); a vanless helper
  listed on a push mower; "Going:" shown with nobody able to go; the shop's crew mower gated
  on helpers, not vans; buying a van didn't seat the one waiting; two identical empty-van
  buttons; standing helpers' tags smeared and the 9th past reach (now 4 to a row).

- The dev's crash: the pad's B on the desk (Step away) called get_viewport() after the
  scene change took the board out of the tree; the hub's interact had the same shape. Fixed,
  and test_hub now presses B. run_all fails on engine ERROR: lines too, which surfaced three
  hidden ones, fixed: UI.focus's deferred lambda holding a freed button (any quick rebuild),
  test_fallout's typed filter on freed critters, test_objects freeing a scene with calls
  queued. docs/TRIBAL.md has the scene-change lesson.

- Then, asked what else could go without the dev: 236 (vans hiding things): vans are placed
  first along the back, so kit never stands behind one (a 60-yard random sweep: none
  hidden); a van that would hide kit stays see-through as a safety net. Fading every van
  that covers another was tried and smeared a row of vans into ghosts: a van's roof and tag
  showing behind another reads as a car park. New test_pad walks 15 menu screens with the
  pad (summary, raise, up front, offer, day's end, payday twice, court, winter, the places'
  cards): all reached, no wrong-way jumps; a mutated copy proves it fails. It found nothing
  to fix. run_all also skips any "at exit" leak report, not just one wording.

OWED CHECKS: 8 (CHECKS.txt: LOAD 1 S24-HUB, S24-CAL, S24-PAPER, S24-DAYEND, S24-PAD;
LOAD 2 S24-YARD, S24-RAISE, S24-CREW).

NEXT:
1. The dev plays LOADs 1 and 2; triage the fallout.
2. 227 when the clock drawing arrives (it becomes the office's clock too).
3. Grill-ready: 225 (upgrades as work, at the yard) with 223's leftovers; 207 with 136; 208
   (your own garden, another door). Hold 210.

## Session 23 (2026-10-04): solo, 218, 219, 221 with 47, and the raise half of 222
- 218: the paper's headline is ink, no shadow (new test_newsprint; screenshot reads).
- 219: the fence corners were only on L plots: the side run on next door's side started a
  BORDER (24px) higher than at a plain back corner. Found by matching the dev's screenshots
  (plain grass beyond the run = next door's corner). test_shapes checks it.
- 221 and 47: measured every board page's pad left/right (a scratch script): the Shop's
  columns sent left/right up or down (Godot picks a button a pixel that way in a row far
  below), and Quit to the day button on the Calendar. Now left/right on the board only goes
  more sideways than up or down, within a row's height (UI.row_step); disabled buttons stay
  reachable, as up/down already allowed. test_controls checks every page. Measured on the
  board only: the summary's rows are unmeasured.
- 222, raise half: a helper's wage is priced on your name when they answered the ad, so
  only their growth asks for a raise (design doc line updated, game-dev da036e1). Growth
  alone still asks after 4 to 6 jobs (modelled, not played): S23-RAISE asks the dev.
- Verifier run 8 (f554ccb..dfa9ad3): 3 claims held (a 463-plot sweep of L corners, both
  sides, every style), 1 real find: an old save's helper hired at a name near 10 back-solved
  under the floor and asked for a raise at once; fixed (the floor moved to where the name is
  stored), its repro round-trips every case. The 221 work was after its range.
- Verified: run_all green, 48 PASS; sim_season SIM_CREW=1 runs clean.

OWED CHECKS: 2 (CHECKS.txt: S23-PAD, S23-RAISE).

NEXT:
1. The dev's answers to S23-PAD and S23-RAISE (a GROW/RAISE_AT change if wanted).
2. A /grill on the office/hub: 220, 222, 223, 224, 225 with 217, 208, S14-CAL. Hold 210.
3. 227 when the dev's clock drawing arrives.

## Session 22 (2026-10-04): LOADs 1 to 4 played and triaged, nothing built
- All six checks answered. S19-LITTER passes (the sapling's sprite unclear, for the sprite
  pass). S16-ROBOT: maybe too good, the dev will report it. S16-RIDEON reframed: upgrades
  should be work on kit you own (parts and labour), not a shop list. S20-FIXES: the 6am
  start fine, the summary better, the paper's headline unreadable (a drop shadow on
  newsprint). S20-DIAL: reads as a speedometer, too small; the dev will draw what they
  picture (Graveyard Keeper's sunrise and sunset markers). S21-CREW: the whole flow is
  confusing (results hidden and unscrollable on a pad, kit unnoticed, a wall of toggles).
- The dev's verdict on the board as a whole: overwhelming, confusing, not smooth; pad
  left/right misbehaves. Every menu note points at one redesign: the office/hub grill.
- Triaged into NOTES 218 to 227 (fence corners from the dev's screenshots: 219, cause
  suspected, not run). Diagnosed in passing: helpers ask for raises within days because
  wage_for uses your current reputation (222).
- Promoted to the design doc (veto): nothing on the lawn does nothing (226); upgrades as
  work on owned kit, direction only (225).
- Verified: run_all green, 47 PASS lines; no code changed.

OWED CHECKS: none (CHECKS.txt says so).

NEXT:
1. 218 (the headline's shadow) and 219 (fence corners): small bugs, one batch.
2. A /grill on the office/hub: 220, 222, 223, 224, 225 with 217, 208, S14-CAL, 47 (221 checked
   against it). Hold 210 (help slice 2, robot tiers) until the crew flow is redesigned.
3. 227 when the dev's clock drawing arrives.

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
