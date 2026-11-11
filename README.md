# Dyno

Strategy and tactics survival game set when dinosaurs ruled the earth. Travel a top-down
strategic map (Battle Brothers style), fight encounters in third person with pause-and-plan
orders (Jagged Alliance style), and grow your dino to old age. Experience buys skills for this
life; DNA mutations pass to the next generation.

## Run

1. Install Godot 4.4 or newer (standard build, not .NET). Developed and verified on
   Godot 4.7.2-stable; CI uses the same version.
2. Open `project.godot` in the editor and press F5, or run `godot --path .`

## Controls (greybox)

| Where | Input | Action |
| --- | --- | --- |
| Map | Left click | Travel (time passes only while moving) |
| Tactical | WASD / Shift | Move / sprint the selected dino |
| Tactical | Left click, Ctrl+click | Order move / append to queue |
| Tactical | Tab | Next pack member |
| Tactical | Space | Pause and plan |
| Tactical | Right mouse, wheel | Orbit, zoom |
| Tactical | Backspace | Leave encounter |

## Tests

```
godot --headless --path . -s res://tests/run_tests.gd
```

Tests live in `tests/suite.gd`; `run_tests.gd` only loads and runs it. Lint with
`gdlint $(find . -name "*.gd")` (`pip install "gdtoolkit==4.*"`).

## Layout

```
data/      Species and (later) ability, mutation, encounter resources
scenes/    .tscn files, one folder per layer (ui, strategic, tactical, dino)
src/       GDScript, mirrored by layer; src/core holds the autoloads
tests/     Headless test runner
docs/      GDD, architecture, plan, UI style, sub-agent briefs
```

Start with `docs/PLAN.md`. Agents start with `CLAUDE.md`.
