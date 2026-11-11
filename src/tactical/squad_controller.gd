class_name SquadController
extends Node
## Player control of the squad on the tactical field.
## - Tab cycles the selected dino (a solo species has a squad of one).
## - WASD drives the selected dino directly, relative to the camera.
## - Left click orders the selected dino to move; hold Ctrl to append to its queue.
## Orders can be given while paused, so this node always processes.

var members: Array[Dino] = []
var selected_index: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func selected() -> Dino:
	if members.is_empty():
		return null
	return members[selected_index]


func select(index: int) -> void:
	if members.is_empty():
		return
	var previous := selected()
	if previous != null and previous.commands.is_empty():
		previous.move_intent = Vector3.ZERO
		previous.wants_sprint = false
	selected_index = wrapi(index, 0, members.size())
	EventBus.unit_selected.emit(selected())


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"select_next"):
		select(selected_index + 1)
	elif event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			_order_move(click.position)


func _physics_process(_delta: float) -> void:
	var dino := selected()
	if dino == null:
		return
	var input := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	dino.wants_sprint = Input.is_action_pressed(&"sprint")
	if input == Vector2.ZERO:
		if dino.commands.is_empty():
			dino.move_intent = Vector3.ZERO
		return
	if TimeController.is_paused:
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var forward := -camera.global_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := camera.global_basis.x
	right.y = 0.0
	right = right.normalized()
	# Direct control overrides queued orders.
	dino.commands.clear()
	dino.move_intent = right * input.x - forward * input.y


func _order_move(screen_position: Vector2) -> void:
	var dino := selected()
	var camera := get_viewport().get_camera_3d()
	if dino == null or camera == null:
		return
	var origin := camera.project_ray_origin(screen_position)
	var normal := camera.project_ray_normal(screen_position)
	# Greybox ground is the y = 0 plane. TODO(tactical): raycast against terrain.
	var hit: Variant = Plane(Vector3.UP, 0.0).intersects_ray(origin, normal)
	if hit == null:
		return
	if not Input.is_action_pressed(&"queue_modifier"):
		dino.commands.clear()
	var point: Vector3 = hit
	dino.commands.enqueue(TacticalCommand.move_to(point))
