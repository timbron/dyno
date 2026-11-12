# Plan

Task ids are stable; agents quote them in branches and reports. Briefs: `docs/agents/`.

## Milestones

| # | Milestone | Proves | Exit test |
| --- | --- | --- | --- |
| M0 | Scaffold | Project structure, flow, palette | Pick species, travel, enter and leave an encounter |
| M1 | Combat slice | Tactics are fun | Raptor pack kills a prey herd using pause orders; T-rex duels a rival |
| M2 | Survival loop | Strategy matters | A life can end by starvation, wounds or a lost fight |
| M3 | World | Replayable map | Generated regions, events, territories, save and load |
| M4 | Lineage | The hook works | XP skills, mutations, ageing, mating, next generation inherits |
| M5 | Ecosystem | World feels alive | Six wild species with herd, pack and territorial behaviour |
| M6 | Content and polish | Shippable | Final art, audio, UI, balance pass, Windows build |

## M0 Scaffold (done, verified headless on Godot 4.7.2-stable)

| Id | Task | Owner | Status |
| --- | --- | --- | --- |
| QA-01 | Open project in Godot, fix any load or runtime errors, run tests, record engine version in README | 08 | done 2026-11-12 |

OPEN from QA-01:

- Verified headless only (import, 120-frame run, scene smoke tests). Nobody has played the
  species select, map, tactical loop by hand yet.

## M1 Combat slice

| Id | Task | Owner | Needs |
| --- | --- | --- | --- |
| D-01 | Health, damage, death state, corpse; collision scaled by species (done 2026-11-12) | 02 | QA-01 |
| D-02 | Two wild species as data: small herd prey, large rival predator (done 2026-11-12) | 02 | D-01 |
| T-01 | ATTACK command: approach, bite with facing arc, flank and rear bonus (done 2026-11-12) | 03 | D-01 |
| T-02 | Order targeting: click enemy to attack, right-click cancel, order path preview (done 2026-11-12, headless only: preview not yet seen on screen) | 03 | T-01 |
| T-03 | Encounter setup from data: who spawns where, win / flee / death outcomes back to map (done 2026-11-12, headless only) | 03 | D-02 |
| T-04 | Pack follow: unselected members follow or hold; formation spacing (done 2026-11-12) | 03 | QA-01 |
| A-01 | Wild AI v1: idle, flee when hurt, attack when cornered or predator (done 2026-11-12) | 04 | D-01 |
| U-01 | Tactical HUD per design: squad portraits, order queue strip, pause overlay (done 2026-11-12, headless only, not checked against the design canvas) | 06 | T-02 |
| U-02 | Species select and main menu per design (done 2026-11-12, not checked against the design canvas) | 06 | QA-01 |
| QA-02 | Tests for damage and arc maths; CI lint and headless test run (done 2026-11-12, headless and Git Bash only; hardened CI not yet run on GitHub Actions) | 08 | T-01 |

Parallel lanes: (D-01, D-02) with (T-04, U-02); then (T-01, A-01); then (T-02, T-03, U-01, QA-02).

OPEN from T-02 and T-03:

- Neither has been played by hand: check clicking an enemy, the path preview, the arena
  edge posts, the result banner and the three encounters for balance.
- Nothing consumes `GameState.last_encounter` yet (S-01 feeding, S-02 wounds and losses).
- Map markers and their encounter ids are constants in `strategic_map.gd` (S-05).

OPEN from U-01:

- Check the HUD against the "Dyno UI" canvas: vertical squad list, portrait content, paused-only
  order strip, chip wording, wash strength, AMBER and CLAY banner text (UI_STYLE says BONE or
  LICHEN only on panels).
- Layout at 1600x900, 1280x720, 3840x2160, 16:10 and 21:9; click pass-through and right-drag
  orbit over the panels in a windowed run.
- Chip ellipsis and the 170 px chip width cap (no real font metrics headless).
- Readability of the 25% pause wash and the 11 px captions.
- Path-preview numbers match the chip numbers; a chip goes when its attack target dies.
- Tab moves the SELECTED frame and F flips the pack caption, through real key input.
- Question: should clicking a portrait select that dino? Recommend yes, as a follow-up; needs
  a new `EventBus.unit_select_requested(dino)` that SquadController listens to.
- Question: should unselected pack members show following or holding one by one? Recommend
  not now; needs a tactical-side contract.
- Follow-up: encounter objective panel (top right) needs the encounter name and living wild
  count on EventBus or from EncounterDirector.
- Follow-up: ability slots stay empty until P-02; WAIT and USE_ABILITY orders are not shown
  in the strip (no destination).
- Follow-up (07): Barlow and Barlow Condensed files in `assets/fonts/`.

OPEN from QA-02:

- Follow-up (04): WildBrain calls `_rng.randomize()` in `_ready()`, so `_test_wild_brain` is not
  deterministic. Suggest an optional seed (`rng_seed`, 0 = randomize) that the tests set.
- Follow-up (08): verify the Godot download against the release's SHA512-SUMS.txt in CI.
- The hardened CI workflow has not yet run on GitHub Actions. Check that it parses with the new
  `permissions` and `defaults.run.shell` keys, that the Linux import exits 0, and that the test
  log has no leak or ERROR lines.

## M2 Survival loop

| Id | Task | Owner |
| --- | --- | --- |
| S-01 | Hunger, thirst, rest on the map; feeding after a kill | 01 |
| S-02 | Wounds persist between encounters; healing over days | 02 |
| S-03 | Encounter tokens that roam the map (prey herds, rivals) with sight and pursuit | 01 |
| S-04 | Day and night cycle on map and in tactical lighting | 01 / 03 |
| U-03 | Strategic HUD per design: needs, time controls, region info, event dialogs | 06 |
| P-01 | XP awards for kills, survival days, discoveries | 05 |
| QA-03 | Life-and-death soak test: scripted life runs headless without errors | 08 |

## M3 World

| Id | Task | Owner |
| --- | --- | --- |
| S-05 | World generation: regions, biomes, water, nesting sites, rival territories | 01 |
| S-06 | Text events with choices and outcomes (data-driven) | 01 |
| S-07 | Tactical arena built from the map biome | 03 |
| C-01 | Save and load of `GameState` and world | orchestrator |

## M4 Lineage

| Id | Task | Owner |
| --- | --- | --- |
| P-02 | Ability resources and four-slot bar; Bull Rush, Ambush, Pounce, Roar | 05 / 03 |
| P-03 | Mutation resources, deed tracking, stat effects | 05 |
| P-04 | Age stages change stats and size; elder decline | 02 / 05 |
| P-05 | Mating, nest, inheritance, next-generation start | 05 / 01 |
| U-04 | Evolution screen per design: skills, DNA strand, lineage tree | 06 |

## M5 Ecosystem, M6 Polish

Scoped after M2 playtest. Expected: utility AI and herd behaviour (04), species roster (02),
models, animation and sound (07), balance and export (08).

## How the orchestrator runs a task

1. Pick tasks whose "Needs" are merged; keep to one task per owner at a time.
2. Spawn one sub-agent per task with the prompt template in `docs/agents/README.md`.
3. On report: check the contract changes, run the three verification commands, merge.
4. Update this file: mark the task done, add follow-ups raised under OPEN.

## Risks

| Risk | Mitigation |
| --- | --- |
| Third-person control and pause orders feel like two games | M1 exists to test exactly this; cut direct control or orders early if one loses |
| Pack control overload | Follow and formation by default (T-04); orders are optional precision |
| Agents collide in shared files | Path ownership, EventBus contract, one task per owner |
| Scope of art | Greybox through M4; pick art direction before M5 |
