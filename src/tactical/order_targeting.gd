class_name OrderTargeting
extends RefCounted
## Pure maths behind click orders: which dino a camera ray points at and where an order
## leads, for the path preview. No input and no scene access.

## Returned by [method ray_capsule_distance] when the ray passes the capsule by.
const MISS: float = -1.0
const RAY_LENGTH: float = 500.0
## Click targets are wider than the collision capsule: the body sticks out past it and a
## moving animal is hard to hit exactly.
const PICK_RADIUS_SCALE: float = 1.5
const PICK_RADIUS_MARGIN: float = 0.25


## Distance along the ray to the point nearest an upright capsule standing on
## [param base], or [constant MISS] when the ray passes further than [param radius]
## from the capsule's axis.
static func ray_capsule_distance(
	origin: Vector3, direction: Vector3, base: Vector3, radius: float, height: float
) -> float:
	if direction.is_zero_approx():
		return MISS
	var far := origin + direction.normalized() * RAY_LENGTH
	var low := base + Vector3.UP * radius
	var high := base + Vector3.UP * maxf(height - radius, radius + 0.01)
	var closest := Geometry3D.get_closest_points_between_segments(origin, far, low, high)
	if closest[0].distance_to(closest[1]) > radius:
		return MISS
	return origin.distance_to(closest[0])


static func pick_radius(body_radius: float) -> float:
	return body_radius * PICK_RADIUS_SCALE + PICK_RADIUS_MARGIN


## The living dino nearest the ray's origin that the ray points at and that is not of
## [param own_faction]; null when there is none.
static func pick_enemy(
	origin: Vector3, direction: Vector3, candidates: Array[Dino], own_faction: StringName
) -> Dino:
	var best: Dino = null
	var best_distance := INF
	for dino in candidates:
		if not is_instance_valid(dino) or dino.is_dead() or dino.faction == own_faction:
			continue
		var radius := pick_radius(dino.body_radius())
		var height := Dino.BASE_HEIGHT * dino.species.body_scale
		var distance := ray_capsule_distance(
			origin, direction, dino.global_position, radius, height
		)
		if distance != MISS and distance < best_distance:
			best = dino
			best_distance = distance
	return best


## Where [param command] takes a dino: a Vector3, or null when the order leads nowhere
## (its target is dead or gone, or the order has no place).
static func command_destination(command: TacticalCommand) -> Variant:
	if command == null:
		return null
	if command.type == TacticalCommand.Type.MOVE_TO:
		return command.target_position
	if command.type != TacticalCommand.Type.ATTACK:
		return null
	if not is_instance_valid(command.target) or not command.target.is_inside_tree():
		return null
	var victim := command.target as Dino
	if victim != null and victim.is_dead():
		return null
	return command.target.global_position


## The points a dino at [param start] passes through while it works off [param commands].
static func path_points(start: Vector3, commands: Array[TacticalCommand]) -> PackedVector3Array:
	var points := PackedVector3Array([start])
	for command in commands:
		var destination: Variant = command_destination(command)
		if destination != null:
			points.append(destination as Vector3)
	return points
