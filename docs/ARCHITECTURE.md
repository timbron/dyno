# Architecture

This file is the contract between agents. Change it in the same commit as the code.

## Scene flow

```
species_select  ->  strategic_map  <->  tactical
   (Control)          (Node2D)          (Node3D)
```

`SceneRouter.go_to(path)` is the only way to change scene. `GameState` carries everything that
must survive the change.

## Autoloads (`src/core/`, load order)

| Name | Role | Public API |
| --- | --- | --- |
| `EventBus` | Global signals | see below |
| `InputSetup` | Registers input actions | `KEY_ACTIONS` |
| `GameState` | Run state | `species`, `genome`, `generation`, `day`, `hour`, `map_position`, `cleared_encounters`, `start_new_life()`, `party_size()`, `age_days()`, `advance_time()` |
| `TimeController` | Tactical pause | `is_paused`, `set_paused()` |
| `SceneRouter` | Scene changes | `go_to()`, path constants |

## Signals (`EventBus`)

| Signal | Emitted by | Payload |
| --- | --- | --- |
| `life_started` | GameState | none |
| `day_passed(day)` | GameState | new day number |
| `tactical_pause_changed(paused)` | TimeController | bool |
| `unit_selected(dino)` | SquadController | selected `Dino` |
| `dino_died(dino)` | Dino | the dead `Dino` |
| `encounter_started(index)` | strategic map | encounter index |
| `xp_gained(amount)` | reserved for progression | int |

## Classes

| Class | File | Notes |
| --- | --- | --- |
| `SpeciesData` (Resource) | `src/dino/species_data.gd` | One `.tres` per species in `data/species/` |
| `Genome` (Resource) | `src/dino/genome.gd` | Heritable mutation ids, `inherit()` |
| `Dino` (CharacterBody3D) | `src/dino/dino.gd` | Body only: `move_intent`, `wants_sprint`, `commands`, `take_damage(amount, attacker)`, `is_dead()`, `health_fraction()`, `body_radius()`, `stage_for()`; local signals `damaged(amount, attacker)`, `died` |
| `TacticalCommand` | `src/tactical/tactical_command.gd` | `MOVE_TO` works; `ATTACK`, `USE_ABILITY`, `WAIT` are stubs |
| `CommandQueue` | `src/tactical/command_queue.gd` | Per-dino FIFO |
| `SquadController` | `src/tactical/squad_controller.gd` | Selection, direct control, click orders |
| `ThirdPersonCamera` | `src/camera/third_person_camera.gd` | `set_target()`; runs while paused |
| `Palette`, `JungleTheme` | `src/ui/` | Colours and Theme builder |

## Death and corpses

A `Dino` at zero health emits `died` and `EventBus.dino_died` once, clears its commands and
ignores intent from then on. It stays in the scene as a corpse: group `Dino.CORPSE_GROUP`,
physics layer `Dino.LAYER_CORPSE` (2) instead of `Dino.LAYER_BODY` (1), so the living walk
through it. Controllers and AI must check `is_dead()` before driving or targeting a dino.

The collision capsule is built per dino from `Dino.BASE_RADIUS` / `BASE_HEIGHT` times
`SpeciesData.body_scale`; use `body_radius()` for reach and spacing maths.

## Input actions

`move_forward/back/left/right`, `sprint`, `tactical_pause`, `select_next`, `queue_modifier`,
`leave_encounter`, `ability_1..4`. Add new ones in `src/core/input_setup.gd`.

## Pause model

`TimeController` sets `get_tree().paused`. Camera, HUD and SquadController process always, so
the player can look around and issue orders. Dinos, AI, physics-driven gameplay and the clock
stop. The strategic map does not use tactical pause: time there passes only while travelling.

## Layer ownership

| Path | Owner brief |
| --- | --- |
| `src/core/`, `project.godot`, `docs/ARCHITECTURE.md` | orchestrator |
| `src/strategic/`, `scenes/strategic/`, `data/world/` | 01 strategic |
| `src/dino/`, `scenes/dino/`, `data/species/` | 02 dino core |
| `src/tactical/`, `src/camera/`, `scenes/tactical/` | 03 tactical |
| `src/ai/`, `data/ai/` | 04 AI |
| `src/progression/`, `data/abilities/`, `data/mutations/` | 05 progression |
| `src/ui/`, `scenes/ui/` | 06 UI |
| `assets/` | 07 art and audio |
| `tests/`, `.github/`, export presets | 08 QA and build |

## Known gaps in the scaffold

- Not yet run in the Godot editor: scripts are lint-clean only. First job is QA-01.
- Strategic regions and encounters are hard-coded constants (to be moved to data).
- Ground is the y = 0 plane; click orders intersect that plane, not terrain.
- Damage and death exist, but nothing deals damage yet (T-01). No AI, save/load, audio or
  real art.
- `SquadController` still selects and drives dead pack members (to fix in T-04).
