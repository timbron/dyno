# Rules for every agent working in this repo

Read this file, then `docs/ARCHITECTURE.md`, then your brief in `docs/agents/`.

## Project

Dyno: Godot 4.4+, GDScript only, 3D tactical layer and 2D strategic map.
Design is in `docs/GDD.md`. Work is sequenced in `docs/PLAN.md`.

## Hard rules

1. Stay inside the paths your brief says you own. Need a change elsewhere? Stop and report it.
2. Cross-system communication goes through `EventBus` signals or `GameState`. No reaching into
   another layer's nodes with `get_node("/root/...")` or absolute paths.
3. New signal, autoload, input action or resource class: add it to `docs/ARCHITECTURE.md` in
   the same change.
4. Typed GDScript everywhere (`var x: int`, `-> void`). Tabs. Max line length 100.
5. Game data lives in `.tres` resources under `data/`, never as constants in scripts.
6. UI colours come from `src/ui/palette.gd` only. UI follows `docs/UI_STYLE.md`.
7. Anything that must work during tactical pause sets `process_mode = PROCESS_MODE_ALWAYS`.
   Everything else must stop cleanly when the tree is paused.
8. `Dino` never reads input. Controllers and AI drive it through `move_intent`,
   `wants_sprint` and `commands`.
9. Pure logic (formulas, queues, inheritance, generation) gets a test in `tests/suite.gd`
   or a suite it loads such as `tests/combat_suite.gd`
   (`tests/run_tests.gd` is only the loader; it must not name game classes statically).
10. Do not add plugins, addons or third-party assets without approval from the orchestrator.

## Before you report done

```
gdlint $(find . -name "*.gd")          # pip install "gdtoolkit==4.*"
godot --headless --path . --import     # project loads with no script errors
godot --headless --path . -s res://tests/run_tests.gd
```

All three must pass. If Godot is not available to you, say so in the report; do not claim a pass.

## Report format

```
TASK: <id from docs/PLAN.md>
STATUS: done | partial | blocked
CHANGED: <files>
CONTRACT CHANGES: <signals / autoload API / resources added or changed, or "none">
VERIFIED: <commands run and results>
OPEN: <questions, follow-ups, things outside your paths that need changing>
```

## Git

One branch per task: `<agent>/<task-id>-<slug>`, for example `tactical/T-03-bite-attack`.
Small commits, imperative subject. Never commit `.godot/`.
