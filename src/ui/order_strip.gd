class_name OrderStrip
extends PanelContainer
## The selected dino's live orders as chips, numbered like the path preview on the ground.
## The HUD shows it only while paused and calls show_orders() every frame; the strip
## rebuilds its chips only when the labels change.

const MAX_CHIPS: int = 5
const CHIP_MAX_WIDTH: float = 170.0

var _shown: PackedStringArray = PackedStringArray()

@onready var _empty: Label = $Row/Empty
@onready var _chips: HBoxContainer = $Row/Chips


func show_orders(dino: Dino) -> void:
	var labels := PackedStringArray()
	if is_instance_valid(dino) and not dino.is_dead():
		labels = HudFormat.order_labels(dino.commands.all(), MAX_CHIPS)
	_empty.visible = labels.is_empty()
	_chips.visible = not labels.is_empty()
	if labels == _shown:
		return
	_shown = labels
	for child in _chips.get_children():
		_chips.remove_child(child)
		child.queue_free()
	for text in labels:
		_add_chip(text)


func chip_count() -> int:
	return _chips.get_child_count()


func _add_chip(text: String) -> void:
	var chip := PanelContainer.new()
	if HudFormat.is_attack_label(text):
		chip.theme_type_variation = JungleTheme.CHIP_PANEL_ATTACK
	else:
		chip.theme_type_variation = JungleTheme.CHIP_PANEL
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := Label.new()
	label.text = text
	label.theme_type_variation = JungleTheme.LABEL_CHIP
	chip.add_child(label)
	_chips.add_child(chip)
	var natural_width := label.get_minimum_size().x
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.custom_minimum_size.x = minf(CHIP_MAX_WIDTH, natural_width)
