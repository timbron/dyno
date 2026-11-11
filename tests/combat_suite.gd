extends RefCounted
## Combat and wild AI tests (T-01, A-01). Run by tests/suite.gd, which owns the counters.

const DINO_SCENE: PackedScene = preload("res://scenes/dino/dino.tscn")

var _suite: RefCounted


func run(tree: SceneTree, suite: RefCounted) -> void:
	_suite = suite
	_test_combat_math()
	_test_brain_decide()
	await _test_attack_command(tree)
	await _test_wild_brain(tree)


func _check(condition: bool, description: String) -> void:
	_suite.call("_check", condition, description)


func _spawn_dino(tree: SceneTree, species: SpeciesData, at: Vector3) -> Dino:
	var dino := DINO_SCENE.instantiate() as Dino
	dino.setup(species, "Test")
	dino.position = at
	tree.root.add_child(dino)
	return dino


func _spawn_wild(tree: SceneTree, species: SpeciesData, at: Vector3) -> Dino:
	var dino := _spawn_dino(tree, species, at)
	var brain := WildBrain.new()
	brain.name = "Brain"
	dino.add_child(brain)
	return dino


func _brain_of(dino: Dino) -> WildBrain:
	return dino.get_node("Brain") as WildBrain


func _make_ground(tree: SceneTree) -> StaticBody3D:
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400.0, 1.0, 400.0)
	shape.shape = box
	ground.add_child(shape)
	ground.position = Vector3(0.0, -0.5, 0.0)
	tree.root.add_child(ground)
	return ground


func _wait(tree: SceneTree, frames: int) -> void:
	for i in frames:
		await tree.physics_frame


func _test_combat_math() -> void:
	var origin := Vector3.ZERO
	# Target at the origin with yaw 0 faces -Z.
	var front := CombatMath.hit_zone(Vector3(0.0, 0.0, -3.0), origin, 0.0)
	var side := CombatMath.hit_zone(Vector3(3.0, 0.0, 0.0), origin, 0.0)
	var behind := CombatMath.hit_zone(Vector3(0.0, 0.0, 3.0), origin, 0.0)
	_check(front == CombatMath.Zone.FRONT, "attacker ahead of the target hits the front")
	_check(side == CombatMath.Zone.FLANK, "attacker beside the target hits the flank")
	_check(behind == CombatMath.Zone.REAR, "attacker behind the target hits the rear")
	var turned := CombatMath.hit_zone(Vector3(0.0, 0.0, -3.0), origin, PI)
	_check(turned == CombatMath.Zone.REAR, "zones turn with the target")
	_check(is_equal_approx(CombatMath.bite_damage(20.0, front), 20.0), "front bite: base damage")
	_check(is_equal_approx(CombatMath.bite_damage(20.0, side), 25.0), "flank bite deals 125%")
	_check(is_equal_approx(CombatMath.bite_damage(20.0, behind), 30.0), "rear bite deals 150%")
	var reach := CombatMath.bite_reach(0.5, 1.0)
	_check(is_equal_approx(reach, 1.5 + CombatMath.REACH_MARGIN), "reach covers both bodies")
	var near := Vector3(reach - 0.01, 5.0, 0.0)
	var far := Vector3(reach + 0.01, 0.0, 0.0)
	_check(CombatMath.in_reach(origin, 0.5, near, 1.0), "just inside reach, height ignored")
	_check(not CombatMath.in_reach(origin, 0.5, far, 1.0), "just outside reach")
	_check(CombatMath.in_bite_arc(origin, 0.0, Vector3(0.5, 0.0, -2.0)), "ahead is in the arc")
	_check(not CombatMath.in_bite_arc(origin, 0.0, Vector3(2.0, 0.0, 0.0)), "abeam is not")
	_check(not CombatMath.in_bite_arc(origin, 0.0, Vector3(0.0, 0.0, 2.0)), "behind is not")


func _test_brain_decide() -> void:
	var skittish := SpeciesData.Temperament.SKITTISH
	var territorial := SpeciesData.Temperament.TERRITORIAL
	var predator := SpeciesData.Temperament.PREDATOR
	var idle := WildBrain.State.IDLE
	var flee := WildBrain.State.FLEE
	var attack := WildBrain.State.ATTACK
	_check(WildBrain.decide(predator, false, true, false, false) == idle, "no threat: idle")
	_check(WildBrain.decide(skittish, true, false, false, true) == flee, "prey flees on sight")
	_check(WildBrain.decide(skittish, true, true, true, true) == attack, "cornered prey fights")
	_check(WildBrain.decide(predator, true, false, false, false) == attack, "predator attacks")
	_check(WildBrain.decide(predator, true, true, false, false) == flee, "hurt predator flees")
	_check(WildBrain.decide(predator, true, true, true, false) == attack, "cornered beats hurt")
	_check(WildBrain.decide(territorial, true, false, false, true) == attack, "defends its ground")
	_check(WildBrain.decide(territorial, true, false, false, false) == idle, "ignores passers-by")
	for temperament: SpeciesData.Temperament in [skittish, territorial, predator]:
		var profile := WildBrain.default_profile(temperament)
		_check(profile != null and profile.resource_path != "", "profile file for temperament")


func _test_attack_command(tree: SceneTree) -> void:
	var ground := _make_ground(tree)
	var hunter_species := SpeciesData.new()
	hunter_species.bite_damage = 10.0
	hunter_species.bite_cooldown = 0.5
	var prey_species := SpeciesData.new()
	prey_species.max_health = 45.0
	var hunter := _spawn_dino(tree, hunter_species, Vector3(0.0, 0.1, 12.0))
	hunter.faction = Dino.FACTION_PLAYER
	# Prey faces -Z, away from the hunter, so every bite lands on its rear.
	var prey := _spawn_dino(tree, prey_species, Vector3(0.0, 0.1, 0.0))
	var bites: Array[float] = []
	var zones: Array[int] = []
	hunter.bit.connect(
		func(_target: Dino, amount: float, zone: int) -> void:
			bites.append(amount)
			zones.append(zone)
	)
	_check(not hunter.bite(prey), "a bite from out of reach misses")
	hunter.commands.enqueue(TacticalCommand.attack(prey))
	hunter.commands.enqueue(TacticalCommand.move_to(Vector3(0.0, 0.0, 12.0)))
	await _wait(tree, 600)
	_check(prey.is_dead(), "attack order closes in and bites until the target is dead")
	_check(bites.size() == 3, "three rear bites kill a 45 health target")
	_check(not bites.is_empty() and is_equal_approx(bites[0], 15.0), "rear bite deals 150%")
	var all_rear := zones.all(func(zone: int) -> bool: return zone == CombatMath.Zone.REAR)
	_check(all_rear, "every bite from behind is a rear hit")
	_check(hunter.global_position.z > 10.0, "the queue moves on after the kill")
	_check(not hunter.bite(prey), "a corpse cannot be bitten")
	for node: Node in [ground, hunter, prey]:
		node.queue_free()
	await tree.process_frame


func _test_wild_brain(tree: SceneTree) -> void:
	var ground := _make_ground(tree)
	var dryosaur := load("res://data/species/dryosaur.tres") as SpeciesData
	var allosaur := load("res://data/species/allosaur.tres") as SpeciesData
	var raptor := load("res://data/species/raptor.tres") as SpeciesData
	# Prey: calm alone, bolts when a hunter comes into sight.
	var prey := _spawn_wild(tree, dryosaur, Vector3(0.0, 0.1, 0.0))
	await _wait(tree, 60)
	_check(_brain_of(prey).state == WildBrain.State.IDLE, "prey with nothing in sight is idle")
	var hunter := _spawn_dino(tree, raptor, Vector3(0.0, 0.1, 15.0))
	hunter.faction = Dino.FACTION_PLAYER
	await _wait(tree, 45)
	_check(_brain_of(prey).state == WildBrain.State.FLEE, "prey flees a hunter in sight")
	await _wait(tree, 240)
	_check(_brain_of(prey).state == WildBrain.State.IDLE, "prey calms down once far away")
	var gap := prey.global_position.distance_to(hunter.global_position)
	_check(gap > 25.0, "fleeing prey opens the distance")
	_check(prey.global_position.z < -8.0, "prey runs directly away from the hunter")
	prey.queue_free()
	await tree.process_frame
	# Same faction is never a threat.
	var friend := _spawn_wild(tree, dryosaur, Vector3(100.0, 0.1, 100.0))
	var other := _spawn_wild(tree, dryosaur, Vector3(103.0, 0.1, 100.0))
	await _wait(tree, 60)
	_check(_brain_of(friend).state == WildBrain.State.IDLE, "herd mates do not scare each other")
	# Rival predator: attacks on sight, breaks off when badly hurt.
	var rival := _spawn_wild(tree, allosaur, Vector3(0.0, 0.1, -8.0))
	var start_health := hunter.health
	await _wait(tree, 400)
	_check(hunter.health < start_health, "rival predator closes in and its bites land")
	var bystander := _spawn_dino(tree, raptor, rival.global_position + Vector3(0.0, 0.1, 20.0))
	bystander.faction = Dino.FACTION_PLAYER
	rival.take_damage(rival.species.max_health * 0.9, bystander)
	var hurt_at := rival.global_position.distance_to(bystander.global_position)
	await _wait(tree, 120)
	_check(_brain_of(rival).state == WildBrain.State.FLEE, "badly hurt rival breaks off")
	var after := rival.global_position.distance_to(bystander.global_position)
	_check(after > hurt_at, "hurt rival runs from its attacker")
	for node: Node in [ground, hunter, rival, bystander, friend, other]:
		node.queue_free()
	await tree.process_frame
