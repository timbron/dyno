extends Node3D
## Root of an encounter. Builds a greybox arena, spawns the player's squad from
## GameState and the wild animals from the pending EncounterData, wires selection to the
## camera and sends the EncounterResult back through GameState when the director calls
## the encounter over. Backspace retreats.

const DINO_SCENE: PackedScene = preload("res://scenes/dino/dino.tscn")
const FALLBACK_SPECIES_PATH: String = "res://data/species/raptor.tres"
const FALLBACK_ENCOUNTER: StringName = &"dryosaur_herd"
## Ground beyond the arena edge, so an animal that crosses it does not fall off the world.
const GROUND_MARGIN: float = 14.0
const TREE_COUNT: int = 70
## No tree this close to the squad or to where a wild animal starts.
const SPAWN_CLEARING: float = 5.0
const EDGE_POSTS: int = 60
## Seconds the field stays up after a win or a wipe before the scene changes.
const END_DELAY: float = 3.0
const SQUAD_TINT: Color = Color(0.42, 0.56, 0.38)
const PREY_TINT: Color = Color(0.66, 0.6, 0.42)
const HUNTER_TINT: Color = Color(0.58, 0.28, 0.21)

var _encounter: EncounterData

@onready var _camera: ThirdPersonCamera = $CameraRig
@onready var _squad: SquadController = $Squad
@onready var _director: EncounterDirector = $Director


func _ready() -> void:
	_encounter = EncounterData.load_by_id(GameState.pending_encounter_id)
	if _encounter == null:
		_encounter = EncounterData.load_by_id(FALLBACK_ENCOUNTER)
	_build_environment()
	_build_ground()
	_scatter_trees()
	_mark_edge()
	_spawn_squad()
	_spawn_wild()
	_director.arena_radius = _encounter.arena_radius
	_director.finished.connect(_on_encounter_finished)
	EventBus.unit_selected.connect(_on_unit_selected)
	_squad.select(0)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"leave_encounter"):
		_director.finish(EncounterResult.Outcome.FLED)


func _on_unit_selected(dino: Node3D) -> void:
	_camera.set_target(dino)


## Results go to GameState before the scene changes. A retreat leaves at once; a win or a
## wipe leaves the field up for a moment so the player sees how it ended.
func _on_encounter_finished(result: EncounterResult) -> void:
	GameState.record_encounter(result)
	if result.outcome == EncounterResult.Outcome.FLED:
		SceneRouter.go_to(SceneRouter.STRATEGIC_MAP)
		return
	var next := SceneRouter.STRATEGIC_MAP
	if result.outcome == EncounterResult.Outcome.DIED:
		next = SceneRouter.MAIN_MENU
	# Connected to this node, so the timer does nothing if the scene is gone by then.
	get_tree().create_timer(END_DELAY).timeout.connect(_leave.bind(next))


func _leave(scene_path: String) -> void:
	SceneRouter.go_to(scene_path)


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
		dino.set_tint(SQUAD_TINT)
		_squad.members.append(dino)
		_director.squad.append(dino)


func _spawn_wild() -> void:
	for group in _encounter.groups:
		if group.species == null:
			continue
		var spots := group.positions()
		var predator := group.species.temperament != SpeciesData.Temperament.SKITTISH
		for i in spots.size():
			var dino := DINO_SCENE.instantiate() as Dino
			dino.setup(group.species, "%s %d" % [group.species.display_name, i + 1])
			dino.position = spots[i] + Vector3.UP * 0.5
			dino.rotation.y = i * EncounterGroup.GOLDEN_ANGLE
			var brain := WildBrain.new()
			brain.name = "Brain"
			dino.add_child(brain)
			add_child(dino)
			dino.set_tint(HUNTER_TINT if predator else PREY_TINT)
			_director.wild.append(dino)


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
	var side := (_encounter.arena_radius + GROUND_MARGIN) * 2.0
	var size := Vector3(side, 1.0, side)
	var shape := BoxShape3D.new()
	shape.size = size
	var mesh := BoxMesh.new()
	mesh.size = size
	_add_static_body(Vector3(0.0, -0.5, 0.0), shape, mesh, Color(0.23, 0.29, 0.2))


func _scatter_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1977
	var half := _encounter.arena_radius + GROUND_MARGIN - 4.0
	var clearings: Array[Vector3] = [Vector3.ZERO]
	for group in _encounter.groups:
		clearings.append_array(group.positions())
	for i in TREE_COUNT:
		var spot := Vector3(rng.randf_range(-half, half), 0.0, rng.randf_range(-half, half))
		var clear := true
		for clearing in clearings:
			clear = clear and spot.distance_to(clearing) >= SPAWN_CLEARING
		if not clear:
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


## A ring of low posts on the arena edge: crossing it is a retreat (or an escape).
func _mark_edge() -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.12
	mesh.bottom_radius = 0.12
	mesh.height = 1.2
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.87, 0.84, 0.76)
	material.roughness = 1.0
	for i in EDGE_POSTS:
		var angle := TAU * i / EDGE_POSTS
		var post := MeshInstance3D.new()
		post.mesh = mesh
		post.material_override = material
		post.position = Vector3(cos(angle), 0.0, sin(angle)) * _encounter.arena_radius
		post.position.y = mesh.height * 0.5
		add_child(post)


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
