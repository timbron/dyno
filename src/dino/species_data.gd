class_name SpeciesData
extends Resource
## Static definition of a playable or wild species. One .tres per species in data/species/.

enum SocialType { SOLO, PACK }

@export var id: StringName = &"unknown"
@export var display_name: String = "Unknown"
@export_multiline var description: String = ""
@export var social_type: SocialType = SocialType.SOLO
@export_range(1, 8) var pack_size: int = 1
@export var max_health: float = 100.0
@export var max_stamina: float = 100.0
@export var move_speed: float = 6.0
@export var sprint_multiplier: float = 1.5
@export var bite_damage: float = 20.0
@export var body_scale: float = 1.0
@export var lifespan_days: int = 120


func is_pack() -> bool:
	return social_type == SocialType.PACK
