class_name WildBrain
extends Node
## Small state machine for one wild dino; add it as a child of the Dino it drives.
## It only ever touches the dino through move_intent, wants_sprint and commands, and it
## pauses with the tree. Never add one to a dino the player controls.
##
## IDLE    stroll around the starting spot.
## FLEE    sprint away from every threat in sight until they are far behind.
## ATTACK  run down and bite one threat.

enum State { IDLE, FLEE, ATTACK }

const PROFILE_DIRECTORY: String = "res://data/ai/"

@export var profile: AiProfile

var state: State = State.IDLE
var target: Dino

var _dino: Dino
var _home: Vector3
var _think_timer: float = 0.0
var _wander_timer: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


## What an animal does this instant. Pure, so the rules can be tested without a scene.
## [param hurt]: below the species' flee threshold. [param cornered]: a threat is on top
## of it and it is too tired to run. [param in_territory]: the threat is on its ground.
static func decide(
	temperament: SpeciesData.Temperament, has_threat: bool, hurt: bool, cornered: bool,
	in_territory: bool
) -> State:
	if not has_threat:
		return State.IDLE
	if cornered:
		return State.ATTACK
	if hurt:
		return State.FLEE
	match temperament:
		SpeciesData.Temperament.PREDATOR:
			return State.ATTACK
		SpeciesData.Temperament.TERRITORIAL:
			return State.ATTACK if in_territory else State.IDLE
	return State.FLEE


## The profile matching a temperament: data/ai/skittish.tres, territorial.tres, predator.tres.
static func default_profile(temperament: SpeciesData.Temperament) -> AiProfile:
	var names: PackedStringArray = ["skittish", "territorial", "predator"]
	var path := "%s%s.tres" % [PROFILE_DIRECTORY, names[temperament]]
	if ResourceLoader.exists(path):
		var loaded := load(path) as AiProfile
		if loaded != null:
			return loaded
	return AiProfile.new()


func _ready() -> void:
	_dino = get_parent() as Dino
	if _dino == null:
		push_error("WildBrain must be a child of a Dino")
		set_physics_process(false)
		return
	if profile == null:
		profile = default_profile(_dino.species.temperament)
	_home = _dino.global_position
	_rng.randomize()
	# Stagger the herd so forty brains do not all look around on the same frame.
	_think_timer = _rng.randf() * profile.think_interval
	_wander_timer = _rng.randf_range(0.0, profile.wander_pause_max)
	_dino.damaged.connect(_on_damaged)


func _physics_process(delta: float) -> void:
	if _dino.is_dead():
		set_physics_process(false)
		return
	_think_timer -= delta
	if _think_timer <= 0.0:
		_think_timer = profile.think_interval
		_think()
	match state:
		State.IDLE:
			_idle(delta)
		State.FLEE:
			_flee()
		State.ATTACK:
			_attack()


## Living dinos of another faction within [param radius], nearest first.
func threats_within(radius: float) -> Array[Dino]:
	var found: Array[Dino] = []
	for node in get_tree().get_nodes_in_group(Dino.GROUP):
		var other := node as Dino
		if other == null or other == _dino or other.is_dead():
			continue
		if other.faction == _dino.faction:
			continue
		if _flat_distance(other.global_position, _dino.global_position) <= radius:
			found.append(other)
	var here := _dino.global_position
	found.sort_custom(
		func(a: Dino, b: Dino) -> bool:
			var to_a := a.global_position.distance_squared_to(here)
			return to_a < b.global_position.distance_squared_to(here)
	)
	return found


func _think() -> void:
	# Once alarmed, keep watching until the threat is well away, not just out of sight.
	var radius := profile.sight_range if state == State.IDLE else profile.safe_range
	var threats := threats_within(radius)
	var nearest: Dino = threats[0] if not threats.is_empty() else null
	var hurt := _dino.health_fraction() < _dino.species.flee_health_fraction
	var cornered := false
	var in_territory := false
	if nearest != null:
		var distance := _flat_distance(nearest.global_position, _dino.global_position)
		var stamina_fraction := _dino.stamina / maxf(_dino.species.max_stamina, 0.001)
		var exhausted := stamina_fraction <= profile.exhausted_stamina_fraction
		cornered = exhausted and distance <= profile.cornered_range
		in_territory = _flat_distance(nearest.global_position, _home) <= profile.territory_radius
	var next := decide(_dino.species.temperament, nearest != null, hurt, cornered, in_territory)
	_enter(next, nearest)


func _enter(next: State, nearest: Dino) -> void:
	if next == State.ATTACK:
		# Stay on the current victim while it lives; switching every look wastes bites.
		if state != State.ATTACK or not is_instance_valid(target) or target.is_dead():
			target = nearest
	else:
		target = null
	if next == state:
		return
	state = next
	_dino.commands.clear()
	_dino.move_intent = Vector3.ZERO
	_dino.wants_sprint = false
	if state == State.IDLE:
		_wander_timer = _rng.randf_range(profile.wander_pause_min, profile.wander_pause_max)


func _idle(delta: float) -> void:
	_dino.wants_sprint = false
	if not _dino.commands.is_empty():
		return
	_wander_timer -= delta
	if _wander_timer > 0.0:
		return
	_wander_timer = _rng.randf_range(profile.wander_pause_min, profile.wander_pause_max)
	var angle := _rng.randf() * TAU
	var reach := _rng.randf() * profile.wander_radius
	var spot := _home + Vector3(cos(angle), 0.0, sin(angle)) * reach
	_dino.commands.enqueue(TacticalCommand.move_to(spot))


func _flee() -> void:
	var away := Vector3.ZERO
	var here := _dino.global_position
	for threat in threats_within(profile.safe_range):
		var offset := here - threat.global_position
		offset.y = 0.0
		# Nearer threats push harder.
		away += offset.normalized() / maxf(offset.length(), 1.0)
	if away.is_zero_approx():
		_dino.move_intent = Vector3.ZERO
		_dino.wants_sprint = false
		return
	_dino.move_intent = away.normalized()
	_dino.wants_sprint = true


func _attack() -> void:
	if not is_instance_valid(target) or target.is_dead():
		target = null
		return
	var command := _dino.commands.current()
	if command == null or command.type != TacticalCommand.Type.ATTACK or command.target != target:
		_dino.commands.clear()
		_dino.commands.enqueue(TacticalCommand.attack(target))
	_dino.wants_sprint = not _dino.can_reach(target)


## Being bitten is noticed at once, even from outside the sight range or from behind.
func _on_damaged(_amount: float, attacker: Dino) -> void:
	if attacker == null or attacker.is_dead() or attacker.faction == _dino.faction:
		return
	if state == State.IDLE:
		state = State.FLEE
		_dino.commands.clear()
	_think_timer = 0.0


func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()
