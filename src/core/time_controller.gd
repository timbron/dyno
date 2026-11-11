extends Node
## Tactical pause (autoload "TimeController").
## Pausing freezes the simulation; nodes that must keep working while the player
## plans (camera, HUD, squad orders) set process_mode = PROCESS_MODE_ALWAYS.

var is_paused: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"tactical_pause"):
		set_paused(not is_paused)


func set_paused(paused: bool) -> void:
	if paused == is_paused:
		return
	is_paused = paused
	get_tree().paused = paused
	EventBus.tactical_pause_changed.emit(paused)
