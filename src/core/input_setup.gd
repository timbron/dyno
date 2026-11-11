extends Node
## Registers input actions in code (autoload "InputSetup") so the bindings are
## readable in one place and never drift from project.godot.

const KEY_ACTIONS: Dictionary = {
	&"move_forward": [KEY_W, KEY_UP],
	&"move_back": [KEY_S, KEY_DOWN],
	&"move_left": [KEY_A, KEY_LEFT],
	&"move_right": [KEY_D, KEY_RIGHT],
	&"sprint": [KEY_SHIFT],
	&"tactical_pause": [KEY_SPACE],
	&"select_next": [KEY_TAB],
	&"queue_modifier": [KEY_CTRL],
	&"leave_encounter": [KEY_BACKSPACE],
	&"ability_1": [KEY_1],
	&"ability_2": [KEY_2],
	&"ability_3": [KEY_3],
	&"ability_4": [KEY_4],
}


func _ready() -> void:
	for action: StringName in KEY_ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for keycode in KEY_ACTIONS[action]:
			var event := InputEventKey.new()
			event.physical_keycode = keycode
			InputMap.action_add_event(action, event)
