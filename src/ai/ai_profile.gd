class_name AiProfile
extends Resource
## Tuning for a WildBrain. One .tres per behaviour style in data/ai/.
## What the animal wants (flee or fight) comes from SpeciesData.temperament; this says
## how far it sees and how it moves while doing it.

## Dinos of another faction inside this range are noticed.
@export var sight_range: float = 22.0
## A fleeing animal calms down once every threat is beyond this range.
@export var safe_range: float = 34.0
## A threat this close to an animal too tired to run is fought instead.
@export var cornered_range: float = 4.0
## Share of stamina under which the animal counts as too tired to run.
@export_range(0.0, 1.0) var exhausted_stamina_fraction: float = 0.15
## A territorial animal attacks only threats this close to where it started.
@export var territory_radius: float = 16.0
## Seconds between two looks around. Brains start at a random point in the interval.
@export var think_interval: float = 0.25
## Idle wandering: how far from the starting spot, and the pause between strolls.
@export var wander_radius: float = 8.0
@export var wander_pause_min: float = 2.0
@export var wander_pause_max: float = 6.0
