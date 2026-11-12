extends CanvasLayer
## Tactical HUD: day and age readout, squad portraits with vitals, ability slots, pause
## wash and banner, the selected dino's order strip and the encounter result banner.
## Layout lives in scenes/ui/hud.tscn; looks come from JungleTheme type variations.
## Everything is learned from EventBus, GameState and the Dino nodes the signals carry.
## No HUD control takes mouse input, so every click reaches the SquadController.

const MAX_PORTRAITS: int = 8
const WASH_ALPHA: float = 0.25
const PORTRAIT_SCENE: PackedScene = preload("res://scenes/ui/squad_portrait.tscn")

var _squad: Array[Dino] = []
var _selected: Dino
var _pack_following: bool = true
var _portraits: Array[SquadPortrait] = []

@onready var _root: Control = %Root
@onready var _pause_wash: ColorRect = %PauseWash
@onready var _status_label: Label = %StatusLabel
@onready var _pack_label: Label = %PackLabel
@onready var _result_label: Label = %ResultLabel
@onready var _squad_list: VBoxContainer = %SquadList
@onready var _pause_banner: PanelContainer = %PauseBanner
@onready var _result_banner: PanelContainer = %ResultBanner
@onready var _order_strip: OrderStrip = %OrderStrip


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root.theme = JungleTheme.build()
	_pause_wash.color = Color(Palette.CANOPY, WASH_ALPHA)
	_result_banner.visible = false
	_apply_pause(TimeController.is_paused)
	_refresh_pack_label()
	_ignore_mouse(self)
	EventBus.squad_changed.connect(_on_squad_changed)
	EventBus.unit_selected.connect(_on_unit_selected)
	EventBus.tactical_pause_changed.connect(_on_pause_changed)
	EventBus.pack_mode_changed.connect(_on_pack_mode_changed)
	EventBus.encounter_ended.connect(_on_encounter_ended)


func _process(_delta: float) -> void:
	_status_label.text = HudFormat.status_line(
		GameState.day, GameState.hour, GameState.age_days(), GameState.generation
	)
	for portrait in _portraits:
		portrait.refresh(portrait.dino == _selected and is_instance_valid(_selected))
	if _order_strip.visible:
		_order_strip.show_orders(_selected if is_instance_valid(_selected) else null)


func _on_squad_changed(members: Array[Node3D]) -> void:
	var dinos: Array[Dino] = []
	for member in members:
		if not is_instance_valid(member):
			continue
		var dino := member as Dino
		if dino != null:
			dinos.append(dino)
		if dinos.size() >= MAX_PORTRAITS:
			break
	_set_squad(dinos)


func _set_squad(dinos: Array[Dino]) -> void:
	_squad = dinos
	for child in _squad_list.get_children():
		_squad_list.remove_child(child)
		child.queue_free()
	_portraits.clear()
	for i in dinos.size():
		var portrait := PORTRAIT_SCENE.instantiate() as SquadPortrait
		_squad_list.add_child(portrait)
		portrait.setup(dinos[i], i + 1)
		_ignore_mouse(portrait)
		_portraits.append(portrait)
	_refresh_pack_label()


func _on_unit_selected(dino: Node3D) -> void:
	_selected = dino as Dino
	if _selected != null and not _squad.has(_selected):
		var solo: Array[Dino] = [_selected]
		_set_squad(solo)


func _on_pause_changed(paused: bool) -> void:
	_apply_pause(paused)


func _apply_pause(paused: bool) -> void:
	_pause_wash.visible = paused
	_pause_banner.visible = paused
	_order_strip.visible = paused


func _on_pack_mode_changed(following: bool) -> void:
	_pack_following = following
	_refresh_pack_label()


func _refresh_pack_label() -> void:
	_pack_label.text = HudFormat.pack_caption(_squad.size(), _pack_following)


func _on_encounter_ended(result: RefCounted) -> void:
	var ended := result as EncounterResult
	if ended == null:
		return
	var color := Palette.AMBER
	var text := "RETREAT"
	if ended.outcome == EncounterResult.Outcome.WON:
		text = "THE FIELD IS YOURS\n%d killed  ·  %d escaped" % [
			ended.kills.size(), ended.escaped
		]
	elif ended.outcome == EncounterResult.Outcome.DIED:
		color = Palette.CLAY
		text = "YOUR LINE ENDS HERE"
	_result_label.text = text
	_result_label.add_theme_color_override(&"font_color", color)
	_result_banner.visible = true


func _ignore_mouse(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_ignore_mouse(child)
