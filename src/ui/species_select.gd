extends Control
## Choose the species (pack or solo hunter) for this lineage. Lists every playable
## species in data/species/. Esc or Back returns to the main menu.

const CARD_WIDTH: float = 360.0

var _first_button: Button


func _ready() -> void:
	theme = JungleTheme.build()

	var background := ColorRect.new()
	background.color = Palette.CANOPY
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 28)
	center.add_child(column)

	var title := JungleTheme.label("CHOOSE YOUR LINEAGE", Palette.BONE, 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	var cards := HBoxContainer.new()
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.add_theme_constant_override(&"separation", 24)
	column.add_child(cards)
	for species in SpeciesData.load_playable():
		cards.add_child(_build_card(species))

	var back := Button.new()
	back.text = "Back"
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.custom_minimum_size = Vector2(160.0, 0.0)
	back.pressed.connect(_go_back)
	column.add_child(back)

	if _first_button != null:
		_first_button.grab_focus()
	else:
		back.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_cancel"):
		_go_back()


func _build_card(species: SpeciesData) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(CARD_WIDTH, 0.0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 10)
	card.add_child(box)

	box.add_child(JungleTheme.label(species.display_name, Palette.BONE, 24))
	var kind := "SOLO HUNTER"
	if species.is_pack():
		kind = "PACK OF %d" % species.pack_size
	box.add_child(JungleTheme.label(kind, Palette.AMBER, 12))

	var description := JungleTheme.label(species.description, Palette.LICHEN, 14)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size = Vector2(CARD_WIDTH - 40.0, 90.0)
	box.add_child(description)

	box.add_child(_stat_row("HEALTH", species.max_health, 320.0, Palette.CLAY))
	box.add_child(_stat_row("STAMINA", species.max_stamina, 140.0, Palette.RIVER))
	box.add_child(_stat_row("SPEED", species.move_speed, 9.0, Palette.FERN))
	box.add_child(_stat_row("BITE", species.bite_damage, 60.0, Palette.AMBER))
	box.add_child(
		JungleTheme.label("Lifespan %d days" % species.lifespan_days, Palette.LICHEN, 12)
	)

	var button := Button.new()
	button.text = "Begin life"
	button.pressed.connect(_on_species_chosen.bind(species))
	box.add_child(button)
	if _first_button == null:
		_first_button = button
	return card


## A labelled bar with the number written out, so the stat never reads by colour alone.
func _stat_row(title: String, value: float, scale_max: float, fill: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 8)
	var name_label := JungleTheme.label(title, Palette.LICHEN, 12)
	name_label.custom_minimum_size = Vector2(70.0, 0.0)
	row.add_child(name_label)
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.max_value = scale_max
	bar.value = value
	bar.custom_minimum_size = Vector2(0.0, 12.0)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.add_theme_stylebox_override(&"fill", JungleTheme.flat_box(fill, fill, 0, 2))
	row.add_child(bar)
	var number := JungleTheme.label(String.num(value, 1).trim_suffix(".0"), Palette.BONE, 12)
	number.custom_minimum_size = Vector2(36.0, 0.0)
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(number)
	return row


func _go_back() -> void:
	SceneRouter.go_to(SceneRouter.MAIN_MENU)


func _on_species_chosen(species: SpeciesData) -> void:
	GameState.start_new_life(species)
	SceneRouter.go_to(SceneRouter.STRATEGIC_MAP)
