---
name: handoff
description: Wrap up a Super Landscaper session, write the HANDOFF.md session entry, update the owed-checks ledger, verify, then commit and push. Use when the user says "handoff", "wrap up", "end the session", "let's stop here", or asks for session notes.
---

# Handoff (session wrap)

The session record IS the continuity between machines and sessions. A handoff that
drops an owed check or records unverified green is worse than none.

## 1. Gather
- This session's commits: `git log --oneline <last handoff commit>..`. No prior session
  entry in HANDOFF.md yet (first-ever handoff)? There is no anchor, so use the whole
  history (`git log --oneline`) instead of failing or guessing a range.
- From the conversation: what was BUILT / FIXED / CONFIRMED / DECIDED, which owed checks
  the dev confirmed, and what new ones this session's work created.

## 2. Verify before recording
This is a Godot project. Once `project.godot` exists, run the headless parse check from
the repo root (godot exits 0 even on errors, so grep):
`"$GODOT" --headless --editor --quit 2>&1 | grep -E "SCRIPT ERROR|Parse Error|SHADER ERROR"`
No output = clean. It catches ERRORS, not GDScript warnings: never report "parse clean"
as "no warnings". Before `project.godot` exists there is nothing to run; say so in the entry.
If regression tests are added later, add their command here.
A red result gets FIXED or RECORDED AS RED; never write a green handoff over it.

## 3. Write the session entry
At the top of the session list in HANDOFF.md, directly below the ledger block:
- Numbering: previous top session + 1, or **Session 1** if there are no prior entries.
  Header: `## Session N (YYYY-MM-DD): <headline>`.
- House style: short bullets, one per work item, commit hashes inline, verification
  stated (parse clean, or dev-confirmed, or not checked). Plain hyphens only, never em
  or en dashes.
- Every entry ends with: OWED CHECKS (if any) and NEXT (a proposed order).

## 4. Maintain the ledger
The "## Owed checks (rolling ledger)" block at the top of HANDOFF.md holds things only
the dev can verify by playing (feel, readability, is the face funny, is the job tense):
- ADD an entry for each new owed check, tagged (SN): a short bold title, then `- [ ]`
  bullets, one observable each ("do X, watch Y"). Never a prose paragraph.
- DELETE bullets the dev confirmed this session (the session entry records the verdict).
- A broad pass ("all good") does NOT clear a multi-bullet entry. Read the bullets back
  and ask which were actually exercised; clear exactly those.
- If a check has survived 3+ sessions, say so to the dev instead of silently rolling it.

## 5. Archive
Keep about 8 sessions in HANDOFF.md. When a new one pushes an old one past that, move
the oldest session block to the top of the session list in HANDOFF_ARCHIVE.md (create
it with a `# Handoff archive` header if missing).

## 6. Commit and push
HANDOFF.md plus anything uncommitted. No Co-Authored-By trailer. Write the message via
the Bash tool with a heredoc or `git commit -F <file>` (a PowerShell here-string mangles
messages containing double quotes). Confirm the push succeeded: the other machine reads
this file. If the session changed the design, the vault doc
`../game-dev/Super Landscaper.md` needs its own edit and push; flag it if not done.

## 7. Report
What this session shipped and what NEXT is, in a couple of lines, then the FULL owed
checklist verbatim (the `- [ ]` bullets, not a summary).

## 8. Offer the context clear
Once the push lands, close with a ONE-LINE offer to clear context. Never clear it
yourself, never press. If step 2 came back red, the push failed, or a thread is
half-finished, say the seam is NOT clean and why instead of offering.
