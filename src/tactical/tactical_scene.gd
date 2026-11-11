extends Node3D
## Root of an encounter. Builds a greybox arena, spawns the player's squad from
## GameState and wires selection to the camera. Backspace returns to the map.

const DINO_SCENE: PackedScene = preload("res://scenes/dino/dino.tscn")
const FALLBACK_SPECIES_PATH: String = "res://data/species/raptor.tres"
const ARENA_SIZE: float = 160.0
const TREE_COUNT: int = 70

@onready var _camera: ThirdPersonCamera = $CameraRig
@onready var _squad: SquadController = $Squad


func _ready() -> void:
	_build_environment()
	_build_ground()
	_scatter_trees()
	_spawn_squad()
	EventBus.unit_selected.connect(_on_unit_selected)
	_squad.select(0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"leave_encounter"):
		SceneRouter.go_to(SceneRouter.STRATEGIC_MAP)


func _on_unit_selected(dino: Node3D) -> void:
	_camera.set_target(dino)


func _spawn_squad() -> void:
	var species: SpeciesData = GameState.species
	if species == null:
		species = load(FALLBACK_SPECIES_PATH) as SpeciesData
	for i in species.pack_size:
		var dino := DINO_SCENE.instantiate() as Dino
		var label := species.display_name
		if species.pack_size > 1:
			label = "%s %d" % [species.display_name, i + 1]
		dino.setup(species, label)
		dino.faction = Dino.FACTION_PLAYER
		dino.position = Vector3((i - (species.pack_size - 1) * 0.5) * 3.0, 0.5, 0.0)
		add_child(dino)
		_squad.members.append(dino)


func _build_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.47, 0.54, 0.44)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.55, 0.62, 0.5)
	environment.ambient_light_energy = 0.6
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.47, 0.54, 0.44)
	environment.fog_density = 0.012
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)


func _build_ground() -> void:
	var size := Vector3(ARENA_SIZE, 1.0, ARENA_SIZE)
	var shape := BoxShape3D.new()
	shape.size = size
	var mesh := BoxMesh.new()
	mesh.size = size
	_add_static_body(Vector3(0.0, -0.5, 0.0), shape, mesh, Color(0.23, 0.29, 0.2))


func _scatter_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1977
	var half := ARENA_SIZE * 0.5 - 4.0
	for i in TREE_COUNT:
		var spot := Vector3(rng.randf_range(-half, half), 0.0, rng.randf_range(-half, half))
		if spot.length() < 8.0:
			continue
		var radius := rng.randf_range(0.4, 1.1)
		var height := rng.randf_range(7.0, 14.0)
		var shape := CylinderShape3D.new()
		shape.radius = radius
		shape.height = height
		var mesh := CylinderMesh.new()
		mesh.top_radius = radius * 0.8
		mesh.bottom_radius = radius
		mesh.height = height
		_add_static_body(spot + Vector3.UP * height * 0.5, shape, mesh, Color(0.29, 0.24, 0.19))


func _add_static_body(at: Vector3, shape: Shape3D, mesh: Mesh, color: Color) -> void:
	var body := StaticBody3D.new()
	body.position = at
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	add_child(body)
