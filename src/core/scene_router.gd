extends Node
## Scene flow (autoload "SceneRouter"): species select -> strategic map <-> tactical.

const SPECIES_SELECT: String = "res://scenes/ui/species_select.tscn"
const STRATEGIC_MAP: String = "res://scenes/strategic/strategic_map.tscn"
const TACTICAL: String = "res://scenes/tactical/tactical.tscn"


func go_to(scene_path: String) -> void:
	TimeController.set_paused(false)
	get_tree().change_scene_to_file.call_deferred(scene_path)
