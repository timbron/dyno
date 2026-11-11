extends Node
## Run-wide state that survives scene changes (autoload "GameState").
## One "life" = one generation of the lineage. Save/load will serialise this node.

const HOURS_PER_DAY: float = 24.0

var species: SpeciesData
var genome: Genome = Genome.new()
var generation: int = 1
var day: int = 1
var hour: float = 6.0
var map_position: Vector2 = Vector2(360.0, 520.0)
var cleared_encounters: Array[int] = []
## Hand-off from the map to the tactical scene: which map marker was walked into and
## which data/encounters/<id>.tres to set up. Index -1 means none.
var pending_encounter_index: int = -1
var pending_encounter_id: StringName = &""
## Marker the party retreated from; the map leaves it alone until the party has moved off.
var fled_encounter_index: int = -1
## Result of the most recent encounter, null before the first.
var last_encounter: EncounterResult


func start_new_life(chosen: SpeciesData) -> void:
	species = chosen
	day = 1
	hour = 6.0
	cleared_encounters.clear()
	pending_encounter_index = -1
	pending_encounter_id = &""
	fled_encounter_index = -1
	last_encounter = null
	EventBus.life_started.emit()


## The map calls this as the party walks into a marker, before going to the tactical scene.
func begin_encounter(index: int, encounter_id: StringName) -> void:
	pending_encounter_index = index
	pending_encounter_id = encounter_id
	EventBus.encounter_started.emit(index)


## The tactical scene calls this once, before leaving. A won encounter is cleared from the
## map; one the party fled stays and is remembered in [member fled_encounter_index].
func record_encounter(result: EncounterResult) -> void:
	last_encounter = result
	var index := pending_encounter_index
	pending_encounter_index = -1
	pending_encounter_id = &""
	if index >= 0:
		if result.outcome == EncounterResult.Outcome.WON:
			if not cleared_encounters.has(index):
				cleared_encounters.append(index)
		elif result.outcome == EncounterResult.Outcome.FLED:
			fled_encounter_index = index
	EventBus.encounter_ended.emit(result)


func party_size() -> int:
	return species.pack_size if species != null else 1


func age_days() -> int:
	return day - 1


func advance_time(hours: float) -> void:
	hour += hours
	while hour >= HOURS_PER_DAY:
		hour -= HOURS_PER_DAY
		day += 1
		EventBus.day_passed.emit(day)
