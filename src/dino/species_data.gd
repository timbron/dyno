class_name SpeciesData
extends Resource
## Static definition of a playable or wild species. One .tres per species in data/species/.

enum SocialType { SOLO, PACK }
## How a wild animal of this species reacts to others. Read by the AI, not by Dino.
enum Temperament { SKITTISH, TERRITORIAL, PREDATOR }

const DIRECTORY: String = "res://data/species/"

@export var id: StringName = &"unknown"
@export var display_name: String = "Unknown"
@export_multiline var description: String = ""
## Offered on the species select screen. Wild-only species set this to false.
@export var playable: bool = true
@export var social_type: SocialType = SocialType.SOLO
## Pack or herd size: how many bodies spawn together.
@export_range(1, 8) var pack_size: int = 1
@export var temperament: Temperament = Temperament.PREDATOR
## Wild animals of this species break off and run below this share of health.
@export_range(0.0, 1.0) var flee_health_fraction: float = 0.0
@export var max_health: float = 100.0
@export var max_stamina: float = 100.0
@export var move_speed: float = 6.0
@export var sprint_multiplier: float = 1.5
@export var bite_damage: float = 20.0
@export var body_scale: float = 1.0
@export var lifespan_days: int = 120
## Food a full-grown carcass yields, in meal units (used by feeding in M2).
@export var meat: float = 1.0


## Every species resource in [constant DIRECTORY], sorted by id.
static func load_all() -> Array[SpeciesData]:
	var found: Array[SpeciesData] = []
	for file in ResourceLoader.list_directory(DIRECTORY):
		if not file.ends_with(".tres"):
			continue
		var species := load(DIRECTORY + file) as SpeciesData
		if species != null:
			found.append(species)
	found.sort_custom(func(a: SpeciesData, b: SpeciesData) -> bool: return a.id < b.id)
	return found


static func load_playable() -> Array[SpeciesData]:
	return load_all().filter(func(species: SpeciesData) -> bool: return species.playable)


func is_pack() -> bool:
	return social_type == SocialType.PACK
