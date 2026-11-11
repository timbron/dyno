extends Control
## First screen of a run: choose the species (pack or solo hunter) for this lineage.

const SPECIES_PATHS: Array[String] = [
	"res://data/species/raptor.tres",
	"res://data/species/tyrannosaur.tres",
]


func _ready() -> void:
	theme = JungleTheme.build()

	var background := ColorRect.new()
	background.color = Palette.CANOPY
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 28)
	center.add_child(column)

	var title := JungleTheme.label("Choose your lineage", Palette.BONE, 34)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title)

	var cards := HBoxContainer.new()
	cards.add_theme_constant_override(&"separation", 24)
	column.add_child(cards)
	for path: String in SPECIES_PATHS:
		var species := load(path) as SpeciesData
		if species != null:
			cards.add_child(_build_card(species))


func _build_card(species: SpeciesData) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(360.0, 0.0)
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
	description.custom_minimum_size = Vector2(320.0, 90.0)
	box.add_child(description)

	var stats := "Health %d   Stamina %d   Speed %.1f   Bite %d   Lifespan %d days" % [
		int(species.max_health), int(species.max_stamina), species.move_speed,
		int(species.bite_damage), species.lifespan_days,
	]
	var stats_label := JungleTheme.label(stats, Palette.BONE, 12)
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(stats_label)

	var button := Button.new()
	button.text = "Begin life"
	button.pressed.connect(_on_species_chosen.bind(species))
	box.add_child(button)
	return card


func _on_species_chosen(species: SpeciesData) -> void:
	GameState.start_new_life(species)
	SceneRouter.go_to(SceneRouter.STRATEGIC_MAP)
