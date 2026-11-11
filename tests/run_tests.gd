extends SceneTree
## Minimal headless test runner. Run from the project root:
##   godot --headless --path . -s res://tests/run_tests.gd
## Exit code 0 = all passed. Tests live in tests/suite.gd.
##
## The suite is loaded at runtime, not referenced statically: a `-s` script is compiled
## before the autoloads are registered, so any script that names EventBus or GameState
## (Dino, for one) cannot be a compile-time dependency of this file.

const SUITE_PATH: String = "res://tests/suite.gd"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	# Wait one frame so the autoloads are in the tree and have run _ready().
	await process_frame
	var script: GDScript = load(SUITE_PATH)
	if script == null or not script.can_instantiate():
		printerr("FAIL: could not load " + SUITE_PATH)
		quit(1)
		return
	var suite: RefCounted = script.new()
	await suite.call("run", self)
	var checks: int = suite.get("checks")
	var failures: int = suite.get("failures")
	print("%d checks, %d failed" % [checks, failures])
	quit(1 if failures > 0 or checks == 0 else 0)
