class_name Dino
extends CharacterBody3D
## Body of any dinosaur on the tactical field, player-owned or wild.
## It never reads input. A controller (SquadController, later AI brains) sets
## [member move_intent] / [member wants_sprint] or fills [member commands].
## At zero health it becomes a corpse: it stops acting, lies down and no longer blocks
## the living, but stays in the scene (group [constant CORPSE_GROUP]) to be fed on later.

## Emitted after health drops. [param attacker] may be null (starvation, hazards).
signal damaged(amount: float, attacker: Dino)
## Emitted once, together with [signal EventBus.dino_died].
signal died

enum AgeStage { HATCHLING, JUVENILE, ADULT, ELDER }

const TURN_SPEED: float = 8.0
const ACCELERATION: float = 18.0
const ARRIVE_DISTANCE: float = 0.6
const SPRINT_STAMINA_PER_SEC: float = 18.0
const STAMINA_REGEN_PER_SEC: float = 9.0
## Capsule of a body_scale 1.0 dino; the real shape is this times the species scale.
const BASE_RADIUS: float = 0.6
const BASE_HEIGHT: float = 2.0
const LAYER_BODY: int = 1
const LAYER_CORPSE: int = 2
const CORPSE_GROUP: StringName = &"corpses"
const CORPSE_ROLL: float = PI * 0.5

@export var species: SpeciesData

var display_label: String = "Dino"
var health: float = 100.0
var stamina: float = 100.0
var move_intent: Vector3 = Vector3.ZERO
var wants_sprint: bool = false
var commands: CommandQueue = CommandQueue.new()

var _dead: bool = false
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

@onready var _visual: Node3D = $Visual
@onready var _collision: CollisionShape3D = $Collision


static func stage_for(age_days: int, lifespan_days: int) -> AgeStage:
	var fraction := float(age_days) / float(maxi(lifespan_days, 1))
	if fraction < 0.1:
		return AgeStage.HATCHLING
	if fraction < 0.3:
		return AgeStage.JUVENILE
	if fraction < 0.8:
		return AgeStage.ADULT
	return AgeStage.ELDER


## Call before adding the dino to the tree.
func setup(species_data: SpeciesData, label: String) -> void:
	species = species_data
	display_label = label


func _ready() -> void:
	if species == null:
		species = SpeciesData.new()
	health = species.max_health
	stamina = species.max_stamina
	_visual.scale = Vector3.ONE * species.body_scale
	_fit_collision()


func _physics_process(delta: float) -> void:
	if _dead:
		_settle(delta)
		return
	_follow_commands()
	var direction := Vector3(move_intent.x, 0.0, move_intent.z).limit_length(1.0)
	var sprinting := wants_sprint and stamina > 0.0 and direction != Vector3.ZERO
	var speed := species.move_speed
	if sprinting:
		speed *= species.sprint_multiplier
	velocity.x = move_toward(velocity.x, direction.x * speed, ACCELERATION * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, ACCELERATION * delta)
	_apply_gravity(delta)
	if direction != Vector3.ZERO:
		var facing := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, facing, TURN_SPEED * delta)
	var stamina_rate := -SPRINT_STAMINA_PER_SEC if sprinting else STAMINA_REGEN_PER_SEC
	stamina = clampf(stamina + stamina_rate * delta, 0.0, species.max_stamina)
	move_and_slide()


func is_dead() -> bool:
	return _dead


func health_fraction() -> float:
	return health / maxf(species.max_health, 0.001)


## Radius of the body on the ground plane, for reach and spacing maths.
func body_radius() -> float:
	return BASE_RADIUS * species.body_scale


## Removes health. Zero or negative amounts and hits on a corpse are ignored.
func take_damage(amount: float, attacker: Dino = null) -> void:
	if _dead or amount <= 0.0:
		return
	health = maxf(health - amount, 0.0)
	damaged.emit(amount, attacker)
	if health == 0.0:
		_die()


func _die() -> void:
	_dead = true
	commands.clear()
	move_intent = Vector3.ZERO
	wants_sprint = false
	velocity.x = 0.0
	velocity.z = 0.0
	# Corpses rest on the ground but do not block the living.
	collision_layer = LAYER_CORPSE
	add_to_group(CORPSE_GROUP)
	if _visual != null:
		_visual.rotation.z = CORPSE_ROLL
		_visual.position.y = body_radius()
	died.emit()
	EventBus.dino_died.emit(self)


## A corpse only falls to the ground; it never moves on its own.
func _settle(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0
	_apply_gravity(delta)
	move_and_slide()


func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta


## The scene's shape is shared by every instance, so each dino gets its own scaled copy.
func _fit_collision() -> void:
	var capsule := CapsuleShape3D.new()
	capsule.radius = BASE_RADIUS * species.body_scale
	capsule.height = BASE_HEIGHT * species.body_scale
	_collision.shape = capsule
	_collision.position = Vector3(0.0, capsule.height * 0.5, 0.0)


func _follow_commands() -> void:
	var command := commands.current()
	if command == null:
		return
	if command.type != TacticalCommand.Type.MOVE_TO:
		# TODO(tactical): ATTACK, USE_ABILITY and WAIT are not implemented yet.
		commands.advance()
		return
	var offset := command.target_position - global_position
	offset.y = 0.0
	if offset.length() <= ARRIVE_DISTANCE:
		commands.advance()
		if commands.is_empty():
			move_intent = Vector3.ZERO
		return
	move_intent = offset.normalized()
