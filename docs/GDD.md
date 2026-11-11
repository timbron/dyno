# Dyno: game design

## Pitch

You are a dinosaur. Survive, grow, reach old age, and leave a stronger lineage. Strategy on a
top-down map, tactics in third person with pause-and-plan orders.

## Decisions so far

| Topic | Decision |
| --- | --- |
| Engine | Godot 4.4+, GDScript |
| Strategic layer | Top-down map, Battle Brothers style: click to travel, time passes while moving |
| Tactical layer | Third-person 3D, real time with pause; orders queue while paused |
| Player unit | Chosen at the start of a run: a pack species or a solo hunter |
| Goal | Reach old age; then the lineage continues with inherited DNA |
| UI mood | Subdued jungle palette (`docs/UI_STYLE.md`) |

## Core loop

1. **Choose a lineage.** Pack (several weaker bodies, flanking, losses hurt) or solo
   (one powerful body, no backup).
2. **Strategic map.** Travel between regions. Manage hunger, thirst, wounds, rest. Find prey,
   water, nesting ground; avoid or challenge rivals. Events and encounters trigger on contact.
3. **Tactical encounter.** Third person. Direct control of the selected dino, orders for the
   rest. Space pauses; queue moves, attacks and abilities; resume and watch.
4. **Aftermath.** Feed, lick wounds, gain XP. Spend XP on skills, unlock mutations.
5. **Age.** Hatchling, juvenile, adult, elder. Stats rise then decline. Mate as an adult.
6. **Death or old age.** The next generation starts as a hatchling with part of the genome.

## Species

| Species | Type | Identity |
| --- | --- | --- |
| Raptor | Pack of 3 | Fast, fragile, flanking and focus fire |
| Tyrannosaur | Solo | Huge bite, low stamina, intimidation |
| Later | Pack | Herbivore herd (ceratopsian): defensive formations |
| Later | Solo | Ambusher (spinosaur): water and stealth |

Wild species (prey and rivals) use the same `SpeciesData` and `Dino` body.

## Progression

- **Skills** (this life only, bought with XP): Bull Rush, Ambush, Pounce, Roar, Tail Sweep,
  Pack Howl, Death Roll. Active abilities sit in four slots.
- **Mutations** (heritable DNA): Thick Hide, Keen Smell, Long Stride, Night Eyes, Venom Bite,
  Fast Clotting. Earned through deeds (kill ten larger prey, survive a drought), not bought.
- **Inheritance**: each mutation passes with a chance, raised by a strong mate. Generation
  count and lineage tree are shown on the evolution screen.

## Survival pressures

Hunger, thirst, wounds (bleeding, broken limb), stamina, weather and season, territory owners.
Pack species share food; solo species keep it all but have no one to cover a wound.

## Tactical rules (first pass)

- Real time; pause any time. Each dino has an order queue: move, attack, ability, wait.
- Bite attacks have a facing arc; flank and rear hits deal more.
- Stamina gates sprint and abilities. Size class decides knockback and grapples.
- Morale: wild animals flee when hurt or outnumbered; so does your pack if the alpha falls.
- Leaving the arena edge is a retreat with a chase check.

## Open questions

1. Is the player always a carnivore, or are herbivore lineages playable at launch?
2. Permadeath for the lineage (no heir means game over), or always a fallback hatchling?
3. One hand-made map, or a generated world per run?
4. Art direction: stylised low-poly or realistic?
5. Platforms beyond Windows?
