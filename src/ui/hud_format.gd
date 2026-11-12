class_name HudFormat
extends RefCounted
## Pure text and state logic for the tactical HUD. No scene access.

enum Look { NORMAL, SELECTED, DEAD }

const ATTACK_WORD: String = "ATTACK"
const MOVE_WORD: String = "MOVE"


## The letter shown on a member's portrait tile: the first character of the name,
## upper-cased, or "?" when the name is blank.
static func portrait_glyph(display_name: String) -> String:
	var stripped := display_name.strip_edges()
	if stripped.is_empty():
		return "?"
	return stripped.left(1).to_upper()


## How a portrait row is drawn. Death wins over selection.
static func member_look(selected: bool, dead: bool) -> Look:
	if dead:
		return Look.DEAD
	if selected:
		return Look.SELECTED
	return Look.NORMAL


## The state word on a portrait row.
static func member_state(selected: bool, dead: bool, order_count: int) -> String:
	if dead:
		return "DEAD"
	if selected:
		return "SELECTED"
	if order_count == 1:
		return "1 ORDER"
	if order_count > 1:
		return "%d ORDERS" % order_count
	return ""


## The squad panel header: solo, or the pack mode.
static func pack_caption(member_count: int, following: bool) -> String:
	if member_count <= 1:
		return "SOLO"
	if following:
		return "PACK  ·  FOLLOW"
	return "PACK  ·  HOLD"


static func status_line(day: int, hour: float, age_days: int, generation: int) -> String:
	return "Day %d  ·  %02d:00  ·  Age %d d  ·  Generation %d" % [
		day, int(hour), age_days, generation
	]


## Chip labels for the orders in [param commands] that still lead somewhere, numbered
## from 1 like the path preview. Past [param max_chips] the rest collapse into one "+n".
static func order_labels(commands: Array[TacticalCommand], max_chips: int) -> PackedStringArray:
	var live: PackedStringArray = PackedStringArray()
	for command in commands:
		if command == null or OrderTargeting.command_destination(command) == null:
			continue
		var number := live.size() + 1
		if command.type == TacticalCommand.Type.ATTACK:
			var victim := command.target as Dino
			if victim != null:
				live.append("%d  %s  %s" % [number, ATTACK_WORD, victim.display_label.to_upper()])
			else:
				live.append("%d  %s" % [number, ATTACK_WORD])
		else:
			live.append("%d  %s" % [number, MOVE_WORD])
	var limit := maxi(max_chips, 0)
	if live.size() <= limit:
		return live
	var labels := live.slice(0, limit)
	labels.append("+%d" % (live.size() - limit))
	return labels


static func is_attack_label(text: String) -> bool:
	return text.contains(ATTACK_WORD)
