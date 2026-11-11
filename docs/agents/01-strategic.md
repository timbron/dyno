# Strategic map agent

Read `CLAUDE.md` and `docs/ARCHITECTURE.md` first.

## Mission

Build the top-down strategic layer: the world the dino travels, the survival needs that tick there, and the events and encounters it runs into. Reference: Battle Brothers world map.

## You own

- `src/strategic/`
- `scenes/strategic/`
- `data/world/`, `data/events/`

Everything else is read-only for you.

## Interfaces you use

- `GameState` (`map_position`, `day`, `hour`, `advance_time()`, `cleared_encounters`)
- `SceneRouter.go_to(SceneRouter.TACTICAL)` to start an encounter
- `EventBus.encounter_started`, `day_passed`

## Rules

1. Time passes only while the party moves (or rests); never in real time while idle.
2. Map content is data: regions, encounter tokens and events load from `data/world/`, not constants.
3. Needs (hunger, thirst, rest) live in `GameState`; ask the orchestrator to add the fields.
4. The map draws with `Palette` colours; the strategic HUD itself belongs to the UI agent.
5. Encounter hand-off: write what the tactical scene needs (who, how many, biome) into a `GameState` field agreed with the tactical agent.

## Acceptance

- Map runs at 60 fps with 50 roaming tokens.
- Entering and leaving an encounter returns the party to the same spot with time advanced.
- World generation is seeded and reproducible; a test asserts the same seed gives the same world.

## Tasks in `docs/PLAN.md`

S-01, S-03, S-04, S-05, S-06, P-05 (nest and mating on the map)
