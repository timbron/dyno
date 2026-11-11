extends RefCounted
## Encounter setup and outcome tests (T-03). Run by tests/suite.gd, which owns the counters.

const DINO_SCENE: PackedScene = preload("res://scenes/dino/dino.tscn")
const TACTICAL_SCENE: String = "res://scenes/tactical/tactical.tscn"
const GROUP_SCRIPT: String = "res://src/tactical/encounter_group.gd"

var _suite: RefCounted


func run(tree: SceneTree, suite: RefCounted) -> void:
	_suite = suite
	_test_decide()
	_test_group_layout()
	_test_encounter_data()
	_test_game_state_hand_off()
	await _test_director(tree)
	await _test_scene_spawns_encounter(tree)


func _check(condition: bool, description: String) -> void:
	_suite.call("_check", condition, description)


func _spawn_dino(tree: SceneTree, species: SpeciesData, at: Vector3) -> Dino:
	var dino := DINO_SCENE.instantiate() as Dino
	dino.setup(species, "Test")
	dino.position = at
	tree.root.add_child(dino)
	return dino


func _wait(tree: SceneTree, frames: int) -> void:
	for i in frames:
		await tree.physics_frame


func _test_decide() -> void:
	var ongoing := EncounterResult.Outcome.ONGOING
	var won := EncounterResult.Outcome.WON
	var fled := EncounterResult.Outcome.FLED
	var died := EncounterResult.Outcome.DIED
	_check(EncounterResult.decide(3, 5, false) == ongoing, "both sides standing: ongoing")
	_check(EncounterResult.decide(1, 0, false) == won, "no wild animal left: won")
	_check(EncounterResult.decide(2, 4, true) == fled, "leader over the edge: fled")
	_check(EncounterResult.decide(0, 4, false) == died, "squad wiped: died")
	_check(EncounterResult.decide(0, 0, true) == died, "a wiped squad never wins or flees")
	_check(EncounterResult.decide(2, 0, true) == fled, "a retreat beats a win on the same frame")
	_check(EncounterDirector.outside_arena(Vector3(50.0, 9.0, 50.0), 70.0), "past the edge")
	_check(not EncounterDirector.outside_arena(Vector3(40.0, 9.0, 40.0), 70.0), "inside it")


func _test_group_layout() -> void:
	var species := SpeciesData.new()
	species.pack_size = 4
	# Built through load(): naming EncounterGroup here makes Godot 4.7 report leaked
	# scripts when the test run exits.
	var group: Resource = (load(GROUP_SCRIPT) as GDScript).new()
	group.set("species", species)
	group.set("distance", 30.0)
	_check(group.call("body_count") == 4, "count 0 takes the species pack size")
	var ahead: Vector3 = group.call("centre")
	_check(ahead.distance_to(Vector3(0.0, 0.0, -30.0)) < 0.001, "bearing 0 is ahead")
	group.set("bearing_degrees", 90.0)
	var centre: Vector3 = group.call("centre")
	_check(centre.distance_to(Vector3(30.0, 0.0, 0.0)) < 0.001, "bearing 90 is right")
	group.set("count", 9)
	var spots: Array[Vector3] = group.call("positions")
	_check(spots.size() == 9, "an explicit count overrides the pack size")
	_check(spots[0].distance_to(centre) < 0.001, "the first body stands at the centre")
	var apart := true
	for i in spots.size():
		for j in i:
			apart = apart and spots[i].distance_to(spots[j]) >= 3.0 * 0.6
	_check(apart, "bodies in a group do not start on top of each other")
	var again: Array[Vector3] = group.call("positions")
	var same := again.size() == spots.size()
	for i in mini(again.size(), spots.size()):
		same = same and again[i].is_equal_approx(spots[i])
	_check(same, "the layout is the same every time")
	var empty: Resource = (load(GROUP_SCRIPT) as GDScript).new()
	var nobody: Array[Vector3] = empty.call("positions")
	_check(empty.call("body_count") == 0 and nobody.is_empty(), "no species, no bodies")


func _test_encounter_data() -> void:
	var all := EncounterData.load_all()
	_check(all.size() >= 3, "three or more encounter resources load")
	for encounter in all:
		var path := "%s%s.tres" % [EncounterData.DIRECTORY, encounter.id]
		_check(encounter.resource_path == path, "encounter %s is named after its id" % encounter.id)
		_check(encounter.body_count() > 0, "encounter %s spawns something" % encounter.id)
		var sane := true
		for group in encounter.groups:
			sane = sane and group.species != null and not group.species.playable
			for spot in group.positions():
				# Room to stand, and far enough that the squad is not bitten on arrival.
				sane = sane and spot.length() < encounter.arena_radius - 5.0
				sane = sane and spot.length() > 15.0
		_check(sane, "encounter %s places wild species inside the arena" % encounter.id)
	_check(EncounterData.load_by_id(&"dryosaur_herd") != null, "load_by_id finds an encounter")
	_check(EncounterData.load_by_id(&"no_such_thing") == null, "an unknown id gives null")
	_check(EncounterData.load_by_id(&"") == null, "an empty id gives null")


func _test_game_state_hand_off() -> void:
	var cleared_before := GameState.cleared_encounters.duplicate()
	var ended: Array[RefCounted] = []
	var on_ended := func(result: RefCounted) -> void: ended.append(result)
	EventBus.encounter_ended.connect(on_ended)
	GameState.cleared_encounters.clear()
	GameState.begin_encounter(2, &"contested_kill")
	_check(GameState.pending_encounter_id == &"contested_kill", "the map names the encounter")
	var fled := EncounterResult.new()
	fled.outcome = EncounterResult.Outcome.FLED
	GameState.record_encounter(fled)
	_check(GameState.last_encounter == fled, "the result is kept on GameState")
	_check(not GameState.cleared_encounters.has(2), "an encounter the party fled stays")
	_check(GameState.fled_encounter_index == 2, "and is remembered as fled")
	_check(GameState.pending_encounter_index == -1, "the hand-off is used up")
	GameState.begin_encounter(2, &"contested_kill")
	var won := EncounterResult.new()
	won.outcome = EncounterResult.Outcome.WON
	GameState.record_encounter(won)
	_check(GameState.cleared_encounters.has(2), "a won encounter is cleared from the map")
	_check(ended.size() == 2 and ended[1] == won, "encounter_ended carries each result")
	EventBus.encounter_ended.disconnect(on_ended)
	GameState.cleared_encounters = cleared_before
	GameState.fled_encounter_index = -1
	GameState.last_encounter = null


func _make_director(tree: SceneTree, squad: Array[Dino], wild: Array[Dino]) -> EncounterDirector:
	var director := EncounterDirector.new()
	director.arena_radius = 20.0
	director.squad = squad
	director.wild = wild
	director.leader = squad[0]
	tree.root.add_child(director)
	return director


func _test_director(tree: SceneTree) -> void:
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400.0, 1.0, 400.0)
	shape.shape = box
	ground.add_child(shape)
	ground.position = Vector3(0.0, -0.5, 0.0)
	tree.root.add_child(ground)
	var species := SpeciesData.new()
	species.id = &"test_prey"
	species.meat = 0.5
	var results: Array[EncounterResult] = []
	var on_finished := func(result: EncounterResult) -> void: results.append(result)

	# Won: one kill, one escape over the edge.
	var a := _spawn_dino(tree, species, Vector3(0.0, 0.1, 0.0))
	var b := _spawn_dino(tree, species, Vector3(3.0, 0.1, 0.0))
	a.faction = Dino.FACTION_PLAYER
	b.faction = Dino.FACTION_PLAYER
	var victim := _spawn_dino(tree, species, Vector3(0.0, 0.1, -8.0))
	var runner := _spawn_dino(tree, species, Vector3(6.0, 0.1, -8.0))
	var director := _make_director(tree, [a, b], [victim, runner])
	director.finished.connect(on_finished)
	await _wait(tree, 5)
	_check(results.is_empty() and not director.is_finished(), "nothing ends while both stand")
	a.take_damage(a.species.max_health * 0.25)
	victim.take_damage(1000.0)
	await _wait(tree, 5)
	_check(results.is_empty(), "one wild animal alive on the field keeps it going")
	runner.global_position = Vector3(0.0, 0.1, -30.0)
	await _wait(tree, 5)
	_check(not is_instance_valid(runner), "an animal over the edge is gone")
	_check(results.size() == 1, "the encounter ends exactly once")
	if results.size() == 1:
		var won := results[0]
		_check(won.outcome == EncounterResult.Outcome.WON, "nothing wild left: won")
		var one_kill := won.kills.size() == 1 and won.kills[0] == &"test_prey"
		_check(one_kill, "the kill is listed by species")
		_check(won.escaped == 1, "the escape is counted")
		_check(is_equal_approx(won.meat, 0.5), "meat comes from the kills only")
		_check(won.survivors == 2 and won.lost == 0, "both squad members survived")
		_check(is_equal_approx(won.wounds[0], 0.75), "wounds are the survivors' health")
	director.finish(EncounterResult.Outcome.FLED)
	_check(results.size() == 1, "a finished encounter cannot end again")
	director.queue_free()
	victim.queue_free()

	# Fled: the leader crosses the edge; a follower outside does not count.
	var beast := _spawn_dino(tree, species, Vector3(0.0, 0.1, -8.0))
	results.clear()
	director = _make_director(tree, [a, b], [beast])
	director.finished.connect(on_finished)
	b.global_position = Vector3(30.0, 0.1, 0.0)
	await _wait(tree, 5)
	_check(results.is_empty(), "a follower over the edge is not a retreat")
	a.global_position = Vector3(-30.0, 0.1, 0.0)
	await _wait(tree, 5)
	var fled := results.size() == 1 and results[0].outcome == EncounterResult.Outcome.FLED
	_check(fled, "the leader over the edge is a retreat")
	director.queue_free()

	# Died: the whole squad is dead.
	a.global_position = Vector3(0.0, 0.1, 0.0)
	b.global_position = Vector3(3.0, 0.1, 0.0)
	results.clear()
	director = _make_director(tree, [a, b], [beast])
	director.finished.connect(on_finished)
	a.take_damage(1000.0)
	await _wait(tree, 5)
	_check(results.is_empty(), "one squad member down is not the end")
	b.take_damage(1000.0)
	await _wait(tree, 5)
	var died := results.size() == 1 and results[0].outcome == EncounterResult.Outcome.DIED
	_check(died, "the whole squad dead: died")
	_check(died and results[0].lost == 2 and results[0].survivors == 0, "the losses are counted")
	for node: Node in [director, ground, a, b, beast]:
		node.queue_free()
	await tree.process_frame


## The real scene sets up the encounter named on GameState.
func _test_scene_spawns_encounter(tree: SceneTree) -> void:
	var species_before := GameState.species
	GameState.species = load("res://data/species/raptor.tres") as SpeciesData
	GameState.begin_encounter(-1, &"contested_kill")
	var encounter := EncounterData.load_by_id(&"contested_kill")
	var scene := (load(TACTICAL_SCENE) as PackedScene).instantiate()
	tree.root.add_child(scene)
	await _wait(tree, 10)
	var director := scene.get_node("Director") as EncounterDirector
	_check(director.wild.size() == encounter.body_count(), "every body in the data is spawned")
	_check(director.squad.size() == GameState.species.pack_size, "and the whole squad")
	_check(is_equal_approx(director.arena_radius, encounter.arena_radius), "arena from the data")
	var wild_ok := true
	for dino in director.wild:
		wild_ok = wild_ok and dino.faction == Dino.FACTION_WILD and dino.has_node("Brain")
	_check(wild_ok, "wild animals are wild and have a brain")
	_check(director.leader == director.squad[0], "the selected dino is the leader")
	_check(not director.is_finished(), "the encounter is running")
	scene.queue_free()
	await tree.process_frame
	GameState.species = species_before
	GameState.pending_encounter_index = -1
	GameState.pending_encounter_id = &""
