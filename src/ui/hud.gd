extends CanvasLayer
## Tactical HUD: selected-dino vitals, day/age readout, ability slots, pause banner.
## Greybox layout built in code; final layout follows docs/UI_STYLE.md.

const EDGE: int = 24
const BAR_SIZE: Vector2 = Vector2(240.0, 12.0)

var _dino: Dino
var _name_label: Label
var _health_bar: ProgressBar
var _stamina_bar: ProgressBar
var _status_label: Label
var _pause_banner: PanelContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = JungleTheme.build()
	add_child(root)

	_place(root, _build_vitals(), Control.PRESET_BOTTOM_LEFT)
	_place(root, _build_status(), Control.PRESET_TOP_LEFT)
	_place(root, _build_abilities(), Control.PRESET_CENTER_BOTTOM)
	_place(root, _build_hints(), Control.PRESET_BOTTOM_RIGHT)
	_pause_banner = _build_pause_banner()
	_place(root, _pause_banner, Control.PRESET_CENTER_TOP)
	_pause_banner.visible = false

	EventBus.unit_selected.connect(_on_unit_selected)
	EventBus.tactical_pause_changed.connect(_on_pause_changed)


func _process(_delta: float) -> void:
	_status_label.text = "Day %d  ·  %02d:00  ·  Generation %d" % [
		GameState.day, int(GameState.hour), GameState.generation
	]
	if not is_instance_valid(_dino):
		return
	_health_bar.max_value = _dino.species.max_health
	_health_bar.value = _dino.health
	_stamina_bar.max_value = _dino.species.max_stamina
	_stamina_bar.value = _dino.stamina


func _on_unit_selected(dino: Node3D) -> void:
	_dino = dino as Dino
	if _dino != null:
		_name_label.text = _dino.display_label


func _on_pause_changed(paused: bool) -> void:
	_pause_banner.visible = paused


func _place(root: Control, panel: Control, preset: Control.LayoutPreset) -> void:
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_MINSIZE, EDGE)
	var bottom := [
		Control.PRESET_BOTTOM_LEFT, Control.PRESET_CENTER_BOTTOM, Control.PRESET_BOTTOM_RIGHT
	]
	if preset in bottom:
		panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	if preset == Control.PRESET_BOTTOM_RIGHT:
		panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	if preset in [Control.PRESET_CENTER_BOTTOM, Control.PRESET_CENTER_TOP]:
		panel.grow_horizontal = Control.GROW_DIRECTION_BOTH


func _build_vitals() -> PanelContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 6)
	_name_label = JungleTheme.label("Dino", Palette.BONE, 18)
	box.add_child(_name_label)
	box.add_child(JungleTheme.label("HEALTH", Palette.LICHEN, 11))
	_health_bar = _bar(Palette.CLAY)
	box.add_child(_health_bar)
	box.add_child(JungleTheme.label("STAMINA", Palette.LICHEN, 11))
	_stamina_bar = _bar(Palette.RIVER)
	box.add_child(_stamina_bar)
	return _panel(box)


func _build_status() -> PanelContainer:
	_status_label = JungleTheme.label("Day 1", Palette.LICHEN, 14)
	return _panel(_status_label)


func _build_abilities() -> PanelContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 8)
	for i in 4:
		var slot := PanelContainer.new()
		slot.custom_minimum_size = Vector2(56.0, 56.0)
		slot.add_theme_stylebox_override(
			&"panel", JungleTheme.flat_box(Palette.CANOPY, Palette.BARK, 1, 4, 6)
		)
		slot.add_child(JungleTheme.label(str(i + 1), Palette.LICHEN, 12))
		row.add_child(slot)
	return _panel(row)


func _build_hints() -> PanelContainer:
	var text := "WASD move  ·  Click move / attack  ·  Ctrl+Click queue\n"
	text += "Tab next dino  ·  F pack follow / hold  ·  Space pause\n"
	text += "RMB cancel orders  ·  RMB drag orbit  ·  Backspace leave"
	return _panel(JungleTheme.label(text, Palette.LICHEN, 12))


func _build_pause_banner() -> PanelContainer:
	var panel := _panel(JungleTheme.label("PAUSED  —  PLAN YOUR MOVES", Palette.AMBER, 18))
	panel.add_theme_stylebox_override(
		&"panel", JungleTheme.flat_box(Color(Palette.CANOPY, 0.92), Palette.AMBER, 1, 4, 14)
	)
	return panel


func _panel(content: Control) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_child(content)
	return panel


func _bar(fill: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = BAR_SIZE
	bar.add_theme_stylebox_override(&"fill", JungleTheme.flat_box(fill, fill, 0, 2))
	return bar
