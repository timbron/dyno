extends RefCounted
## Test suite, loaded by tests/run_tests.gd once the autoloads exist.
## Add a _test_* function and call it from run().

const SCENES: Array[String] = [
	"res://scenes/ui/species_select.tscn",
	"res://scenes/strategic/strategic_map.tscn",
	"res://scenes/tactical/tactical.tscn",
]
const SMOKE_FRAMES: int = 10

var checks: int = 0
var failures: int = 0


func run(tree: SceneTree) -> void:
	_test_age_stage()
	_test_genome_inherit()
	_test_command_queue()
	await _test_scenes_smoke(tree)


func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + description)


func _test_age_stage() -> void:
	_check(Dino.stage_for(0, 100) == Dino.AgeStage.HATCHLING, "day 0 is hatchling")
	_check(Dino.stage_for(20, 100) == Dino.AgeStage.JUVENILE, "20% of life is juvenile")
	_check(Dino.stage_for(50, 100) == Dino.AgeStage.ADULT, "50% of life is adult")
	_check(Dino.stage_for(90, 100) == Dino.AgeStage.ELDER, "90% of life is elder")


func _test_genome_inherit() -> void:
	var parent := Genome.new()
	parent.add_mutation(&"thick_hide")
	parent.add_mutation(&"thick_hide")
	parent.add_mutation(&"keen_smell")
	_check(parent.mutation_ids.size() == 2, "mutations are not duplicated")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	_check(parent.inherit(rng, 1.0).mutation_ids.size() == 2, "pass chance 1 keeps everything")
	_check(parent.inherit(rng, 0.0).mutation_ids.is_empty(), "pass chance 0 keeps nothing")


func _test_command_queue() -> void:
	var queue := CommandQueue.new()
	_check(queue.current() == null, "empty queue has no current command")
	queue.enqueue(TacticalCommand.move_to(Vector3(1.0, 0.0, 2.0)))
	queue.enqueue(TacticalCommand.move_to(Vector3(3.0, 0.0, 4.0)))
	_check(queue.size() == 2, "two commands queued")
	queue.advance()
	_check(queue.current().target_position == Vector3(3.0, 0.0, 4.0), "advance moves to next")
	queue.clear()
	_check(queue.is_empty(), "clear empties the queue")


## Each scene must load, enter the tree and survive a few frames.
func _test_scenes_smoke(tree: SceneTree) -> void:
	for path in SCENES:
		var packed: PackedScene = load(path)
		_check(packed != null, "%s loads" % path)
		if packed == null:
			continue
		var scene := packed.instantiate()
		tree.root.add_child(scene)
		for i in SMOKE_FRAMES:
			await tree.physics_frame
		_check(is_instance_valid(scene) and scene.is_inside_tree(), "%s runs" % path)
		scene.queue_free()
		await tree.process_frame
	tree.paused = false
