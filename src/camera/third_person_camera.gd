class_name ThirdPersonCamera
extends Node3D
## Orbiting third-person camera for the tactical field.
## Hold right mouse to orbit, wheel to zoom. Keeps working during tactical pause
## so the player can look around while planning.

@export var distance: float = 8.0
@export var min_distance: float = 3.0
@export var max_distance: float = 22.0
@export var height_offset: float = 1.6
@export var mouse_sensitivity: float = 0.004
@export var zoom_step: float = 1.0
@export var follow_speed: float = 10.0

var _target: Node3D
var _arm: SpringArm3D
var _yaw: float = 0.0
var _pitch: float = 0.4


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_arm = SpringArm3D.new()
	_arm.spring_length = distance
	_arm.margin = 0.3
	add_child(_arm)
	var camera := Camera3D.new()
	camera.current = true
	_arm.add_child(camera)
	_apply_rotation()


func set_target(target: Node3D) -> void:
	_arm.clear_excluded_objects()
	_target = target
	if target is CollisionObject3D:
		_arm.add_excluded_object((target as CollisionObject3D).get_rid())


func _process(delta: float) -> void:
	if not is_instance_valid(_target):
		return
	var focus := _target.global_position + Vector3.UP * height_offset
	global_position = global_position.lerp(focus, clampf(follow_speed * delta, 0.0, 1.0))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
			var motion := event as InputEventMouseMotion
			_yaw -= motion.relative.x * mouse_sensitivity
			_pitch = clampf(_pitch + motion.relative.y * mouse_sensitivity, 0.05, 1.35)
			_apply_rotation()
	elif event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if not button.pressed:
			return
		if button.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(-zoom_step)
		elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(zoom_step)


func _zoom(amount: float) -> void:
	distance = clampf(distance + amount, min_distance, max_distance)
	_arm.spring_length = distance


func _apply_rotation() -> void:
	rotation = Vector3(0.0, _yaw, 0.0)
	_arm.rotation = Vector3(-_pitch, 0.0, 0.0)
