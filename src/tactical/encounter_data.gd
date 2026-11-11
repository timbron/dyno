class_name EncounterData
extends Resource
## Who is on the field in one kind of encounter. One .tres per encounter in
## data/encounters/, named after its id.

const DIRECTORY: String = "res://data/encounters/"

@export var id: StringName = &"unknown"
@export var display_name: String = "Encounter"
## Animals and the squad's leader that cross this distance from the centre have left.
@export var arena_radius: float = 70.0
@export var groups: Array[EncounterGroup] = []


## The encounter stored as data/encounters/<id>.tres, or null when there is none.
static func load_by_id(encounter_id: StringName) -> EncounterData:
	var path := "%s%s.tres" % [DIRECTORY, encounter_id]
	if encounter_id == &"" or not ResourceLoader.exists(path):
		return null
	return load(path) as EncounterData


## Every encounter resource in [constant DIRECTORY], sorted by id.
static func load_all() -> Array[EncounterData]:
	var found: Array[EncounterData] = []
	for file in ResourceLoader.list_directory(DIRECTORY):
		if not file.ends_with(".tres"):
			continue
		var encounter := load(DIRECTORY + file) as EncounterData
		if encounter != null:
			found.append(encounter)
	found.sort_custom(func(a: EncounterData, b: EncounterData) -> bool: return a.id < b.id)
	return found


func body_count() -> int:
	var total := 0
	for group in groups:
		total += group.body_count()
	return total
