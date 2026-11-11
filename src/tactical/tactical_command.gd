class_name TacticalCommand
extends RefCounted
## One order in a dino's queue. Orders are issued live or while paused and run in sequence.

enum Type { MOVE_TO, ATTACK, USE_ABILITY, WAIT }

var type: Type = Type.MOVE_TO
var target_position: Vector3 = Vector3.ZERO
var target: Node3D
var ability_id: StringName = &""
var duration: float = 0.0


static func move_to(position: Vector3) -> TacticalCommand:
	var command := TacticalCommand.new()
	command.type = Type.MOVE_TO
	command.target_position = position
	return command
