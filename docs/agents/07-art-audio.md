# Art and audio agent

Read `CLAUDE.md` and `docs/ARCHITECTURE.md` first.

## Mission

Source, prepare and integrate models, animation, fonts and sound so that greybox placeholders can be swapped without touching gameplay code.

## You own

- `assets/`
- The `Visual` subtree inside `scenes/dino/dino.tscn` (coordinate with dino core)

Everything else is read-only for you.

## Interfaces you use

- `SpeciesData.body_scale` and the `Visual` node contract
- `docs/UI_STYLE.md` for fonts and icon style

## Rules

1. Only assets with licences that allow commercial use; record source and licence in `assets/CREDITS.md`.
2. Formats: glTF binary for models, OGG for audio, PNG or SVG for icons.
3. Environment palette stays muted to match the UI: no saturated greens.
4. Performance budget: 60 fps at 1080p on a mid-range GPU with 40 dinos on screen.
5. Do not start before the orchestrator confirms the art direction (open question in the GDD).

## Acceptance

- Swapping a species model changes no script.
- Every asset has a credits entry.
- Imported assets load with no warnings.

## Tasks in `docs/PLAN.md`

M5 and M6 tasks
