#!/usr/bin/env bash
# Headless checks. Godot exits 0 even on script errors, so the PASS line and the
# absence of SCRIPT ERROR are the real signals. Run from anywhere: bash tests/run_all.sh
cd "$(dirname "$0")/.." || exit 1
GODOT="${GODOT:?set it to your Godot executable (see CLAUDE.md Environment)}"
fail=0

# Warnings as errors for this run only (tests/strict.cfg): the editor's parse step doesn't
# analyse warnings, but every script a test loads does, so a new warning fails that test.
cp tests/strict.cfg override.cfg
trap 'rm -f override.cfg' EXIT

parse="$("$GODOT" --headless --editor --quit 2>&1 | grep -E "SCRIPT ERROR|Parse Error|SHADER ERROR")"
if [ -n "$parse" ]; then echo "FAIL  parse check"; echo "$parse"; fail=1; else echo "PASS  parse check"; fi

for t in tests/smoke.gd tests/test_*.gd; do
	[ -e "$t" ] || continue
	# timeout: a failed assert halts the script but not the SceneTree, so godot would idle forever.
	out="$(timeout 60 "$GODOT" --headless --path . -s "$t" 2>&1)"
	# Engine errors count too (a null call in an input handler, a bad get_child), bar the
	# leak reports a headless run prints as it quits ("... at exit").
	engine="$(grep "^ERROR:" <<<"$out" | grep -v "at exit")"
	if ! grep -q "^PASS" <<<"$out" || grep -q "SCRIPT ERROR" <<<"$out" || [ -n "$engine" ]; then
		# Show the real error; fall back to the tail (e.g. a timeout) when there is none.
		errs="$(grep -A2 -E "SCRIPT ERROR|^FAIL|^ERROR:" <<<"$out" | grep -v "at exit" | head -n 20)"
		echo "FAIL  $t"; if [ -n "$errs" ]; then echo "$errs"; else tail -n 25 <<<"$out"; fi; fail=1
	else
		echo "PASS  $t"
	fi
done
exit $fail
