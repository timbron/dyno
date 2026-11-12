extends RefCounted
## Tactical HUD tests (U-01). Run by tests/suite.gd, which owns the counters.
## HudFormat is reached through load() and call(): naming some script classes from a test
## makes Godot 4.7 report leaked scripts when the run exits.

const DINO_SCENE: PackedScene = preload("res://scenes/dino/dino.tscn")
const FORMAT_PATH: String = "res://src/ui/hud_format.gd"
const HUD_PATH: String = "res://scenes/ui/hud.tscn"
const TACTICAL_SCENE: String = "res://scenes/tactical/tactical.tscn"
const LOOK_NORMAL: int = 0
const LOOK_SELECTED: int = 1
const LOOK_DEAD: int = 2

var _suite: RefCounted
var _format: GDScript
var _emitted: Array = []


func run(tree: SceneTree, suite: RefCounted) -> void:
	_suite = suite
	_format = load(FORMAT_PATH) as GDScript
	_test_glyph_look_state()
	_test_caption_and_status()
	await _test_order_labels(tree)
	await _test_squad_announce(tree)
	await _test_hud(tree)
	await _test_hud_layout(tree)
	await _test_freed_member(tree)
	await _test_tactical_hud(tree)


func _check(condition: bool, description: String) -> void:
	_suite.call("_check", condition, description)


func _fmt(method: StringName, args: Array = []) -> Variant:
	return _format.callv(method, args)


func _spawn_dino(tree: SceneTree, label: String = "Test") -> Dino:
	var dino := DINO_SCENE.instantiate() as Dino
	dino.setup(SpeciesData.new(), label)
	tree.root.add_child(dino)
	return dino


func _spawn_many(tree: SceneTree, count: int) -> Array[Dino]:
	var dinos: Array[Dino] = []
	for i in count:
		dinos.append(_spawn_dino(tree, "Raptor %d" % (i + 1)))
	return dinos


func _roster(dinos: Array[Dino]) -> Array[Node3D]:
	var roster: Array[Node3D] = []
	roster.assign(dinos)
	return roster


func _frames(tree: SceneTree, count: int = 2) -> void:
	for i in count:
		await tree.process_frame


func _free_all(tree: SceneTree, nodes: Array) -> void:
	for node: Node in nodes:
		if is_instance_valid(node):
			node.queue_free()
	await tree.process_frame


func _test_glyph_look_state() -> void:
	_check(_fmt(&"portrait_glyph", ["Raptor 2"]) == "R", "glyph is the first letter")
	_check(_fmt(&"portrait_glyph", ["  allosaur"]) == "A", "glyph skips spaces, upper-cases")
	_check(_fmt(&"portrait_glyph", [""]) == "?", "empty name gives ?")
	_check(_fmt(&"portrait_glyph", ["   "]) == "?", "blank name gives ?")
	_check(_fmt(&"member_look", [true, true]) == LOOK_DEAD, "dead beats selected")
	_check(_fmt(&"member_look", [false, true]) == LOOK_DEAD, "dead look")
	_check(_fmt(&"member_look", [true, false]) == LOOK_SELECTED, "selected look")
	_check(_fmt(&"member_look", [false, false]) == LOOK_NORMAL, "normal look")
	_check(_fmt(&"member_state", [false, true, 0]) == "DEAD", "dead state")
	_check(_fmt(&"member_state", [true, true, 4]) == "DEAD", "dead beats selected and orders")
	_check(_fmt(&"member_state", [true, false, 4]) == "SELECTED", "selected state")
	_check(_fmt(&"member_state", [false, false, 1]) == "1 ORDER", "one order")
	_check(_fmt(&"member_state", [false, false, 3]) == "3 ORDERS", "three orders")
	_check(_fmt(&"member_state", [false, false, 0]) == "", "no orders, no state word")


func _test_caption_and_status() -> void:
	_check(_fmt(&"pack_caption", [1, true]) == "SOLO", "one member is solo")
	_check(_fmt(&"pack_caption", [0, false]) == "SOLO", "no member is solo")
	_check((_fmt(&"pack_caption", [3, true]) as String).contains("FOLLOW"), "pack follows")
	_check((_fmt(&"pack_caption", [3, false]) as String).contains("HOLD"), "pack holds")
	var line: String = _fmt(&"status_line", [3, 14.6, 2, 1])
	_check(line.contains("Day 3"), "status has the day")
	_check(line.contains("14:00"), "status truncates the hour")
	_check(line.contains("Age 2"), "status has the age")
	_check(line.contains("Generation 1"), "status has the generation")
	_check((_fmt(&"status_line", [1, 6.0, 0, 1]) as String).contains("06:00"), "hour is padded")
	_check(_fmt(&"is_attack_label", ["2  ATTACK  TEST"]) == true, "attack label")
	_check(_fmt(&"is_attack_label", ["1  MOVE"]) == false, "move label is not attack")
	_check(_fmt(&"is_attack_label", ["+2"]) == false, "overflow label is not attack")


## A spot no dino can reach during a test, so a queued order never completes by itself.
func _far(index: int) -> Vector3:
	return Vector3(5000.0 + index * 100.0, 0.0, 5000.0)


func _moves(count: int) -> Array[TacticalCommand]:
	var commands: Array[TacticalCommand] = []
	for i in count:
		commands.append(TacticalCommand.move_to(Vector3(i, 0.0, 0.0)))
	return commands


func _test_order_labels(tree: SceneTree) -> void:
	var empty: Array[TacticalCommand] = []
	_check((_fmt(&"order_labels", [empty, 5]) as PackedStringArray).is_empty(), "no orders")
	var two: PackedStringArray = _fmt(&"order_labels", [_moves(2), 5])
	_check(two == PackedStringArray(["1  MOVE", "2  MOVE"]), "two moves are numbered")
	var victim := _spawn_dino(tree, "Test")
	var attack: Array[TacticalCommand] = [TacticalCommand.attack(victim)]
	var one: PackedStringArray = _fmt(&"order_labels", [attack, 5])
	_check(one.size() == 1 and one[0].contains("ATTACK"), "attack label says ATTACK")
	_check(one.size() == 1 and one[0].contains("TEST"), "attack label names the target")
	var mixed: Array[TacticalCommand] = [
		TacticalCommand.move_to(Vector3.ZERO),
		TacticalCommand.attack(victim),
		TacticalCommand.move_to(Vector3.ONE),
	]
	victim.take_damage(1000.0)
	var skipped: PackedStringArray = _fmt(&"order_labels", [mixed, 5])
	_check(skipped == PackedStringArray(["1  MOVE", "2  MOVE"]), "dead target skipped, numbers")
	var with_null: Array[TacticalCommand] = [null, TacticalCommand.move_to(Vector3.ZERO)]
	var nulls: PackedStringArray = _fmt(&"order_labels", [with_null, 5])
	_check(nulls == PackedStringArray(["1  MOVE"]), "null entries are skipped")
	var over: PackedStringArray = _fmt(&"order_labels", [_moves(7), 5])
	_check(over.size() == 6 and over[5] == "+2", "seven orders with max five end in +2")
	var exact: PackedStringArray = _fmt(&"order_labels", [_moves(5), 5])
	_check(exact.size() == 5 and not exact[4].begins_with("+"), "exactly max has no +")
	var none_fit: PackedStringArray = _fmt(&"order_labels", [_moves(3), 0])
	_check(none_fit == PackedStringArray(["+3"]), "max zero collapses everything")
	_check((_fmt(&"order_labels", [empty, 0]) as PackedStringArray).is_empty(), "max zero, none")
	await _free_all(tree, [victim])


func _on_squad_changed(members: Array[Node3D]) -> void:
	_emitted.append(members.duplicate())


func _test_squad_announce(tree: SceneTree) -> void:
	_emitted.clear()
	EventBus.squad_changed.connect(_on_squad_changed)
	var squad := SquadController.new()
	tree.root.add_child(squad)
	squad.select(0)
	_check(_emitted.is_empty(), "an empty squad announces nothing")
	var dinos := _spawn_many(tree, 3)
	for dino in dinos:
		squad.members.append(dino)
	squad.select(0)
	_check(_emitted.size() == 1, "first select announces once")
	var first: Array = _emitted[0] if not _emitted.is_empty() else []
	var in_order := first.size() == 3
	for i in mini(first.size(), 3):
		in_order = in_order and first[i] == dinos[i]
	_check(in_order, "announced list has the members in order")
	squad.select(1)
	_check(_emitted.size() == 1, "select with an unchanged list does not announce")
	var fourth := _spawn_dino(tree, "Fourth")
	squad.members.append(fourth)
	squad.select(0)
	_check(_emitted.size() == 2 and _emitted[1].size() == 4, "a longer list announces again")
	dinos[2].take_damage(1000.0)
	squad.select(0)
	_check(_emitted.size() == 2, "a death does not announce")
	EventBus.squad_changed.disconnect(_on_squad_changed)
	await _free_all(tree, [squad, fourth] + dinos)


func _make_hud(tree: SceneTree) -> CanvasLayer:
	var hud := (load(HUD_PATH) as PackedScene).instantiate() as CanvasLayer
	tree.root.add_child(hud)
	await _frames(tree)
	return hud


func _rows(hud: Node) -> Array[Node]:
	return hud.get_node("%SquadList").get_children()


func _row_state(row: Node) -> String:
	return (row.get_node("%State") as Label).text


func _strip_chips(hud: Node) -> int:
	return hud.get_node("%OrderStrip").call("chip_count")


func _test_hud(tree: SceneTree) -> void:
	var hud := await _make_hud(tree)
	_check(hud.process_mode == Node.PROCESS_MODE_ALWAYS, "HUD runs while paused")
	var dinos := _spawn_many(tree, 10)
	var three: Array[Dino] = dinos.slice(0, 3)
	EventBus.squad_changed.emit(_roster(three))
	await _frames(tree)
	_check(_rows(hud).size() == 3, "three members give three rows")
	_check((hud.get_node("%PackLabel") as Label).text.contains("FOLLOW"), "pack caption follows")
	var eight: Array[Dino] = dinos.slice(0, 8)
	EventBus.squad_changed.emit(_roster(eight))
	await _frames(tree)
	_check(_rows(hud).size() == 8, "eight members give eight rows")
	EventBus.squad_changed.emit(_roster(dinos))
	await _frames(tree)
	_check(_rows(hud).size() == 8, "ten members are capped at eight rows")
	var two: Array[Dino] = dinos.slice(0, 2)
	EventBus.squad_changed.emit(_roster(two))
	await _frames(tree)
	_check(_rows(hud).size() == 2, "a new announcement replaces the rows")

	EventBus.squad_changed.emit(_roster(three))
	await _frames(tree)
	EventBus.unit_selected.emit(dinos[1])
	await _frames(tree)
	var rows := _rows(hud)
	_check(_row_state(rows[1]) == "SELECTED", "selected row says SELECTED")
	_check(_row_state(rows[0]) != "SELECTED", "first row is not selected")
	_check(_row_state(rows[2]) != "SELECTED", "last row is not selected")
	_check(rows[1].theme_type_variation == &"PortraitRowSelected", "selected row has its frame")
	_check(rows[0].theme_type_variation == &"PortraitRow", "other rows have the plain frame")

	var hurt := dinos[0]
	hurt.take_damage(10.0)
	await _frames(tree)
	var bar := rows[0].get_node("%HealthBar") as ProgressBar
	_check(is_equal_approx(bar.value, hurt.health), "health bar follows health")
	_check(is_equal_approx(bar.max_value, hurt.species.max_health), "health bar max is species")

	dinos[2].commands.enqueue(TacticalCommand.move_to(_far(0)))
	dinos[2].commands.enqueue(TacticalCommand.move_to(_far(1)))
	await _frames(tree)
	_check(_row_state(rows[2]) == "2 ORDERS", "an unselected member shows its order count")
	dinos[2].commands.clear()

	EventBus.pack_mode_changed.emit(false)
	_check((hud.get_node("%PackLabel") as Label).text.contains("HOLD"), "pack caption holds")
	EventBus.pack_mode_changed.emit(true)

	dinos[2].take_damage(1000.0)
	await _frames(tree)
	_check(_row_state(rows[2]) == "DEAD", "a dead member's row says DEAD")
	_check((rows[2].get_node("%Glyph") as Label).text == "X", "a dead member's glyph is X")
	_check((rows[2].get_node("%HealthBar") as ProgressBar).value == 0.0, "dead: empty bar")
	_check((rows[2].get_node("%StaminaBar") as ProgressBar).value == 0.0, "dead: empty stamina")

	var result := EncounterResult.new()
	result.outcome = EncounterResult.Outcome.WON
	EventBus.encounter_ended.emit(result)
	_check((hud.get_node("%ResultBanner") as Control).visible, "result banner shows")
	_check((hud.get_node("%ResultLabel") as Label).text.contains("THE FIELD IS YOURS"), "WON text")

	# Solo fallback: nobody announced a squad.
	var solo_hud := await _make_hud(tree)
	EventBus.unit_selected.emit(dinos[3])
	await _frames(tree)
	_check(_rows(solo_hud).size() == 1, "a selection with no squad gives one row")
	_check((solo_hud.get_node("%PackLabel") as Label).text == "SOLO", "one row is SOLO")
	EventBus.unit_selected.emit(null)
	await _frames(tree)
	_check(_rows(solo_hud).size() == 1, "a null selection keeps the rows")
	solo_hud.queue_free()

	# Pause visibility and order strip.
	EventBus.squad_changed.emit(_roster(three))
	EventBus.unit_selected.emit(dinos[0])
	await _frames(tree)
	_check(not (hud.get_node("%PauseWash") as Control).visible, "pause wash starts hidden")
	_check(not (hud.get_node("%OrderStrip") as Control).visible, "order strip starts hidden")
	EventBus.tactical_pause_changed.emit(true)
	await _frames(tree)
	for node_name in ["%PauseWash", "%PauseBanner", "%OrderStrip"]:
		_check((hud.get_node(node_name) as Control).visible, "%s shows when paused" % node_name)
	var strip := hud.get_node("%OrderStrip")
	_check((strip.get_node("Row/Empty") as Control).visible, "no orders: hint is visible")
	_check(_strip_chips(hud) == 0, "no orders: no chips")
	for i in 2:
		dinos[0].commands.enqueue(TacticalCommand.move_to(_far(i)))
	await _frames(tree)
	_check(_strip_chips(hud) == 2, "two orders give two chips")
	_check(not (strip.get_node("Row/Empty") as Control).visible, "orders hide the hint")
	for i in 5:
		dinos[0].commands.enqueue(TacticalCommand.move_to(_far(i + 2)))
	await _frames(tree)
	_check(_strip_chips(hud) == 6, "seven orders give five chips and an overflow chip")
	var unclickable := true
	var stack: Array[Node] = [hud]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		stack.append_array(node.get_children())
		if node is Control and (node as Control).mouse_filter != Control.MOUSE_FILTER_IGNORE:
			unclickable = false
			printerr("takes mouse: %s" % node.get_path())
	_check(unclickable, "every HUD control ignores the mouse")
	dinos[0].commands.clear()
	await _frames(tree)
	_check(_strip_chips(hud) == 0, "cleared queue clears the chips")
	EventBus.tactical_pause_changed.emit(false)
	await _frames(tree)
	for node_name in ["%PauseWash", "%PauseBanner", "%OrderStrip"]:
		_check(not (hud.get_node(node_name) as Control).visible, "%s hides on resume" % node_name)
	await _free_all(tree, [hud] + dinos)


func _test_hud_layout(tree: SceneTree) -> void:
	var hud := await _make_hud(tree)
	var dinos := _spawn_many(tree, 8)
	EventBus.squad_changed.emit(_roster(dinos))
	EventBus.unit_selected.emit(dinos[0])
	for i in 7:
		dinos[0].commands.enqueue(TacticalCommand.move_to(_far(i)))
	EventBus.tactical_pause_changed.emit(true)
	await _frames(tree, 4)
	var view := hud.get_viewport().get_visible_rect()
	var middle := Rect2(view.position + view.size * 0.25, view.size * 0.5)
	var names := ["SquadPanel", "BottomCentre", "PauseBanner", "StatusPanel", "HintPanel"]
	var rects := {}
	for panel_name in names:
		var node := hud.find_child(panel_name, true, false) as Control
		var rect := node.get_global_rect()
		rects[panel_name] = rect
		_check(not rect.intersects(middle), "%s stays out of the screen middle" % panel_name)
		_check(view.encloses(rect), "%s is on screen" % panel_name)
	var squad_rect: Rect2 = rects["SquadPanel"]
	_check(not squad_rect.intersects(rects["StatusPanel"]), "squad panel clears status")
	_check(not squad_rect.intersects(rects["BottomCentre"]), "squad panel clears the bottom")
	var row_rects: Array[Rect2] = []
	for row in _rows(hud):
		row_rects.append((row as Control).get_global_rect())
	var apart := row_rects.size() == 8
	for i in row_rects.size():
		for j in range(i + 1, row_rects.size()):
			apart = apart and not row_rects[i].intersects(row_rects[j])
	_check(apart, "eight portrait rows do not overlap")
	EventBus.tactical_pause_changed.emit(false)
	await _free_all(tree, [hud] + dinos)


func _test_freed_member(tree: SceneTree) -> void:
	var hud := await _make_hud(tree)
	var dinos := _spawn_many(tree, 3)
	EventBus.squad_changed.emit(_roster(dinos))
	EventBus.unit_selected.emit(dinos[1])
	EventBus.tactical_pause_changed.emit(true)
	await _frames(tree)
	dinos[1].queue_free()
	await _frames(tree, 3)
	var rows := _rows(hud)
	_check(rows.size() == 3 and _row_state(rows[1]) == "DEAD", "a freed member reads DEAD")
	_check((rows[1].get_node("%Name") as Label).text == "Raptor 2", "freed member keeps name")
	_check(_strip_chips(hud) == 0, "a freed selection shows no chips")
	EventBus.tactical_pause_changed.emit(false)
	await _free_all(tree, [hud, dinos[0], dinos[2]])


func _test_tactical_hud(tree: SceneTree) -> void:
	var species_before := GameState.species
	GameState.species = load("res://data/species/raptor.tres") as SpeciesData
	GameState.begin_encounter(-1, &"contested_kill")
	var scene := (load(TACTICAL_SCENE) as PackedScene).instantiate()
	tree.root.add_child(scene)
	await _frames(tree, 10)
	var hud: Node = null
	for node in scene.find_children("*", "CanvasLayer", true, false):
		if node.has_node("%SquadList"):
			hud = node
	_check(hud != null, "the tactical scene has the HUD")
	if hud != null:
		_check(_rows(hud).size() == GameState.species.pack_size, "one row per pack member")
	scene.queue_free()
	await tree.process_frame
	GameState.species = species_before
	GameState.pending_encounter_index = -1
	GameState.pending_encounter_id = &""
