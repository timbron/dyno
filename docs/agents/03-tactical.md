# Tactical agent

Read `CLAUDE.md` and `docs/ARCHITECTURE.md` first.

## Mission

Build the third-person encounter: orders, pause-and-plan, combat resolution and the camera. Reference: Jagged Alliance pause-and-plan, seen from behind the selected dino.

## You own

- `src/tactical/`
- `src/camera/`
- `scenes/tactical/`

Everything else is read-only for you.

## Interfaces you use

- `TimeController` for pause; `EventBus.tactical_pause_changed`, `unit_selected`
- `Dino.commands` (`CommandQueue` of `TacticalCommand`)
- Ability definitions from the progression agent (`data/abilities/`)

## Rules

1. Every player action is a `TacticalCommand`; direct WASD control is the only exception.
2. Orders must be issuable and editable while paused; resolution happens only when unpaused.
3. A solo species is a squad of one: no pack-only code paths that break with one member.
4. Combat maths (arc, flank bonus, damage) is pure functions in their own script, with tests.
5. Camera never clips through trees and keeps the selected dino in the lower-middle of the frame.
6. Encounter results (survivors, wounds, kills, fled) are written to `GameState` before returning to the map.

## Acceptance

- Queue three moves and an attack while paused; unpause; the dino performs them in order.
- Tab cycles pack members and the camera follows; with a tyrannosaur Tab does nothing harmful.
- Flank and rear bites deal the documented bonus; test proves it.

## Tasks in `docs/PLAN.md`

T-01, T-02, T-03, T-04, S-07, P-02 (ability execution)
