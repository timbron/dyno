class_name EncounterGroup
extends Resource
## One herd, pack or lone animal in an EncounterData: which species, how many and where
## they stand relative to the player's squad, which starts at the arena centre facing -Z.

const GOLDEN_ANGLE: float = 2.399963

@export var species: SpeciesData
## Bodies to spawn; 0 uses the pack_size of the species.
@export_range(0, 24) var count: int = 0
## Metres from the arena centre to the middle of the group.
@export var distance: float = 35.0
## Direction of the group seen from the squad: 0 straight ahead, 90 to its right.
@export_range(-180.0, 180.0) var bearing_degrees: float = 0.0
## Metres between neighbours in the group.
@export var spread: float = 3.0


func body_count() -> int:
	if count > 0:
		return count
	return species.pack_size if species != null else 0


func centre() -> Vector3:
	var bearing := deg_to_rad(bearing_degrees)
	return Vector3(sin(bearing), 0.0, -cos(bearing)) * distance


## Ground position of every body: a loose spiral around [method centre], the same every
## time so an encounter is reproducible.
func positions() -> Array[Vector3]:
	var spots: Array[Vector3] = []
	var middle := centre()
	for i in body_count():
		var angle := i * GOLDEN_ANGLE
		var reach := spread * sqrt(float(i))
		spots.append(middle + Vector3(cos(angle), 0.0, sin(angle)) * reach)
	return spots
