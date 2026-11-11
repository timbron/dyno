# Architecture

This file is the contract between agents. Change it in the same commit as the code.

## Scene flow

```
main_menu  ->  species_select  ->  strategic_map  <->  tactical
(Control)       (Control)           (Node2D)          (Node3D)
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
| `pack_mode_changed(following)` | SquadController | bool: true = follow, false = hold |
| `encounter_started(index)` | strategic map | encounter index |
| `xp_gained(amount)` | reserved for progression | int |

## Classes

| Class | File | Notes |
| --- | --- | --- |
| `SpeciesData` (Resource) | `src/dino/species_data.gd` | One `.tres` per species in `data/species/`. `playable`, `temperament`, `flee_health_fraction`, `bite_cooldown`, `meat`; `load_all()`, `load_playable()` |
| `Genome` (Resource) | `src/dino/genome.gd` | Heritable mutation ids, `inherit()` |
| `Dino` (CharacterBody3D) | `src/dino/dino.gd` | Body only: `move_intent`, `wants_sprint`, `commands`, `faction`, `take_damage(amount, attacker)`, `bite(target)`, `can_reach(target)`, `bite_ready()`, `is_dead()`, `health_fraction()`, `body_radius()`, `stage_for()`; local signals `damaged(amount, attacker)`, `died`, `bit(target, damage, zone)`; group `Dino.GROUP` |
| `TacticalCommand` | `src/tactical/tactical_command.gd` | `move_to()` and `attack()` work; `USE_ABILITY`, `WAIT` are stubs |
| `CombatMath` | `src/tactical/combat_math.gd` | Pure bite maths: `hit_zone()`, `bite_damage()`, `bite_reach()`, `in_reach()`, `in_bite_arc()` |
| `WildBrain` (Node) | `src/ai/wild_brain.gd` | Child of a wild `Dino`. States `IDLE`, `FLEE`, `ATTACK`; pure `decide()` |
| `AiProfile` (Resource) | `src/ai/ai_profile.gd` | Sight, safe, cornered and territory ranges, wander tuning. One `.tres` per temperament in `data/ai/` |
| `CommandQueue` | `src/tactical/command_queue.gd` | Per-dino FIFO; `remove_last()` drops the newest order |
| `OrderTargeting` | `src/tactical/order_targeting.gd` | Pure click-order maths: `ray_capsule_distance()`, `pick_radius()`, `pick_enemy()`, `command_destination()`, `path_points()` |
| `OrderPathPreview` (MeshInstance3D) | `src/tactical/order_path_preview.gd` | Ground ribbon and markers for the selected dino's queue; runs while paused |
| `Formation` | `src/tactical/formation.gd` | Pure wedge maths: `slot_offset()`, `slot_position()`, `spacing_for()` |
| `SquadController` | `src/tactical/squad_controller.gd` | Selection (living only), direct control, click orders, pack follow / hold: `pack_following`, `set_pack_following()`, `living()`, `order_move(point, append)`, `order_attack(target, append)`, `cancel_orders(last_only)` |
| `ThirdPersonCamera` | `src/camera/third_person_camera.gd` | `set_target()`; runs while paused |
| `Palette`, `JungleTheme` | `src/ui/` | Colours and Theme builder |

## Death and corpses

A `Dino` at zero health emits `died` and `EventBus.dino_died` once, clears its commands and
ignores intent from then on. It stays in the scene as a corpse: group `Dino.CORPSE_GROUP`,
physics layer `Dino.LAYER_CORPSE` (2) instead of `Dino.LAYER_BODY` (1), so the living walk
through it. Controllers and AI must check `is_dead()` before driving or targeting a dino.

The collision capsule is built per dino from `Dino.BASE_RADIUS` / `BASE_HEIGHT` times
`SpeciesData.body_scale`; use `body_radius()` for reach and spacing maths.

## Combat

A bite lands when the target is within `CombatMath.bite_reach()` (both body radii plus a
margin) and inside the attacker's 100 degree frontal arc, and the attacker's
`SpeciesData.bite_cooldown` has run out. Damage is `bite_damage` times a zone multiplier
taken from where the attacker stands relative to the target's facing: front 1.0 (within
60 degrees), flank 1.25, rear 1.5 (beyond 120 degrees).

An `ATTACK` command makes the dino run at its target, turn to face it and bite until the
target is dead, then the queue moves on. Dinos with the same `faction` never threaten or
target each other; the player's squad is `Dino.FACTION_PLAYER`, everything else defaults to
`Dino.FACTION_WILD`.

## Orders

Every click order goes through `SquadController.order_move()` / `order_attack()` /
`cancel_orders()`; mouse input only decides which one to call. A left click on a living
dino of another faction orders an attack, anywhere else a move to that point on the ground;
with `queue_modifier` (Ctrl) held the order is appended, otherwise it replaces the queue.
A right click cancels the selected dino's orders (with Ctrl only the newest); a right drag
is a camera orbit and cancels nothing. Enemies are picked by ray against an upright capsule
wider than the collision shape (`OrderTargeting.pick_radius()`), not by a physics query, so
picking works the same while paused and is not blocked by trees.

`OrderPathPreview` draws the selected dino's queue: move legs in `Palette.BONE`, attack
legs in `Palette.CLAY`, following a live target and dropping an order whose target died.

## Wild AI

`WildBrain.decide()` picks the state from the species temperament: no threat in sight is
idle; cornered (threat on top of it and out of stamina) always fights; hurt (below
`flee_health_fraction`) flees; otherwise skittish flees, predator attacks, territorial
attacks only threats inside its territory radius. Being bitten alerts a brain at once.

## Pack follow

Unselected living members follow the selected dino in a wedge (`Formation`) while
`SquadController.pack_following` is true; F toggles follow / hold. A member given a click
order holds where the order ends until the pack is told to follow again or it is driven
directly. Dinos never treat each other as moving platforms (`platform_floor_layers = 0`).

## Input actions

`move_forward/back/left/right`, `sprint`, `tactical_pause`, `select_next`, `queue_modifier`,
`toggle_pack_follow` (F),
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
- Encounters spawn no wild animals yet (T-03), so there is nothing to click on: attack
  orders, combat and AI run only in tests. No save/load, audio or real art.
- Only the selected dino takes click orders, and only its queue is previewed.
- Click-pick tuning (`PICK_RADIUS_SCALE`, `PICK_RADIUS_MARGIN`) is constants in
  `OrderTargeting`, not data.
- The arena has no edge handling: a fleeing animal runs off the ground plane (T-03).
- Combat tuning (arc, zone multipliers, reach margin) is constants in `CombatMath`,
  not data.
- Main menu "Continue" is disabled until save and load exist (C-01).
- UI screens were built without the "Dyno UI" design canvas; check them against it.
