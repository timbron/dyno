class_name CommandQueue
extends RefCounted
## FIFO list of TacticalCommand for one dino.

signal changed

var _commands: Array[TacticalCommand] = []


func enqueue(command: TacticalCommand) -> void:
	_commands.append(command)
	changed.emit()


func current() -> TacticalCommand:
	return _commands[0] if not _commands.is_empty() else null


func advance() -> void:
	if not _commands.is_empty():
		_commands.pop_front()
		changed.emit()


func clear() -> void:
	if not _commands.is_empty():
		_commands.clear()
		changed.emit()


func is_empty() -> bool:
	return _commands.is_empty()


func size() -> int:
	return _commands.size()


func all() -> Array[TacticalCommand]:
	return _commands.duplicate()
