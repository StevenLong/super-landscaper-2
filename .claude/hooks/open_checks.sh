#!/usr/bin/env bash
# SessionStart: if play-checks are owed, open CHECKS.txt in Notepad so the dev can fill
# it in without hunting for it. Ported from the cube repo, where it worked well.
#
# OWED = an answer line that is still blank (a line that is just ">"). An empty ledger
# still has the file, just no blank answer lines, so it stays shut.
#
# Never fails a session: every path exits 0, and no output when nothing is owed.

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
[ -f CHECKS.txt ] || exit 0

# Only a real startup or a post-handoff clear should pop a window; resume and compact
# are mid-flow.
src="$(cat 2>/dev/null | tr -d ' \n' | sed -n 's/.*"source":"\([a-z]*\)".*/\1/p')"

owed="$(grep -c '^> *$' CHECKS.txt 2>/dev/null || echo 0)"
[ "$owed" -gt 0 ] 2>/dev/null || exit 0

echo "=== PLAY CHECKS: $owed owed (CHECKS.txt) ==="

case "$src" in
	startup|clear|"")
		# Detached so the hook returns at once; Notepad staying open must never hold up a session.
		cmd //c start "" notepad.exe "CHECKS.txt" >/dev/null 2>&1 &
		echo "CHECKS.txt has been opened in Notepad for the dev. Don't tell them to open it; say the count and move on."
		;;
esac
exit 0
