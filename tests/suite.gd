extends RefCounted
## Test suite, loaded by tests/run_tests.gd once the autoloads exist.
## Add a _test_* function and call it from run().

const SCENES: Array[String] = [
	"res://scenes/ui/main_menu.tscn",
	"res://scenes/ui/species_select.tscn",
	"res://scenes/strategic/strategic_map.tscn",
	"res://scenes/tactical/tactical.tscn",
]
const SMOKE_FRAMES: int = 10
const COMBAT_SUITE_PATH: String = "res://tests/combat_suite.gd"
const DINO_SCENE: PackedScene = preload("res://scenes/dino/dino.tscn")

var checks: int = 0
var failures: int = 0


func run(tree: SceneTree) -> void:
	_test_age_stage()
	_test_genome_inherit()
	_test_command_queue()
	await _test_dino_damage_and_death(tree)
	await _test_dino_collision_scale(tree)
	_test_species_data()
	_test_formation()
	await _test_pack_follow(tree)
	var combat: RefCounted = (load(COMBAT_SUITE_PATH) as GDScript).new()
	await combat.call("run", tree, self)
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


func _spawn_dino(tree: SceneTree, species: SpeciesData) -> Dino:
	var dino := DINO_SCENE.instantiate() as Dino
	dino.setup(species, "Test")
	tree.root.add_child(dino)
	return dino


func _test_dino_damage_and_death(tree: SceneTree) -> void:
	var species := SpeciesData.new()
	species.max_health = 50.0
	var dino := _spawn_dino(tree, species)
	var deaths: Array[Node3D] = []
	var on_died := func(dead: Node3D) -> void: deaths.append(dead)
	EventBus.dino_died.connect(on_died)
	_check(dino.health == 50.0, "dino starts at species max health")
	dino.take_damage(-5.0)
	_check(dino.health == 50.0, "negative damage is ignored")
	dino.take_damage(20.0)
	_check(dino.health == 30.0 and not dino.is_dead(), "damage reduces health")
	_check(is_equal_approx(dino.health_fraction(), 0.6), "health fraction follows health")
	dino.commands.enqueue(TacticalCommand.move_to(Vector3(9.0, 0.0, 9.0)))
	dino.take_damage(500.0)
	_check(dino.health == 0.0 and dino.is_dead(), "overkill clamps at zero and kills")
	dino.take_damage(10.0)
	_check(deaths.size() == 1 and deaths[0] == dino, "dino_died is emitted exactly once")
	_check(dino.commands.is_empty(), "death clears the command queue")
	_check(dino.is_in_group(Dino.CORPSE_GROUP), "dead dino is a corpse")
	_check(dino.collision_layer == Dino.LAYER_CORPSE, "corpse leaves the body layer")
	dino.move_intent = Vector3.FORWARD
	var start := dino.global_position
	for i in SMOKE_FRAMES:
		await tree.physics_frame
	var moved := dino.global_position - start
	moved.y = 0.0
	_check(moved.length() < 0.001, "corpse ignores move intent")
	EventBus.dino_died.disconnect(on_died)
	dino.queue_free()
	await tree.process_frame


func _test_dino_collision_scale(tree: SceneTree) -> void:
	var small := SpeciesData.new()
	small.body_scale = 0.5
	var large := SpeciesData.new()
	large.body_scale = 2.5
	var a := _spawn_dino(tree, small)
	var b := _spawn_dino(tree, large)
	var shape_a := (a.get_node("Collision") as CollisionShape3D).shape as CapsuleShape3D
	var shape_b := (b.get_node("Collision") as CollisionShape3D).shape as CapsuleShape3D
	_check(shape_a != shape_b, "each dino has its own collision shape")
	_check(is_equal_approx(shape_a.radius, Dino.BASE_RADIUS * 0.5), "small collision radius")
	_check(is_equal_approx(shape_b.height, Dino.BASE_HEIGHT * 2.5), "large collision height")
	_check(is_equal_approx(b.body_radius(), shape_b.radius), "body_radius matches the shape")
	a.queue_free()
	b.queue_free()
	await tree.process_frame


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


func _test_species_data() -> void:
	var all := SpeciesData.load_all()
	_check(all.size() >= 4, "four or more species resources load")
	var ids: Array[StringName] = []
	for species in all:
		_check(not ids.has(species.id), "species id %s is unique" % species.id)
		ids.append(species.id)
		var sane := species.max_health > 0.0 and species.move_speed > 0.0
		sane = sane and species.body_scale > 0.0 and species.pack_size >= 1
		_check(sane, "species %s has usable stats" % species.id)
	_check(ids.has(&"dryosaur") and ids.has(&"allosaur"), "wild prey and rival exist")
	var playable := SpeciesData.load_playable()
	_check(playable.size() == 2, "exactly the raptor and tyrannosaur are playable")
	for species in playable:
		_check(species.playable, "load_playable returns only playable species")


func _test_formation() -> void:
	var spacing := Formation.spacing_for(0.5, 0.5)
	_check(is_equal_approx(spacing, 1.0 + Formation.BODY_GAP), "spacing covers both radii")
	var first := Formation.slot_offset(0, 2.0)
	var second := Formation.slot_offset(1, 2.0)
	var third := Formation.slot_offset(2, 2.0)
	_check(first.z > 0.0 and second.z > 0.0, "followers stand behind the leader")
	_check(first.x < 0.0 and second.x > 0.0, "followers alternate left and right")
	_check(is_equal_approx(first.z, second.z), "a pair shares a row")
	_check(third.z > first.z, "the next pair is one row further back")
	var slots: Array[Vector3] = []
	var apart := true
	for i in 7:
		var slot := Formation.slot_offset(i, 2.0)
		for other in slots:
			apart = apart and slot.distance_to(other) >= 2.0
		apart = apart and slot.length() >= 2.0
		slots.append(slot)
	_check(apart, "seven followers keep at least the spacing from each other and the leader")
	# A leader turned a quarter turn left faces -X, so "behind" is +X.
	var turned := Formation.slot_position(Vector3(10.0, 0.0, 10.0), PI * 0.5, 0, 2.0)
	_check(turned.x > 10.0, "slots rotate with the leader")


func _test_pack_follow(tree: SceneTree) -> void:
	var species := SpeciesData.new()
	species.pack_size = 3
	var ground := StaticBody3D.new()
	var ground_shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(200.0, 1.0, 200.0)
	ground_shape.shape = box
	ground.add_child(ground_shape)
	ground.position = Vector3(0.0, -0.5, 0.0)
	tree.root.add_child(ground)
	var squad := SquadController.new()
	tree.root.add_child(squad)
	for i in 3:
		var dino := _spawn_dino(tree, species)
		dino.position = Vector3(i * 3.0, 0.1, 0.0)
		squad.members.append(dino)
	squad.select(0)
	var leader := squad.members[0]
	var follower := squad.members[1]
	var other := squad.members[2]
	leader.commands.enqueue(TacticalCommand.move_to(Vector3(0.0, 0.0, -20.0)))
	for i in 360:
		await tree.physics_frame
	_check(leader.global_position.z < -18.0, "leader carries out its move order")
	_check(follower.global_position.z < -10.0, "follower keeps up with the leader")
	_check(
		follower.global_position.distance_to(other.global_position) > 1.0,
		"followers do not stack on one spot"
	)
	squad.set_pack_following(false)
	var held := follower.global_position
	leader.commands.enqueue(TacticalCommand.move_to(Vector3(0.0, 0.0, 0.0)))
	for i in 240:
		await tree.physics_frame
	_check(follower.global_position.distance_to(held) < 1.5, "pack on hold stays put")
	leader.take_damage(1000.0)
	_check(squad.selected() != leader, "selection leaves a dead leader")
	_check(not squad.selected().is_dead(), "selection lands on a living member")
	other.take_damage(1000.0)
	follower.take_damage(1000.0)
	squad.select(squad.selected_index + 1)
	_check(squad.living().is_empty(), "a wiped pack has no living members")
	for node: Node in [squad, ground, leader, follower, other]:
		node.queue_free()
	await tree.process_frame
