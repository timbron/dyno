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
| Tactical | Left click, Ctrl+click | Order move, or attack when clicking an enemy / append to queue |
| Tactical | Right click, Ctrl+right click | Cancel orders / cancel the newest order |
| Tactical | Tab | Next pack member |
| Tactical | F | Pack follows in formation / holds position |
| Tactical | Space | Pause and plan |
| Tactical | Right mouse drag, wheel | Orbit, zoom |
| Tactical | Backspace, or walk past the edge posts | Retreat from the encounter |

## Tests

```
bash tests/ci/run_godot.sh import
bash tests/ci/run_godot.sh tests
```

Run both from the project root. These are the same two steps CI runs. Set `GODOT=<path>` if
the Godot binary is not on PATH. Tests live in `tests/suite.gd` and the suites it loads
(`combat_suite.gd`, `encounter_suite.gd`, `ui_suite.gd`); `run_tests.gd` only loads and runs
them.

CI (GitHub Actions, Godot 4.7.2) fails a step on a non-zero exit, a timeout (import 300 s,
tests 420 s), or any script, parse or compile error. The tests step also fails on any `ERROR`
or `FAIL:` line, a leak report, or a missing "N checks, 0 failed" line. `run_tests.gd` fails a
run that hangs after 300 s.

Lint with `gdlint $(find . -name "*.gd")` (`pip install "gdtoolkit==4.*"`).

## Layout

```
data/      Species, AI profile and encounter resources; later abilities and mutations
scenes/    .tscn files, one folder per layer (ui, strategic, tactical, dino)
src/       GDScript, mirrored by layer; src/core holds the autoloads
tests/     Headless tests; `tests/ci/` holds the CI runner script
docs/      GDD, architecture, plan, UI style, sub-agent briefs
```

Start with `docs/PLAN.md`. Agents start with `CLAUDE.md`.
