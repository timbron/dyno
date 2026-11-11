class_name EncounterDirector
extends Node
## Referee of one encounter. Watches the squad and the wild animals, lets animals that
## cross the arena edge escape, and ends the encounter once: won when no wild animal is
## left on the field, fled when the squad's leader crosses the edge or the player leaves,
## died when the whole squad is dead. Stops with the tree during tactical pause.

signal finished(result: EncounterResult)

var arena_radius: float = 70.0
var squad: Array[Dino] = []
## Wild animals still on the field, alive or dead.
var wild: Array[Dino] = []
## The dino the player is steering; taking it over the edge is a retreat.
var leader: Dino
var escaped: int = 0

var _done: bool = false


static func outside_arena(position: Vector3, radius: float) -> bool:
	return Vector2(position.x, position.z).length() > radius


func _ready() -> void:
	EventBus.unit_selected.connect(_on_unit_selected)


func _physics_process(_delta: float) -> void:
	if _done:
		return
	_release_escapers()
	var retreated := (
		is_instance_valid(leader)
		and not leader.is_dead()
		and outside_arena(leader.global_position, arena_radius)
	)
	var outcome := EncounterResult.decide(_alive(squad), _alive(wild), retreated)
	if outcome != EncounterResult.Outcome.ONGOING:
		finish(outcome)


func is_finished() -> bool:
	return _done


## Ends the encounter with [param outcome] and reports it. Later calls do nothing.
func finish(outcome: EncounterResult.Outcome) -> void:
	if _done:
		return
	_done = true
	var result := EncounterResult.new()
	result.outcome = outcome
	result.escaped = escaped
	for dino in squad:
		if not is_instance_valid(dino) or dino.is_dead():
			result.lost += 1
			continue
		result.survivors += 1
		result.wounds.append(dino.health_fraction())
	for dino in wild:
		if is_instance_valid(dino) and dino.is_dead():
			result.kills.append(dino.species.id)
			result.meat += dino.species.meat
	finished.emit(result)


## A living wild animal past the edge is gone for good.
func _release_escapers() -> void:
	for dino: Dino in wild.duplicate():
		if not is_instance_valid(dino):
			wild.erase(dino)
			continue
		if dino.is_dead() or not outside_arena(dino.global_position, arena_radius):
			continue
		wild.erase(dino)
		escaped += 1
		dino.queue_free()


func _alive(dinos: Array[Dino]) -> int:
	var total := 0
	for dino in dinos:
		if is_instance_valid(dino) and not dino.is_dead():
			total += 1
	return total


func _on_unit_selected(dino: Node3D) -> void:
	var picked := dino as Dino
	if picked != null and squad.has(picked):
		leader = picked
