class_name JungleTheme
extends RefCounted
## Builds the shared UI Theme in code. Assign the result to the root Control of a screen.
## HUD looks are theme type variations named by the constants below; scenes set
## [member Control.theme_type_variation] to one of them and never hold a colour.

const PANEL_ALPHA: float = 0.88

const SLOT_PANEL: StringName = &"SlotPanel"
const PAUSE_PANEL: StringName = &"PausePanel"
const RESULT_PANEL: StringName = &"ResultPanel"
const PORTRAIT_ROW: StringName = &"PortraitRow"
const PORTRAIT_ROW_SELECTED: StringName = &"PortraitRowSelected"
const CHIP_PANEL: StringName = &"ChipPanel"
const CHIP_PANEL_ATTACK: StringName = &"ChipPanelAttack"
const HEALTH_BAR: StringName = &"HealthBar"
const STAMINA_BAR: StringName = &"StaminaBar"
const LABEL_CAPTION: StringName = &"LabelCaption"
const LABEL_HINT: StringName = &"LabelHint"
const LABEL_STATUS: StringName = &"LabelStatus"
const LABEL_UNIT: StringName = &"LabelUnit"
const LABEL_UNIT_DIM: StringName = &"LabelUnitDim"
const LABEL_GLYPH: StringName = &"LabelGlyph"
const LABEL_CHIP: StringName = &"LabelChip"
const LABEL_PAUSE: StringName = &"LabelPause"
const LABEL_RESULT: StringName = &"LabelResult"


static func build() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 16

	var panel_color := Color(Palette.UNDERGROWTH, PANEL_ALPHA)
	theme.set_stylebox(&"panel", &"PanelContainer", flat_box(panel_color, Palette.BARK, 1, 4, 14))

	theme.set_color(&"font_color", &"Label", Palette.BONE)

	theme.set_stylebox(&"background", &"ProgressBar", flat_box(Palette.CANOPY, Palette.BARK, 1, 2))
	theme.set_stylebox(&"fill", &"ProgressBar", flat_box(Palette.FERN, Palette.FERN, 0, 2))

	theme.set_stylebox(&"normal", &"Button", flat_box(Palette.MOSS, Palette.BARK, 1, 4, 10))
	theme.set_stylebox(&"hover", &"Button", flat_box(Palette.FERN, Palette.LICHEN, 1, 4, 10))
	theme.set_stylebox(&"pressed", &"Button", flat_box(Palette.CANOPY, Palette.FERN, 1, 4, 10))
	theme.set_stylebox(&"focus", &"Button", flat_box(Color(0, 0, 0, 0), Palette.AMBER, 2, 4, 10))
	theme.set_color(&"font_color", &"Button", Palette.BONE)
	theme.set_color(&"font_hover_color", &"Button", Palette.BONE)
	theme.set_color(&"font_pressed_color", &"Button", Palette.LICHEN)

	var banner := Color(Palette.CANOPY, 0.92)
	var clear := Color(Palette.CANOPY, 0.0)
	_panel_variation(theme, SLOT_PANEL, flat_box(Palette.CANOPY, Palette.BARK, 1, 4, 6))
	_panel_variation(theme, PAUSE_PANEL, flat_box(banner, Palette.AMBER, 1, 4, 14))
	_panel_variation(theme, RESULT_PANEL, flat_box(banner, Palette.BARK, 1, 4, 18))
	_panel_variation(theme, PORTRAIT_ROW, flat_box(clear, clear, 0, 4, 6))
	_panel_variation(theme, PORTRAIT_ROW_SELECTED, flat_box(Palette.MOSS, Palette.FERN, 2, 4, 6))
	_panel_variation(theme, CHIP_PANEL, flat_box(Palette.CANOPY, Palette.BARK, 1, 4, 6))
	_panel_variation(theme, CHIP_PANEL_ATTACK, flat_box(Palette.CANOPY, Palette.CLAY, 1, 4, 6))

	theme.set_type_variation(HEALTH_BAR, &"ProgressBar")
	theme.set_stylebox(&"fill", HEALTH_BAR, flat_box(Palette.CLAY, Palette.CLAY, 0, 2))
	theme.set_type_variation(STAMINA_BAR, &"ProgressBar")
	theme.set_stylebox(&"fill", STAMINA_BAR, flat_box(Palette.RIVER, Palette.RIVER, 0, 2))

	_label_variation(theme, LABEL_CAPTION, Palette.LICHEN, 11)
	_label_variation(theme, LABEL_HINT, Palette.LICHEN, 12)
	_label_variation(theme, LABEL_STATUS, Palette.LICHEN, 14)
	_label_variation(theme, LABEL_UNIT, Palette.BONE, 18)
	_label_variation(theme, LABEL_UNIT_DIM, Palette.LICHEN, 18)
	_label_variation(theme, LABEL_GLYPH, Palette.BONE, 24)
	_label_variation(theme, LABEL_CHIP, Palette.BONE, 14)
	_label_variation(theme, LABEL_PAUSE, Palette.AMBER, 18)
	_label_variation(theme, LABEL_RESULT, Palette.AMBER, 22)
	return theme


static func flat_box(
	background: Color, border: Color, border_width: int, radius: int, padding: int = 0
) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = background
	box.border_color = border
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(radius)
	box.set_content_margin_all(padding)
	return box


static func label(text: String, color: Color = Palette.BONE, size: int = 16) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_color_override(&"font_color", color)
	node.add_theme_font_size_override(&"font_size", size)
	return node


static func _panel_variation(theme: Theme, name: StringName, box: StyleBoxFlat) -> void:
	theme.set_type_variation(name, &"PanelContainer")
	theme.set_stylebox(&"panel", name, box)


static func _label_variation(theme: Theme, name: StringName, color: Color, size: int) -> void:
	theme.set_type_variation(name, &"Label")
	theme.set_color(&"font_color", name, color)
	theme.set_font_size(&"font_size", name, size)
