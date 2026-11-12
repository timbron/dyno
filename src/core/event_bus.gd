extends Node
## Global signal hub (autoload "EventBus").
## Systems talk to each other through these signals instead of holding references.
## Add a signal here before emitting it anywhere; document payloads in docs/ARCHITECTURE.md.

signal life_started
signal day_passed(day: int)
signal tactical_pause_changed(paused: bool)
signal unit_selected(dino: Node3D)
## [param members] is the player's whole squad as Dino nodes, in squad order, dead included.
signal squad_changed(members: Array[Node3D])
signal dino_died(dino: Node3D)
signal pack_mode_changed(following: bool)
signal encounter_started(encounter_index: int)
## [param result] is an EncounterResult.
signal encounter_ended(result: RefCounted)
signal xp_gained(amount: int)
