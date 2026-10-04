# Notes (task list)

Triaged dev notes. Each item: tag, size, the note, root cause or home file, FIX sketch,
open QUESTION. Numbers are stable (done items are deleted, not renumbered). `/handoff`
sorts this file: done items go, decided design items move to
`../game-dev/Super Landscaper.md`, the rest wait for a grill or sit parked with a date.

Tags: BUG / FEATURE / VISUAL / DESIGN (needs a call before building) / PARKED.
BLOCKS = spoils the next playtest.

### Build (no design call needed)

62b. [FEATURE, small] Leftover thoughts from ramming the car (not decided): a direct hit
   shoves the car a little; dents show on the sprite.
75b. [FEATURE, large] Venues, what's left after the manor and churchyard: the golf course (its
   own grill: 18 holes as separate jobs?); community service
   (a tier 2 arrest's lost slot becomes a forced unpaid job, needs a litter-pick or prison
   venue); the week-4 finale (open in the design doc).
79b. [FEATURE, moderate] Objects, later batches (design doc Mowers and Equipment): medium
   things shoved by heavy mowers (RigidBody2D: chairs, parasols, a sandbox rim), sandbox,
   paddling pools, lawn darts, more critters and their interactions (cats, birds, rats,
   pond fish), fire. Litter, croquet hoops and the sapling built in session 19 (S19-LITTER).

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

### Open after session 16 (2026-10-02; what's left of the S13 to S15 fallout)

193. Grilled 2026-10-02: time is the scarce thing (design doc, The Business). 193a to 193c built in session 17; left:
193d. Retunes after 193a (mine, measured): reputation's climb done in session 18 (gains
   scaled by how known you are, design doc Reputation; the top band after about 20 great
   jobs, was 3; S18-CLIMB asks how it plays). Left: PAPER's count by
   month; REACH and the bars (S14-RING: steps of 0, 20, 55, 75); the vig; pay; the clock
   rate. Today a manor pays about $790 against a $150 week.
   MEASURED (session 19, new `tests/sim_season.gd`: a bot books and plays seasons through
   the real Game code; mowing times and moods are modelled, so trust the shape, not the
   dollars). Means over 5 seeds, mowing at 0.85 of sim_balance's bot times, each job's end
   mood MOOD give or take 15:
   - Everything hinges on regulars, and offers need an end mood over 60. MOOD 75: 13
     regulars by May, 20 by July; paid $15k in May, $31k in July; $101k cash at the first
     winter, $354k at the second. MOOD 65: 6, then 11; $9k, $20k; $48k, $115k. MOOD 55:
     2 or 3 regulars (4 or 5 in the second season); $2k to $4k a month; $1.4k at the
     winter, $1.9k at the second (the heavies take the ride-on now and then).
   - Money is tight for about three weeks: at MOOD 65 or 75 the debt's gone by early May,
     nearly all the kit ($1,500 in all) bought by May, then cash piles up with nothing to buy. The
     $1M target is about 3 seasons at MOOD 75. So money's use (189 robots, 168 help) wants
     pricing against $20k to $40k a month for a good player, not $150.
   - Time: at MOOD 75 days run 60 to 70% full from June and 90 to 135 ads a month are
     turned away for want of room (the squeeze works); at MOOD 55 days stay 16 to 30% full
     and nothing is turned away (the paper alone, 5 to 10 ads a week, can't fill a day:
     PAPER_SIZE). Regular visits missed (placed however busy): 5 to 10 a month at MOOD 75.
   - Fuel eats 25 to 90% of pay (the most at MOOD 55 in summer, on the ride-on): the ride-on burns about $70 of fuel on a small lawn that
     pays about $70 (1.5 a second, the first tank free), petrol about $40. On small lawns
     the push mower nets the most, if it fits the window (its time is a guess: the bot
     never reached 85% with it).
   The sim flatters income (every job meets its target; the ride-on's manor time is a
   guess), so MOOD 75's dollars are the least trustworthy; the verifier (run 6) re-ran and
   matched the core numbers. No numbers changed: which lever (pay, PAPER_SIZE, the offer's mood threshold, fuel) is
   the dev's call, with LOAD 3's play. Help and robots are now priced by 209/210 (a busy
   helper about twice their wage, 2026-10-04 grill), which may make some of these moot.
194. [VISUAL, moderate] Fences and walls: more broken bits to come as the dev plays. Collect
   screenshots here. (The strip of outside grass inside side fences: fixed in session 18.
   Session 19's sweep of 18 whole gardens found nothing new.)
206. [DESIGN, small] The horn (199, built): does using it a lot annoy the customer? The dev
   was unsure; left out for now.
207. [DESIGN, large] Taking things from gardens pays (the dev, 2026-10-02, during the 193
   grill): a critter or an ornament taken has a use, sold (the hedgehog dealer, 136) or set
   in your own garden, even furniture lifted piece by piece over a regular's visits while
   they aren't looking. Needs a minimal market so hoarding one thing can't become the best
   move (hedgehog numbers up, price down). CONFLICT to settle: the doc's "afterwards,
   ownership decides" rule finds a missing gnome after you leave; the dev's lean is unseen
   means never known for ordinary things (a gnome, a flamingo, flowers), a chance they
   notice at most, and the dog always noticed. Grill with 136.
208. [DESIGN, large] Your own garden (the dev, 2026-10-02, during the 193 grill; a soft
   opinion): nothing takes time while you're in it, the day moves only when you leave.
   Seeds got on a job or elsewhere, planted there, grow over several days: leave, come back
   to see a little growth, leave again. For the hub grill.
Also: S14-CAL, the board reads but will be redone when things split out (no item).

PROPOSED ORDER: see Notes 2026-10-04b (the office/hub grill).

### Notes 2026-10-04 (LOAD 3 played, S17 and S18 check fallout, two bugs)

Verdicts: S16-WINDOW, S16-BAY, S17-TERMS yes. S17-GAMBLE works okay (213 is its one gripe).
S17-PACE retired: the dev can't judge the day's speed until there's more than jobs in it;
ask again once help (209) or the hub exists. S17-EVENTS: played a little differently,
subtler than expected, fine.

217. [DESIGN, large] An actual newspaper (the dev): the game keeps saying "the paper" but
   there's no paper, just a tab and things that look like ads. With S17-BOARD (hard to
   read at first, too much in one place; no change now, it gets redone with real places)
   this goes to the office/hub grill (with 208).

211 to 216 built in session 21 (see CHECKS.txt S20-FIXES, S20-DIAL).

### Notes 2026-10-04b (LOADs 1 to 4 played, session 21's fallout, fence screenshots)

Verdicts: S19-LITTER passes (the sapling's sprite unclear, for the sprite pass, 137).
S16-ROBOT: might be too good, the dev will report it. S16-RIDEON: not answered as asked,
reframed into 225. S20-FIXES: the 6am start fine, the summary an improvement, the headline
unreadable (218); the dog and doors not commented (verified by test). S20-DIAL: doesn't
read (227). S21-CREW: the whole flow confusing (222).

220. [DESIGN, large] Everything outside the mowing is overwhelming, confusing and doesn't
   operate smoothly (the dev). For the office/hub grill with 217, 208 and S14-CAL.
222. [DESIGN, large] The crew flow needs rethinking (S21-CREW): the results are hidden (hard
   to notice; the report runs off the bottom and a pad can't scroll to it, since only
   buttons take focus); equipping went unnoticed (a Kit toggle); assigning is a wall of jobs
   each toggled through names. Also "they asked for money after the first day": a raise
   ask, diagnosed: wage_for uses your reputation now, so as your name climbs (50 to 70 in
   days) every helper soon asks. Fixed in session 23: priced on your name when they
   answered the ad, raises by growth only. But growth alone still earns an ask after about
   4 to 6 jobs (modelled, GROW 0.01 a job, RAISE_AT 1.15), so a busy helper asks within 2 or
   3 days: QUESTION (balance) in CHECKS S23-RAISE. Only three in the paper: 1 to 3 a week,
   by design. For the hub grill.
223. [DESIGN, moderate] The shop (inventory): a growing list of buttons doesn't scale, and
   it doesn't scroll down (on a pad: follow_focus only follows a focused button). For the
   hub grill.
224. [VISUAL, moderate] The board's day clock is hard to read: where now is, whether you're
   missing something, whether a booking has already started. Home: board.gd DayClock.
   For the hub grill, unless a quick pass is wanted first.
225. [DESIGN, moderate] Upgrades as work on kit you own, not a shop list (the dev, on
   S16-RIDEON): money for parts and time for labour, e.g. a few hours one morning to fit
   the ride-on's gear. Direction in the design doc (Mowers and Equipment); details for a
   grill (with 223). 226 (nothing on the lawn does nothing) went to the doc too.
227. [VISUAL, moderate] The HUD clock face reads as a speedometer and is too small. The dev
   pictures Graveyard Keeper's: markers for when the window starts, rolling round to where
   it ends (a sunrise and a sunset). Waits on the dev's drawing. Home: hud.gd _draw_dial.

PROPOSED ORDER: the office/hub grill (220, 222, 223, 224, 225 with 217, 208, S14-CAL), then
227 once the drawing comes. 218, 219, 221 and 47 built in session 23.

### Grilled 2026-10-04 (168 hired help with 189 robots: ways to buy time)

Decided in the design doc (The Business, Hired help; Mowers and Equipment, robot mowers).

209 (hired help, slice 1) built in session 21: S21-CREW; Claude's calls in the design doc, Hired help, "Slice 1 as built".
210. [FEATURE, large] Hired help slice 2 and robots: a helper nicked or sacked over a
   crime, quitting and poaching when underpaid, robot tiers (a cheap stop-for-everything
   one, a dear faster one that goes round critters), robots lent to helpers as kit,
   packing a helper's van, quirks. Robots measured slow (two take 8 minutes to cut 85% of
   a small lawn): price the tiers with the sim's scale.
168b. Later layers on record in the doc (from the 160 grill): upfront pay and raises,
   evidence surfacing, the off-season events, selling up, the front page, referrals, wear
   and overheads.

### Grilled 2026-09-29 (160: the season calendar, regular clients)

Decided in the design doc (Direction, The Business, Season Prototype). The game is now a
small business across seasons, not a roguelite run. 162 to 166 (the season prototype) and
167 (the record) were built in session 14; the rest wait.


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
