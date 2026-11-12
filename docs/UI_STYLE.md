# UI style

Mood: deep shade under a canopy. Dark, desaturated greens; bone-coloured text; warm earth for
borders; colour is spent only on state (health, stamina, DNA, danger). Nothing glows. Nothing
is pure black, pure white or saturated.

## Palette (`src/ui/palette.gd`)

| Token | Hex | Use |
| --- | --- | --- |
| CANOPY | `#141C17` | Screen background, bar troughs |
| UNDERGROWTH | `#1F2A22` | Panels (88% opacity over the 3D view) |
| MOSS | `#2E3D30` | Raised surfaces, buttons, map regions |
| FERN | `#5F7A56` | Primary accent, selection, friendly units |
| LICHEN | `#9AA882` | Secondary text, labels, hints |
| BONE | `#DDD6C1` | Primary text, player marker |
| BARK | `#5A4A3A` | Borders and dividers |
| AMBER | `#C59A4A` | XP, pause state, the one call to action |
| CLAY | `#A4553F` | Health, enemies, danger |
| RIVER | `#5C8A8A` | Stamina, water, thirst |
| SPORE | `#7D6A8C` | DNA and mutations only |

## Type

- Headings, labels and buttons: Barlow Condensed 600, uppercase, tracked 0.04 to 0.16 em.
  Body and numbers: Barlow 400 to 600. Both are open-licence; files go in `assets/fonts/`.
- Sizes: 34 screen title, 24 card title, 18 unit name, 16 body, 14 status, 11 to 12 labels.
- Labels are uppercase with wide tracking; everything else is sentence case.

## Components

- **Panel**: UNDERGROWTH, 1 px BARK border, 4 px radius, 14 px padding. No shadows.
- **Bar**: 12 px high, CANOPY trough, flat fill in the state colour, no gradient.
- **Button**: MOSS; hover FERN; pressed CANOPY with FERN border; focus ring AMBER.
- **Slot**: 56 px square, CANOPY, BARK border, key number top-left in LICHEN.
- **Pause state**: AMBER border on the banner, 25% CANOPY wash over the 3D view, order
  paths drawn in BONE dashes with numbered waypoints.
- HUD looks are theme type variations defined in `JungleTheme.build()`; scenes name a variation, never a colour.

## Screens

1. **Species select**: two or more lineage cards, pack or solo tag in AMBER.
2. **Strategic map**: full-screen map; top bar with day, time, season; left needs panel
   (hunger, thirst, rest, wounds); right region panel; bottom-right travel controls.
3. **Tactical HUD**: bottom-left squad portraits with vitals; bottom-centre four ability
   slots; top-left day and age; top-right encounter objective; nothing in the screen centre.
4. **Tactical paused**: same HUD plus banner, order queue strip above the abilities, path
   preview in the world.
5. **Evolution**: left skills (this life), centre DNA strand (heritable, SPORE), right
   lineage tree by generation.

Design mock-ups for these screens are on the project's design canvas ("Dyno UI").

## Rules

- Keep the middle 50% of the tactical screen free of UI.
- Never signal state by colour alone: pair with an icon, label or shape.
- Text contrast on panels: BONE or LICHEN only.
