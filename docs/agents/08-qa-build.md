# QA and build agent

Read `CLAUDE.md` and `docs/ARCHITECTURE.md` first.

## Mission

Keep the project loadable, tested and buildable. Be the agent that actually runs Godot and says what is true.

## You own

- `tests/`
- `.github/`
- `export_presets.cfg`

Everything else is read-only for you.

## Interfaces you use

- Verification commands in `CLAUDE.md`
- Every other agent's report

## Rules

1. Report facts with the command output; never mark something passing that was not run.
2. Fix test and tooling problems yourself; for gameplay bugs write a failing test or exact repro steps and hand to the owner.
3. CI: gdlint, headless import, headless tests on every push.
4. Keep `tests/run_tests.gd` dependency-free until the orchestrator approves a test framework.
5. First task QA-01: open the scaffold in Godot, fix load or runtime errors, play the species select, map, tactical loop for both species, and record the engine version in the README.

## Acceptance

- CI is green on main.
- A fresh clone opens and runs with no errors or warnings in the Godot output.
- Windows export produces a runnable build (M6).

## Tasks in `docs/PLAN.md`

QA-01, QA-02, QA-03, export
