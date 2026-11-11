class_name Dino
extends CharacterBody3D
## Body of any dinosaur on the tactical field, player-owned or wild.
## It never reads input. A controller (SquadController, later AI brains) sets
## [member move_intent] / [member wants_sprint] or fills [member commands].

enum AgeStage { HATCHLING, JUVENILE, ADULT, ELDER }

const TURN_SPEED: float = 8.0
const ACCELERATION: float = 18.0
const ARRIVE_DISTANCE: float = 0.6
const SPRINT_STAMINA_PER_SEC: float = 18.0
const STAMINA_REGEN_PER_SEC: float = 9.0

@export var species: SpeciesData

var display_label: String = "Dino"
var health: float = 100.0
var stamina: float = 100.0
var move_intent: Vector3 = Vector3.ZERO
var wants_sprint: bool = false
var commands: CommandQueue = CommandQueue.new()

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity", 9.8)

@onready var _visual: Node3D = $Visual


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
	# TODO(dino-core): scale the collision shape with the species as well.
	_visual.scale = Vector3.ONE * species.body_scale


func _physics_process(delta: float) -> void:
	_follow_commands()
	var direction := Vector3(move_intent.x, 0.0, move_intent.z).limit_length(1.0)
	var sprinting := wants_sprint and stamina > 0.0 and direction != Vector3.ZERO
	var speed := species.move_speed
	if sprinting:
		speed *= species.sprint_multiplier
	velocity.x = move_toward(velocity.x, direction.x * speed, ACCELERATION * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, ACCELERATION * delta)
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta
	if direction != Vector3.ZERO:
		var facing := atan2(-direction.x, -direction.z)
		rotation.y = lerp_angle(rotation.y, facing, TURN_SPEED * delta)
	var stamina_rate := -SPRINT_STAMINA_PER_SEC if sprinting else STAMINA_REGEN_PER_SEC
	stamina = clampf(stamina + stamina_rate * delta, 0.0, species.max_stamina)
	move_and_slide()


func take_damage(amount: float) -> void:
	if health <= 0.0:
		return
	health = maxf(health - amount, 0.0)
	if health == 0.0:
		EventBus.dino_died.emit(self)


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
