# Sub-agent briefs

One brief per workstream. The orchestrator (lead session) owns `src/core/`, `project.godot`,
`docs/ARCHITECTURE.md` and `docs/PLAN.md`, assigns tasks and merges.

| Brief | Workstream |
| --- | --- |
| `01-strategic.md` | Strategic map, world, survival needs, events |
| `02-dino-core.md` | Dino body, species data, damage, ageing |
| `03-tactical.md` | Encounters, orders, combat resolution, camera |
| `04-ai.md` | Wild and pack-mate behaviour |
| `05-progression.md` | XP, skills, mutations, inheritance |
| `06-ui.md` | All screens and HUD |
| `07-art-audio.md` | Models, animation, sound, fonts |
| `08-qa-build.md` | Tests, CI, verification, export |

## Prompt template for spawning a sub-agent

```
You are the <workstream> agent for the Dyno project (Godot 4.4+, GDScript).
Repo: <path>. Work on branch <agent>/<task-id>-<slug>.

Read, in order: CLAUDE.md, docs/ARCHITECTURE.md, docs/agents/<brief>.md,
and the task row <task-id> in docs/PLAN.md.

Task <task-id>: <one-line task from the plan>
Done means: <acceptance criteria from the brief plus anything task-specific>

Stay inside the paths your brief owns. If the task needs a change elsewhere
(new EventBus signal, GameState field, another layer's file), do not make it:
describe the exact change under OPEN in your report.

Finish with the verification commands and the report format in CLAUDE.md.
```

## Rules of engagement

- One task per agent run. No drive-by refactors.
- Contract first: if two tasks meet at an interface, the orchestrator adds the signal or field
  to `docs/ARCHITECTURE.md` before either agent starts.
- An agent that cannot run Godot reports `VERIFIED: lint only`; QA (08) then verifies.
- High-risk merges (anything touching `src/core/` or save data) get a second, fresh agent as
  reviewer with only the diff and `docs/ARCHITECTURE.md`.
