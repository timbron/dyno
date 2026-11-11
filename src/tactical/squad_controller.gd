class_name SquadController
extends Node
## Player control of the squad on the tactical field.
## - Tab cycles the selected dino among the living (a solo species has a squad of one).
## - WASD drives the selected dino directly, relative to the camera.
## - Left click orders the selected dino to move; hold Ctrl to append to its queue.
## - F switches the rest of the pack between following in formation and holding position.
##   A member that was given a click order holds where the order ends until the pack is
##   told to follow again.
## Orders can be given while paused, so this node always processes.

## Followers stop adjusting once this close to their formation slot.
const SLOT_TOLERANCE: float = 1.0
## Followers sprint to catch up when further than this from their slot.
const CATCH_UP_DISTANCE: float = 6.0

var members: Array[Dino] = []
var selected_index: int = 0
var pack_following: bool = true

var _holding: Array[Dino] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	EventBus.dino_died.connect(_on_dino_died)


func selected() -> Dino:
	if members.is_empty():
		return null
	return members[selected_index]


func living() -> Array[Dino]:
	return members.filter(func(dino: Dino) -> bool: return not dino.is_dead())


## Selects the member at [param index], or the next living one after it.
func select(index: int) -> void:
	if members.is_empty():
		return
	var previous := selected()
	if previous != null and previous.commands.is_empty():
		previous.move_intent = Vector3.ZERO
		previous.wants_sprint = false
	var start := wrapi(index, 0, members.size())
	selected_index = start
	for step in members.size():
		var candidate := wrapi(start + step, 0, members.size())
		if not members[candidate].is_dead():
			selected_index = candidate
			break
	EventBus.unit_selected.emit(selected())


func set_pack_following(following: bool) -> void:
	pack_following = following
	_holding.clear()
	if not following:
		for dino in _followers():
			_halt(dino)
	EventBus.pack_mode_changed.emit(pack_following)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"select_next"):
		select(selected_index + 1)
	elif event.is_action_pressed(&"toggle_pack_follow"):
		set_pack_following(not pack_following)
	elif event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			_order_move(click.position)


func _physics_process(_delta: float) -> void:
	if not TimeController.is_paused:
		_update_followers()
	var dino := selected()
	if dino == null or dino.is_dead():
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
	# Direct control overrides queued orders and puts the dino back in the pack.
	dino.commands.clear()
	_holding.erase(dino)
	dino.move_intent = right * input.x - forward * input.y


## Living members that take their place from the formation: not selected, not holding
## and not busy with their own orders.
func _followers() -> Array[Dino]:
	var leader := selected()
	var followers: Array[Dino] = []
	for dino in members:
		if dino == leader or dino.is_dead() or _holding.has(dino):
			continue
		if not dino.commands.is_empty():
			continue
		followers.append(dino)
	return followers


func _update_followers() -> void:
	var leader := selected()
	if leader == null or leader.is_dead() or not pack_following:
		return
	var followers := _followers()
	for slot in followers.size():
		var dino := followers[slot]
		var spacing := Formation.spacing_for(leader.body_radius(), dino.body_radius())
		var target := Formation.slot_position(
			leader.global_position, leader.rotation.y, slot, spacing
		)
		var offset := target - dino.global_position
		offset.y = 0.0
		var distance := offset.length()
		if distance <= SLOT_TOLERANCE:
			_halt(dino)
			continue
		dino.move_intent = offset / distance
		dino.wants_sprint = distance > CATCH_UP_DISTANCE


func _halt(dino: Dino) -> void:
	dino.move_intent = Vector3.ZERO
	dino.wants_sprint = false


func _on_dino_died(dino: Node3D) -> void:
	var dead := dino as Dino
	if dead == null or not members.has(dead):
		return
	_holding.erase(dead)
	if dead == selected() and not living().is_empty():
		select(selected_index + 1)


func _order_move(screen_position: Vector2) -> void:
	var dino := selected()
	var camera := get_viewport().get_camera_3d()
	if dino == null or dino.is_dead() or camera == null:
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
	if not _holding.has(dino):
		_holding.append(dino)
