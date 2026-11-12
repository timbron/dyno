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

## The team

The briefs above say *which part of the game* a task belongs to. The team below says *who
does which step* of a task. The four agents are defined in `.claude/agents/`, each pinned
to its own model:

| Agent | Model | Does | Writes |
| --- | --- | --- | --- |
| `planner` | Fable | Designs the code: files, classes, typed signatures, data, control flow, and every coding decision | nothing |
| `coder` | Opus | Carries out the design as written; makes no design decisions | `src/`, `scenes/`, `data/`, `project.godot` |
| `tester` | Sonnet | Reviews the diff, writes tests, runs lint, import and tests | `tests/`, `.github/` |
| `documenter` | Haiku | Brings the docs in line with the code | `docs/`, `README.md` |

One task runs through them in order. The lead session passes each agent the output of the
ones before it, because an agent starts with no memory of the conversation:

1. `planner` returns the design. The lead session shows it to the user if it has open
   questions about the game itself; technical choices are the planner's.
2. `coder` gets the full design and returns its report. If the design is silent on
   something structural or turns out to be wrong, the coder stops and reports
   `QUESTIONS FOR THE PLANNER`; those go back to `planner`, and its answer back to `coder`.
3. `tester` gets the plan and the coder's report. On `VERDICT: fail` the failures go back
   to `coder`, then to `tester` again.
4. `documenter` gets the plan and both reports once the tester passes.
5. The lead session checks the result, then commits and merges when the user says so. No
   agent commits, merges or pushes.

The models are set in each file's `model:` line (`fable`, `opus`, `sonnet`, `haiku`).

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
