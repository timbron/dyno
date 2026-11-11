extends Node2D
## Greybox strategic map (Battle Brothers style): click to travel, time passes only
## while moving, walking into a marker starts a tactical encounter.
## TODO(strategic): replace hard-coded regions and encounters with generated world data.

const TRAVEL_SPEED: float = 140.0
const HOURS_PER_SECOND: float = 2.0
const ENCOUNTER_RADIUS: float = 26.0
const REGIONS: Array[Dictionary] = [
	{"name": "Fern Lowlands", "at": Vector2(380.0, 520.0), "radius": 250.0, "tone": 0.0},
	{"name": "Cycad Forest", "at": Vector2(900.0, 330.0), "radius": 290.0, "tone": 1.0},
	{"name": "Mire", "at": Vector2(1230.0, 680.0), "radius": 210.0, "tone": 2.0},
]
const ENCOUNTERS: Array[Vector2] = [
	Vector2(700.0, 420.0), Vector2(1010.0, 250.0), Vector2(1180.0, 640.0),
]
## Which data/encounters/<id>.tres each marker starts, in the order of ENCOUNTERS.
const ENCOUNTER_IDS: Array[StringName] = [&"dryosaur_herd", &"allosaur_rival", &"contested_kill"]

var _destination: Vector2
var _status: Label


func _ready() -> void:
	_destination = GameState.map_position
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = JungleTheme.build()
	layer.add_child(root)
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status = JungleTheme.label("", Palette.BONE, 14)
	panel.add_child(_status)
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, 24)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var click := event as InputEventMouseButton
		if click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
			_destination = get_global_mouse_position()


func _process(delta: float) -> void:
	var position_now := GameState.map_position
	if position_now.distance_to(_destination) > 1.0:
		GameState.map_position = position_now.move_toward(_destination, TRAVEL_SPEED * delta)
		GameState.advance_time(HOURS_PER_SECOND * delta)
		_check_encounters()
	var species_name := GameState.species.display_name if GameState.species != null else "Dino"
	_status.text = "%s  ·  Day %d  ·  %02d:00  ·  Click to travel" % [
		species_name, GameState.day, int(GameState.hour)
	]
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Palette.CANOPY)
	for region: Dictionary in REGIONS:
		var tone: float = region["tone"]
		var color := Palette.MOSS.lerp(Palette.UNDERGROWTH, tone * 0.4)
		draw_circle(region["at"], region["radius"], color)
	for i in ENCOUNTERS.size():
		if GameState.cleared_encounters.has(i):
			continue
		draw_circle(ENCOUNTERS[i], 9.0, Palette.CLAY)
		draw_arc(ENCOUNTERS[i], ENCOUNTER_RADIUS, 0.0, TAU, 32, Color(Palette.CLAY, 0.5), 1.5)
	var here := GameState.map_position
	if here.distance_to(_destination) > 1.0:
		draw_dashed_line(here, _destination, Palette.LICHEN, 2.0, 8.0)
		draw_circle(_destination, 4.0, Palette.LICHEN)
	draw_circle(here, 11.0, Palette.BONE)
	draw_circle(here, 7.0, Palette.FERN)


func _check_encounters() -> void:
	for i in ENCOUNTERS.size():
		if GameState.cleared_encounters.has(i):
			continue
		var inside := GameState.map_position.distance_to(ENCOUNTERS[i]) <= ENCOUNTER_RADIUS
		if i == GameState.fled_encounter_index:
			# The party just retreated from this one: it triggers again only after it
			# has walked clear of the marker.
			if not inside:
				GameState.fled_encounter_index = -1
			continue
		if inside:
			GameState.begin_encounter(i, ENCOUNTER_IDS[i])
			SceneRouter.go_to(SceneRouter.TACTICAL)
			return
