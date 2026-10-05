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
   screenshots here. (2026-10-04: the bare strip and broken back fence between gardens fixed
   at the root, see docs/TRIBAL.md; test_next_door.) (The strip of outside grass inside side fences: fixed in session 18.
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
   to see a little growth, leave again. Later: another door off the hub (2026-10-04 grill).

PROPOSED ORDER: superseded, see Notes 2026-10-05 (the hub redesign grill first). Still
waiting: 227 when the drawing comes; grills on 225, 207 with 136, 208.

### Notes 2026-10-04 (LOAD 3 played, S17 and S18 check fallout, two bugs)

Verdicts: S16-WINDOW, S16-BAY, S17-TERMS yes. S17-GAMBLE works okay (213 is its one gripe).
S17-PACE retired: the dev can't judge the day's speed until there's more than jobs in it;
ask again once help (209) or the hub exists. S17-EVENTS: played a little differently,
subtler than expected, fine.

211 to 216 built in session 21 (see CHECKS.txt S20-FIXES, S20-DIAL).

### Notes 2026-10-04b (LOADs 1 to 4 played, session 21's fallout, fence screenshots)

Verdicts: S19-LITTER passes (the sapling's sprite unclear, for the sprite pass, 137).
S16-ROBOT: might be too good, the dev will report it. S16-RIDEON: not answered as asked,
reframed into 225. S20-FIXES: the 6am start fine, the summary an improvement, the headline
unreadable (218); the dog and doors not commented (verified by test). S20-DIAL: doesn't
read (227). S21-CREW: the whole flow confusing (222).

225. [DESIGN, moderate] Upgrades as work on kit you own, not a shop list (the dev, on
   S16-RIDEON): money for parts and time for labour, e.g. a few hours one morning to fit
   the ride-on's gear. Direction in the design doc (Mowers and Equipment); details for a
   grill; fitting them yourself happens at the yard (the hub grill, 2026-10-04). 226 (nothing on the lawn does nothing) went to the doc too.
227. [VISUAL, moderate] The HUD clock face reads as a speedometer and is too small. The dev
   pictures Graveyard Keeper's: markers for when the window starts, rolling round to where
   it ends (a sunrise and a sunset). Waits on the dev's drawing. Home: hud.gd _draw_dial.

220, 222, 223, 224 and 217 grilled and built (228 to 234, session 24). 218, 219, 221 and 47
built in session 23.

### Notes 2026-10-05 (session 24's LOADs 1 and 2 played: the hub, the desk and the crew want another big pass)

Verdicts: S24-PAD nothing beyond the notes below. S24-RAISE retired (the dev raises it if it
plays wrong). S24-FENCE retired (the dev reports fences as seen, 194). The dev's overall
read: the hub as built doesn't feel good yet; 239 to 245 are one redesign, grill them together.

238. [VISUAL, large] The rooms don't read (S24-HUB): hollow, eerie, flat; nothing alive or
   interactable; doors neither open nor animate; the desk's placement looks alien. The dev
   isn't sure Claude should do this: they may make prototype visuals as guidance, or ask
   someone good at it. WAITS on that. Home: hub.gd (rooms built in code), tools/art_sprites.py
   group "hub". Joins 137 (the art pipeline). QUESTION: anything cheap meanwhile (doors that
   swing as you pass), or leave the rooms alone until the visuals come?
239. [DESIGN, large] The desk crams calendar, paper and client book into one place, and the
   calendar gives nothing but a way to skip a day (S24-CAL). Too much repeated or idle text:
   the date and time above a calendar that already shows the date, three money lines, the
   reputation line, the date a third time on the day panel. The bookings mix whole numbers
   and clock times. The dev's split, four things in the office, each its own interactable:
   a. Calendar and planning: bring back the number-line timeline. Pick a day, see its
      bookings beside the line; highlighting a job in the list lights it on the line;
      assign who goes from there.
   b. Newspaper and phone, together somewhere else in the office: how you ring people.
   c. Client book, on the desk: your regulars.
   d. Filing cabinet, by the desk: employees (stats, letting go; training later, out of
      scope).
   Home: board.gd (the desk), hub.gd (where the stations stand). The old timeline was the
   board's pre-228 day view (git history). Decides with 245 (what assigning means) and 241.
   238's look is separate: this decides what each station does, the look can follow.
240. [DESIGN, large] The paper doesn't read as a paper (S24-PAPER): "the worst webpage ever
   made", a white square, a centred title, left-aligned blocks. Wanted: it feels like you've
   picked up a real newspaper, with the parts that matter to you highlighted. Still menu-ish
   underneath: left/right at a page's edge or the shoulders turn the page, directions move
   focus between things worth acting on, A acts (rings, or whatever fits). Home: board.gd's
   paper pages. Leans on 238's visual direction for the page itself.
241. [FEATURE, moderate] Ending the day means walking to the office and picking it from a menu
   (S24-DAYEND). The dev's options, either or both: (a) a shopfront entrance on the office:
   trying to leave through it offers to end the day; (b) a pocket planner that travels with
   you, holding the things you'd otherwise walk back for: the day's plan, end the day.
   Home: hub.gd (doors), board.gd (the end-day path). QUESTION: (a), (b) or both?
242. [FEATURE, moderate] The day's end screen reads as sentences (S24-DAYEND, screenshot).
   Wanted: a list of cards, one per job, yours and the crew's in one list (lose the separate
   headings). Collapsed: the money change, who went, where. Expanded (A): the full job
   report. A summary card at the bottom tallies everything. The screenshot also shows a
   number that confuses: "Nigel: 1 job, $82" then "the crew +$9": $82 is what the customer
   paid, +$9 the net after fuel and the flowerbed's bill (game.gd help_job, r.paid vs
   r.net). A card's top line should be the net, the expanded view the pay, fuel and bill.
   Home: board.gd _day_end (~860 to 930), game.gd end_day's day_end dict (has what's needed
   for crew jobs; day_mine has net, outcome, mood for yours).
243. [DESIGN, large] Storage (S24-YARD): a yellow box in a big room that you buy more of reads
   arbitrary, "Backrooms-esque". Wanted: the real space is the inventory. Start smaller (a
   shed, a lockup, a garage): the truck and the mower go in it and it gets tight; grow by
   paying for a bigger place, not more squares. First hit the ceiling only via cheats (a
   second van and a ride-on a few weeks in). Placement always looked wrong (see 244).
   Supersedes the yard's +4 rows (hub.gd, game.gd yard rows) and folds in 237 (arranging by
   hand). QUESTION for the grill: in a tight space, do you place things yourself (237 yes) or
   does it still auto-pack?
244. [VISUAL, moderate] The new vans and many new assets are weirdly narrow and feel
   two-dimensional (S24-YARD). Home: tools/art_sprites.py group "hub" (8 sprites, session
   24), tools/voxel.py for anything that turns. Goes with 238.
245. [DESIGN, large] The crew UX, blank slate (S24-CREW, screenshot: a van's card offering
   "Nigel steps out of the van / Let Nigel go (the van stays) / Put the crew's petrol mower
   in it / Sell the van, $200 (Nigel steps out)"). The dev: "This UX is insane"; rebuild it
   as if from scratch. There's a roster of employees, there's equipment, and there are jobs
   that employees, with equipment, go to. No menu of every combination of who and what
   stays or goes: simple, sensible defaults. Undoes the session 24 "three things, each
   removable alone" cards (d41fa63) as UI; the model (helpers, vans, mowers separate) may
   stay underneath. Home: hub.gd card builders (~600 to 700), game.gd helpers/vans. Decides
   with 239d (the filing cabinet is the roster) and 239a (assigning on the calendar).
246. [BUG, small] "Back ((B))" on the hub's cards: hub.gd:672 wraps Game.key("hop") in
   parens, and key() already adds them (game.gd:371). Drop the outer parens; grep for other
   "(%s)" % Game.key callers.
247. [BUG, small] On Fridays the day panel's text (the payday line) doesn't wrap, so the panel
   grows and squeezes the calendar (CHECKS NOTES). Home: board.gd's day panel; set autowrap
   and a fixed width. Moot if 239 rebuilds the panel, so fix only if 239 waits.

PROPOSED ORDER: one grill for 245, 239, 241, 242, 243 and 240 (in that order: the crew model
decides what the filing cabinet and assigning are, which shapes the stations, the day's end
cards and storage), then build in the same order; 246 rides with the first build. 238 and
244 wait on the dev's visuals; 240's page look too.

### Grilled 2026-10-04c (the hub: 217, 220, 222, 223, 224, S14-CAL, S23-RAISE)

Decided in the design doc (Outside the Season, The hub; The Business, Hired help, Growth
pace). S23-PAD: left and right fine; the Calendar's ad button sits far right, so down from
the tabs drops past it (moot once 230 and 231 replace the page). 228 to 234 built in session 24 (CHECKS.txt
LOADs 1 and 2); Claude's calls in the doc's "As built". Left from it:

235. [DESIGN, small] The phone has nothing of its own yet: ringing stays on the paper's ads
   and situations wanted. The dev listed it with the paper and the client book. Build it
   when something wants ringing that isn't an ad (a regular to move a visit, the shark?).
237. [DESIGN, small] Arranging the yard by hand: open (the dev, 2026-10-04: "not fully
   convinced we won't want to"). Auto-placed is biggest first, so free-looking cells may not
   take a van: S24-YARD asks whether that reads wrong. (2026-10-05: it did; folded into 243.)

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
