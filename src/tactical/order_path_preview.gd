class_name OrderPathPreview
extends MeshInstance3D
## Draws the selected dino's queued orders on the ground: a ribbon through every
## waypoint, a marker at each stop and a larger one under an attack target.
## Rebuilt every frame and runs during tactical pause, so planning shows at once.

const LIFT: float = 0.08
const HALF_WIDTH: float = 0.09
const MOVE_MARKER: float = 0.35
const ATTACK_MARKER_MARGIN: float = 0.5
const ALPHA: float = 0.85

var _dino: Dino
var _mesh: ImmediateMesh = ImmediateMesh.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	top_level = true
	mesh = _mesh
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.disable_fog = true
	material_override = material
	EventBus.unit_selected.connect(_on_unit_selected)


func _process(_delta: float) -> void:
	_mesh.clear_surfaces()
	if not is_instance_valid(_dino) or _dino.is_dead() or _dino.commands.is_empty():
		return
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var from := _dino.global_position
	for command in _dino.commands.all():
		var destination: Variant = OrderTargeting.command_destination(command)
		if destination == null:
			continue
		var to: Vector3 = destination
		var attack := command.type == TacticalCommand.Type.ATTACK
		var color := Color(Palette.CLAY if attack else Palette.BONE, ALPHA)
		var marker := MOVE_MARKER
		if attack and command.target is Dino:
			marker = (command.target as Dino).body_radius() + ATTACK_MARKER_MARGIN
		_add_ribbon(from, to, color)
		_add_marker(to, marker, color)
		from = to
	_mesh.surface_end()


func _on_unit_selected(dino: Node3D) -> void:
	_dino = dino as Dino


func _add_ribbon(from: Vector3, to: Vector3, color: Color) -> void:
	var a := Vector3(from.x, from.y + LIFT, from.z)
	var b := Vector3(to.x, to.y + LIFT, to.z)
	var along := b - a
	along.y = 0.0
	if along.length() < 0.01:
		return
	var side := along.normalized().cross(Vector3.UP) * HALF_WIDTH
	_add_quad(a - side, a + side, b + side, b - side, color)


## A diamond lying on the ground around [param at].
func _add_marker(at: Vector3, radius: float, color: Color) -> void:
	var centre := Vector3(at.x, at.y + LIFT, at.z)
	_add_quad(
		centre + Vector3.FORWARD * radius,
		centre + Vector3.RIGHT * radius,
		centre + Vector3.BACK * radius,
		centre + Vector3.LEFT * radius,
		Color(color, color.a * 0.6)
	)


func _add_quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color) -> void:
	for vertex: Vector3 in [a, b, c, a, c, d]:
		_mesh.surface_set_color(color)
		_mesh.surface_add_vertex(vertex)
