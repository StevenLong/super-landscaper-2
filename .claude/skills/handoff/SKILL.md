---
name: handoff
description: Wrap up a Super Landscaper session, write the HANDOFF.md session entry, update the owed-checks ledger, sort NOTES.md (promote decided design items to the design doc), verify, then commit and push. Use when the user says "handoff", "wrap up", "end the session", "let's stop here", or asks for session notes.
---

# Handoff (session wrap)

HANDOFF.md carries what git cannot: decisions, verdicts, and what comes next; CHECKS.txt
carries the owed play-checks.
A SessionStart hook injects its ledger and latest session into the next session on either
machine, so an entry that drops an owed check or records an unverified pass misleads the
next session.

## 1. Gather
- This session's commits: `git log --oneline <last handoff commit>..`, or the whole history
  if HANDOFF.md has no session entries yet.
- From the conversation: decisions made (and why), checks the dev confirmed, new checks this
  session's work created, and threads left open.

## 2. Verify
Run `bash tests/run_all.sh` (parse check, smoke test, and every test; see Verify in
CLAUDE.md). A failure gets fixed, or recorded as failing; do not write a passing entry over
it.

## 3. Write the session entry
Add it at the top of the session list, below the ledger block.
- Header: `## Session N (YYYY-MM-DD): <headline>`, N = previous top session + 1 (or 1).
- Short bullets. Record what git does not: decisions and their reasons, check verdicts,
  anything half-done, and how the work was verified (parse clean, dev-confirmed, unchecked).
  Do not restate the commit list; cite a hash where it helps.
- End with OWED CHECKS (a count, pointing at CHECKS.txt) and NEXT (a proposed order).
- Plain hyphens only, no em or en dashes.

## 4. Maintain the ledger (CHECKS.txt)
`CHECKS.txt` is the owed-checks ledger and the file the dev fills in. A SessionStart hook
(`.claude/hooks/open_checks.sh`) opens it in Notepad whenever any `>` answer line is blank.
- Read answers first: only the `>` lines are answers. Read every one before saying what
  passed; a vague "all good" elsewhere does not clear a check.
- Remove answered checks (the session entry records the verdict). Leave unanswered ones.
- Add new checks grouped by what the dev loads (not by session): a `LOAD n of m` header
  with a rough time, then per check a short ID (`S2-THROW`), one observable, and a line
  that is exactly `>`. Never pre-fill the `>` line.
- Nothing owed: replace the body with "Nothing owed." and no `>` lines, so the hook stays shut.
- If a check has rolled for 3+ sessions, tell the dev rather than rolling it again.

## 5. Sort NOTES.md (the task list)
Without a set point, ideas pile up in NOTES.md forever. This is the set point.
- DONE items: delete them once the session entry records them.
- Every DESIGN item goes into exactly one state:
  - **Decided**: the dev stated the call in conversation. Fold it into
    `../game-dev/Super Landscaper.md` (right section, as a decision not a transcript), delete
    it from NOTES.md, and list what was promoted in the session entry so the dev can veto.
    Your own proposal the dev didn't answer is not decided.
  - **Needs a grill**: it stays. When about three are waiting, or one blocks the next build,
    NEXT proposes a `/grill` session on them (name the items).
  - **Parked**: it stays, tagged `[PARKED since YYYY-MM-DD]`. Parked 5+ sessions: ask the dev
    once, keep or drop, and act on the answer.
- Commit and push game-dev too if anything was promoted.

## 6. Trim
Keep about 8 sessions. Delete older entries; git history keeps them.

## 7. Commit and push
HANDOFF.md, CHECKS.txt and anything uncommitted. No Co-Authored-By trailer. Write the message with a
Bash heredoc or `git commit -F <file>` (PowerShell here-strings split messages containing
double quotes). Confirm the push landed. If the session changed the design, check that
`../game-dev/Super Landscaper.md` was updated and pushed, and flag it if not.

## 8. Report
Two lines on what shipped and what's NEXT, and how many checks are owed in CHECKS.txt.
Close with a one-line offer to clear context, unless verify failed, the push failed, or a
thread is half-finished; then say why the seam is not clean instead.
