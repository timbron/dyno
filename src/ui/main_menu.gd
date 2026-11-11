extends Control
## Title screen: start a new lineage, continue a saved one (once saving exists), or quit.

@onready var _background: ColorRect = $Background
@onready var _title: Label = $Center/Column/Title
@onready var _tagline: Label = $Center/Column/Tagline
@onready var _new_life: Button = $Center/Column/NewLife
@onready var _continue: Button = $Center/Column/Continue
@onready var _quit: Button = $Center/Column/Quit
@onready var _version: Label = $Version


func _ready() -> void:
	theme = JungleTheme.build()
	_background.color = Palette.CANOPY
	_title.add_theme_color_override(&"font_color", Palette.BONE)
	_tagline.add_theme_color_override(&"font_color", Palette.AMBER)
	_version.add_theme_color_override(&"font_color", Palette.LICHEN)
	_version.text = "v%s" % ProjectSettings.get_setting("application/config/version", "0.1")
	# TODO(orchestrator): enable when save and load exist (C-01).
	_continue.tooltip_text = "No saved lineage yet"
	_new_life.pressed.connect(_on_new_life)
	_quit.pressed.connect(_on_quit)
	_new_life.grab_focus()


func _on_new_life() -> void:
	SceneRouter.go_to(SceneRouter.SPECIES_SELECT)


func _on_quit() -> void:
	get_tree().quit()
