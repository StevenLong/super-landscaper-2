#!/usr/bin/env bash
# Headless checks. Godot exits 0 even on script errors, so the PASS line and the
# absence of SCRIPT ERROR are the real signals. Run from anywhere: bash tests/run_all.sh
cd "$(dirname "$0")/.." || exit 1
GODOT="${GODOT:?set it to your Godot executable (see CLAUDE.md Environment)}"
fail=0

parse="$("$GODOT" --headless --editor --quit 2>&1 | grep -E "SCRIPT ERROR|Parse Error|SHADER ERROR")"
if [ -n "$parse" ]; then echo "FAIL  parse check"; echo "$parse"; fail=1; else echo "PASS  parse check"; fi

for t in tests/smoke.gd tests/test_*.gd; do
	[ -e "$t" ] || continue
	# timeout: a failed assert halts the script but not the SceneTree, so godot would idle forever.
	out="$(timeout 60 "$GODOT" --headless --path . -s "$t" 2>&1)"
	if ! grep -q "^PASS" <<<"$out" || grep -q "SCRIPT ERROR" <<<"$out"; then
		echo "FAIL  $t"; tail -n 25 <<<"$out"; fail=1
	else
		echo "PASS  $t"
	fi
done
exit $fail
