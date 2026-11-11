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


func start_new_life(chosen: SpeciesData) -> void:
	species = chosen
	day = 1
	hour = 6.0
	cleared_encounters.clear()
	EventBus.life_started.emit()


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
