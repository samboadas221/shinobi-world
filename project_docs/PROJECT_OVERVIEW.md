# PROJECT OVERVIEW

## Project

`shinobi_world` is a Flutter + Flame 2D open-world game prototype inspired by Naruto-like shinobi mechanics. The project is currently focused on building a durable first demo foundation rather than final content or art.

## Core Goal

Build a config-driven, scalable shinobi RPG foundation with:

- open-world exploration
- seeded world generation
- random starting village
- character creation
- chakra natures and secondary affinity
- jutsu discovery/practice/progression
- turn-based combat
- NPC/village persistence
- long-term support for many villages, NPCs, jutsus, summons, and story paths

## Current Demo Flow

The current first-demo flow is:

1. App loads YAML config.
2. Splash screen shows Boadas Corp branding.
3. Main menu shows Play, Settings, Exit.
4. Play opens character creation.
5. Character creation rolls:
   - name
   - gender
   - natural chakra nature
   - secondary chakra nature with higher chakra cost
   - random ability points
   - customizable clothing selections
6. Starting village and initial NPC data are generated.
7. Data is persisted through Drift.
8. Player enters the Flame overworld.
9. Remaining world data can be generated/stored in the background.
10. Player can move, practice jutsus, collide with enemies, and enter turn-based combat.

## Current Systems

- Config loading from modular YAML under `assets/configs/`
- Typed config models under `lib/config/models/`
- Character generation under `lib/character/`
- Seeded world generation under `lib/world/`
- Drift database and first-demo persistence under `lib/data/`
- Flame overworld under `lib/game/`
- Jutsu loadout/practice logic under `lib/jutsu/`
- Turn-based combat under `lib/combat/`
- Flutter screens under `lib/screens/`
- Reusable UI widgets under `lib/ui/`

## Current Development Status

The first demo is functional as a prototype. The project has placeholder visuals and simple systems, but the architecture is moving toward the intended scalable shape.

Current validation from the latest implementation pass:

- `dart format lib test` passed
- `flutter analyze` passed
- `flutter test` passed
- `flutter build windows --debug` passed

## Major Priorities

1. Keep all gameplay values in YAML.
2. Reduce large files toward the 50-200 line target.
3. Keep combat, overworld, UI, AI, persistence, and config parsing decoupled.
4. Continue replacing placeholder logic with config-driven systems.
5. Expand Drift-backed NPC/world state without actively simulating distant NPCs.
6. Improve first-demo UX without turning placeholder systems into permanent architecture.

