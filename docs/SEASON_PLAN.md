# Season prototype: build plan

For NOTES 162 to 166 (the design: `../game-dev/Super Landscaper.md`, The Business and
Season Prototype). Delete this file once the prototype is built; what's learned goes to
TRIBAL.md.

## What exists, and what changes

- `game.gd` (autoload Game) holds the run: `money`, `reputation`/`rep_trend`, kit,
  `heat`, `week`, `jobs_done`, `PAYMENTS`, `JOBS_PER_WEEK`, `job_of_week()`,
  `payday_due()`, `payment()`, `settle_payday()` (repossession, "won"/"bankrupt"),
  `make_offers()` / `make_job(seed)` (a job is plain data from one seed),
  `record_result()` (money, rep drift, tallies, best score saved to `save_path`).
  Changes: `week`/`jobs_done`/`PAYMENTS` give way to a date, a principal and a vig; new
  state for regulars and bookings; a save file for all of it.
- `board.gd` is the board: header, classifieds (left), mowers and upgrades (right), and
  the payday and run-over screens. Changes: the classifieds column becomes the calendar;
  payday gains the vig, the living cost and the paper; run-over becomes the winter stub.
- `summary.gd` is the post-job screen (the two books). Changes: the regular's offer and
  the haggle, right after it.
- `customer.gd` starts every job at `mood := 60.0`. Changes: a regular starts at their
  carried mood.
- `main.gd` builds the garden from `Game.job()` by seed (`job.seed + n` per part), so a
  kept job dict rebuilds the same garden. Changes: the dead stay dead (no dog, or a new
  one), one drift prop per visit, no tip for a regular.
- `title.gd`: Start becomes Continue / New business.
- Tests to rewrite: `test_season.gd` (payday), `test_run_flow.gd` (the whole loop).
  Everything else is in-job and shouldn't move.

## Build order (each step ends green on run_all)

1. **Dates and the vig (162).** `day` as a date from 1 April (Godot's `Time` gives
   weekdays); Friday is payday: the vig on `principal` plus the living cost, and any
   extra paid cuts the principal. Repossession as now. At zero, free of him. Empty days
   skip. Test: a month of empty days runs the vig and living cost correctly; overpaying
   cuts the principal; short means repossession; paid off means no more vig.
2. **The weekly paper (163).** At payday, the coming week's ads (count and quality by
   reputation, as `offer_count`/`make_job`) to book into free days. The calendar shows
   the month: each day empty, an ad booked, or a regular. The day's job is played; a
   day with nothing skips. Test: booking fills a day; an unbooked ad is gone next week.
3. **Regulars (164).** After a good classifieds job, the hidden chance and the offer
   (accept / decline / haggle), a cadence placed on free days (a clash shifts a day),
   carried mood, the floor that cancels, dropping one, no tip. The garden by its seed,
   the dead staying dead, one drift prop. Test: an offer accepted books the cadence
   round a busy week; a bad visit below the floor cancels; the mood carries.
4. **The save (165).** One file per business (`FileAccess.store_var`, which keeps
   dictionaries, arrays and Vector2i as they are), written between days; the job in
   progress flagged, and loading onto the flag gives the blackout. Continue / New
   business on the title. Test: save, load, same state; a flagged job loads as the
   blackout.
5. **The winter stub (166).** September's last day: the living cost for October to
   March, who comes back (a chance by carried mood), then April. Test: the ledger adds up.

## First numbers (guesses, not measured; play decides)

- Principal $1,000; the vig 10% a week (so $100 at the start); living $50 a week.
  Against: three small classifieds a week at about $70 each.
- Classifieds pay as now, with tips; regulars pay the agreed rate, no tip.
- An offer: chance about (end mood - 60) / 40, times a persona factor (the busy one
  high, the fusspot low). Cadence by persona: weekly, fortnightly or monthly.
- The haggle: ask 20% more; the better their mood, the likelier yes; near the edge, yes
  but carried mood -10; past it, they walk.
- Carried mood: the next visit starts halfway between 60 and how the last one ended.
  The floor: a visit ending under 35 cancels.
- Season starts in April by default; a knob to start in June for play-checks.

## Decided by the dev (2026-09-29)

1. The calendar is a month grid.
2. Every day is workable, Sundays included: up to one job a day.
3. The calendar starts in April 1980.
