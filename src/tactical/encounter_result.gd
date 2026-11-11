class_name EncounterResult
extends RefCounted
## How an encounter ended and what it cost. The tactical scene fills one in and hands it
## to GameState.record_encounter() before the map comes back.

enum Outcome { ONGOING, WON, FLED, DIED }

var outcome: Outcome = Outcome.ONGOING
## Squad members alive at the end, and their health as a share of full (0..1).
var survivors: int = 0
var wounds: Array[float] = []
## Squad members killed.
var lost: int = 0
## Species id of every wild animal killed.
var kills: Array[StringName] = []
## Wild animals that got away over the arena edge.
var escaped: int = 0
## Meal units lying on the field (SpeciesData.meat of every kill).
var meat: float = 0.0


## The state of an encounter this instant. Pure.
## A wiped squad is a death whatever else happened; a retreat beats a win on the same frame.
static func decide(squad_alive: int, wild_remaining: int, retreated: bool) -> Outcome:
	if squad_alive <= 0:
		return Outcome.DIED
	if retreated:
		return Outcome.FLED
	if wild_remaining <= 0:
		return Outcome.WON
	return Outcome.ONGOING
