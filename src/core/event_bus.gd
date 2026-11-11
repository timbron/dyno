extends Node
## Global signal hub (autoload "EventBus").
## Systems talk to each other through these signals instead of holding references.
## Add a signal here before emitting it anywhere; document payloads in docs/ARCHITECTURE.md.

signal life_started
signal day_passed(day: int)
signal tactical_pause_changed(paused: bool)
signal unit_selected(dino: Node3D)
signal dino_died(dino: Node3D)
signal encounter_started(encounter_index: int)
signal xp_gained(amount: int)
