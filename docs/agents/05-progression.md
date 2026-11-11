# Progression agent

Read `CLAUDE.md` and `docs/ARCHITECTURE.md` first.

## Mission

Own what the player earns: XP, skills for this life, heritable DNA mutations, and what the next generation inherits.

## You own

- `src/progression/`
- `data/abilities/`, `data/mutations/`

Everything else is read-only for you.

## Interfaces you use

- `GameState.genome`, `generation`; `Genome.inherit()`
- `EventBus.xp_gained`, `dino_died`, `day_passed`
- Tactical agent executes abilities; this agent defines them as data

## Rules

1. Skills belong to the individual and are lost on death; mutations belong to the genome.
2. Abilities and mutations are resources: id, name, description, costs, stat modifiers, unlock deed.
3. Mutations are earned by deeds tracked from EventBus signals, never bought with XP.
4. All formulas (XP curve, inheritance chance, mate bonus) are pure functions with tests.
5. No UI here: expose data and signals for the evolution screen.

## Acceptance

- Killing prey awards XP; a skill can be bought and appears in an ability slot.
- A deed unlocks a mutation that changes a visible stat.
- Seeded inheritance test: known genome and seed give a known offspring genome.

## Tasks in `docs/PLAN.md`

P-01, P-02, P-03, P-04, P-05
