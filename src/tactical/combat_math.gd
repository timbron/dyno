class_name CombatMath
extends RefCounted
## Pure combat formulas: where a bite lands, whether it can land, and what it does.
## Angles are about the Y axis; a body with yaw 0 faces -Z (Godot's forward).

## Which side of the target the attacker stands on.
enum Zone { FRONT, FLANK, REAR }

## Half-width of the cone in front of the attacker that its jaws cover.
const BITE_HALF_ARC: float = deg_to_rad(50.0)
## Target's front zone: attacker within this angle of the target's facing.
const FRONT_HALF_ANGLE: float = deg_to_rad(60.0)
## Beyond this angle from the target's facing the attacker is behind it.
const REAR_START_ANGLE: float = deg_to_rad(120.0)
const FLANK_MULTIPLIER: float = 1.25
const REAR_MULTIPLIER: float = 1.5
## Gap the jaws can close beyond the two bodies touching.
const REACH_MARGIN: float = 0.7


static func facing(yaw: float) -> Vector3:
	return Vector3.FORWARD.rotated(Vector3.UP, yaw)


## Unsigned angle between where a body at [param from] with [param yaw] faces and the
## direction to [param to], ignoring height. 0 = dead ahead, PI = directly behind.
static func angle_off_facing(from: Vector3, yaw: float, to: Vector3) -> float:
	var direction := Vector3(to.x - from.x, 0.0, to.z - from.z)
	if direction.is_zero_approx():
		return 0.0
	return facing(yaw).angle_to(direction)


static func hit_zone(
	attacker_position: Vector3, target_position: Vector3, target_yaw: float
) -> Zone:
	var angle := angle_off_facing(target_position, target_yaw, attacker_position)
	if angle <= FRONT_HALF_ANGLE:
		return Zone.FRONT
	if angle < REAR_START_ANGLE:
		return Zone.FLANK
	return Zone.REAR


static func zone_multiplier(zone: Zone) -> float:
	match zone:
		Zone.FLANK:
			return FLANK_MULTIPLIER
		Zone.REAR:
			return REAR_MULTIPLIER
	return 1.0


static func bite_damage(base_damage: float, zone: Zone) -> float:
	return base_damage * zone_multiplier(zone)


## Centre-to-centre distance at which a bite connects.
static func bite_reach(attacker_radius: float, target_radius: float) -> float:
	return attacker_radius + target_radius + REACH_MARGIN


static func in_reach(
	attacker_position: Vector3, attacker_radius: float, target_position: Vector3,
	target_radius: float
) -> bool:
	var offset := target_position - attacker_position
	offset.y = 0.0
	return offset.length() <= bite_reach(attacker_radius, target_radius)


static func in_bite_arc(
	attacker_position: Vector3, attacker_yaw: float, target_position: Vector3
) -> bool:
	return angle_off_facing(attacker_position, attacker_yaw, target_position) <= BITE_HALF_ARC
