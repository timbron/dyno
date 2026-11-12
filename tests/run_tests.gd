extends SceneTree
## Minimal headless test runner. Run from the project root:
##   godot --headless --path . -s res://tests/run_tests.gd
## Exit code 0 = all passed. Tests live in tests/suite.gd.
## A run that hangs is failed by a watchdog after WATCHDOG_SECONDS.
## CI runs this through tests/ci/run_godot.sh, which also checks the exit code and output.
##
## The suite is loaded at runtime, not referenced statically: a `-s` script is compiled
## before the autoloads are registered, so any script that names EventBus or GameState
## (Dino, for one) cannot be a compile-time dependency of this file.

const SUITE_PATH: String = "res://tests/suite.gd"
const WATCHDOG_SECONDS: float = 300.0

var _done: bool = false


func _initialize() -> void:
	create_timer(WATCHDOG_SECONDS, true, false, true).timeout.connect(_on_watchdog)
	_run.call_deferred()


func _run() -> void:
	# Wait one frame so the autoloads are in the tree and have run _ready().
	await process_frame
	var script: GDScript = load(SUITE_PATH)
	if script == null or not script.can_instantiate():
		printerr("FAIL: could not load " + SUITE_PATH)
		_done = true
		quit(1)
		return
	var suite: RefCounted = script.new()
	await suite.call("run", self)
	var checks: int = suite.get("checks")
	var failures: int = suite.get("failures")
	if checks == 0:
		printerr("FAIL: no checks ran")
	print("%d checks, %d failed" % [checks, failures])
	_done = true
	quit(1 if failures > 0 or checks == 0 else 0)


func _on_watchdog() -> void:
	if _done:
		return
	_done = true
	printerr("FAIL: test run did not finish within %d s" % int(WATCHDOG_SECONDS))
	quit(1)
