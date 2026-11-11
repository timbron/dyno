class_name Formation
extends RefCounted
## Pure maths for where pack members stand relative to their leader.
## The shape is a wedge behind the leader: followers alternate left and right, one row
## further back for every pair. Local frame: -Z is the leader's facing, +X its right.

## Sideways step per row, as a share of the spacing.
const WEDGE_SPREAD: float = 0.8
## Clear ground kept between two bodies standing in formation.
const BODY_GAP: float = 1.0


## Offset of follower [param index] (0 = first follower) in the leader's local frame.
static func slot_offset(index: int, spacing: float) -> Vector3:
	var row := index / 2 + 1
	var side := -1.0 if index % 2 == 0 else 1.0
	return Vector3(side * row * spacing * WEDGE_SPREAD, 0.0, row * spacing)


## World position of follower [param index] for a leader at [param leader_position]
## turned [param leader_yaw] radians about the Y axis.
static func slot_position(
	leader_position: Vector3, leader_yaw: float, index: int, spacing: float
) -> Vector3:
	return leader_position + slot_offset(index, spacing).rotated(Vector3.UP, leader_yaw)


## Spacing that keeps two bodies of the given ground radii from touching.
static func spacing_for(leader_radius: float, follower_radius: float) -> float:
	return leader_radius + follower_radius + BODY_GAP
