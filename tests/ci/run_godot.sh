#!/usr/bin/env bash
# Runs one headless Godot step for CI and fails on anything that step must not print.
# Usage (project root): bash tests/ci/run_godot.sh import|tests
# Env: GODOT = Godot binary (default godot), GODOT_TIMEOUT = seconds (per-mode default).
set -uo pipefail

mode="${1:-}"
godot="${GODOT:-godot}"
case "$mode" in
	import)
		limit="${GODOT_TIMEOUT:-300}"
		log=import.log
		args=(--headless --path . --import)
		bad='SCRIPT ERROR|Parse Error|Compile Error'
		;;
	tests)
		limit="${GODOT_TIMEOUT:-420}"
		log=tests.log
		args=(--headless --path . -s res://tests/run_tests.gd)
		bad='SCRIPT ERROR|Parse Error|Compile Error|^(USER )?ERROR|FAIL:|leaked at exit|still in use at exit'
		;;
	*)
		echo "usage: run_godot.sh import|tests" >&2
		exit 2
		;;
esac

timeout --kill-after=10 "$limit" "$godot" "${args[@]}" 2>&1 | tee "$log"
status=${PIPESTATUS[0]}
failed=0
if [ "$status" -eq 124 ] || [ "$status" -eq 137 ]; then
	echo "::error::Godot $mode did not finish within ${limit}s"
	failed=1
elif [ "$status" -ne 0 ]; then
	echo "::error::Godot $mode exited with code $status"
	failed=1
fi
if grep -nE "$bad" "$log"; then
	echo "::error::Godot $mode printed errors, failures or a leak report (lines above)"
	failed=1
fi
if [ "$mode" = tests ] && ! grep -qE '^[1-9][0-9]* checks, 0 failed[[:space:]]*$' "$log"; then
	echo "::error::the test run did not print a passing summary line"
	failed=1
fi
exit "$failed"
