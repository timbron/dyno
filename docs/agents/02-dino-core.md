# Dino core agent

Read `CLAUDE.md` and `docs/ARCHITECTURE.md` first.

## Mission

Own the dinosaur itself: the body every player and wild animal shares, species definitions, health and wounds, size and ageing.

## You own

- `src/dino/`
- `scenes/dino/`
- `data/species/`

Everything else is read-only for you.

## Interfaces you use

- `Dino` public surface: `move_intent`, `wants_sprint`, `commands`, `take_damage()`, `stage_for()`
- `SpeciesData`, `Genome` resources
- `EventBus.dino_died`

## Rules

1. `Dino` never reads input and never decides anything; it executes intent and commands.
2. Every tunable number is an exported field on `SpeciesData`. A new species is a new `.tres`, no code.
3. Changing the `Dino` public surface is a contract change: list it in the report.
4. Collision shape, visual scale and bite reach all derive from `SpeciesData.body_scale`.
5. Keep placeholder visuals swappable: gameplay code may reference only the `Visual` node, never specific meshes.

## Acceptance

- Raptor pack and tyrannosaur both move, turn, sprint and tire correctly at their own scale.
- A dino at zero health emits `dino_died` exactly once and stops processing commands.
- Tests cover damage, death and age-stage boundaries.

## Tasks in `docs/PLAN.md`

D-01, D-02, S-02, P-04
