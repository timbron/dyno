class_name JungleTheme
extends RefCounted
## Builds the shared UI Theme in code. Assign the result to the root Control of a screen.

const PANEL_ALPHA: float = 0.88


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
