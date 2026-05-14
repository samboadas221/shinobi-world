# ARCHITECTURE

## High-Level Flow

```text
main.dart
  -> ShinobiApp
    -> GameConfigLoader
    -> FirstDemoFlowScreen
      -> SplashScreen
      -> MainMenuScreen
      -> CharacterCreationScreen
      -> DemoGameScreen
        -> ShinobiWorldGame
        -> CombatScreen when encounter starts
```

## Config System

Config is loaded from `assets/configs/config_manifest.yaml`.

The manifest points to modular YAML files grouped by domain:

- `configs/app/`
- `configs/character/`
- `configs/world/`
- `configs/player/`
- `configs/combat/`
- `configs/progression/`
- `configs/jutsu/`
- `configs/entities/enemies/`
- `configs/summons/`

`GameConfigLoader` loads the manifest, reads each referenced YAML file, and builds one `GameConfig` object from typed model classes in `lib/config/models/`.

## Runtime Config Object

`GameConfig` contains:

- app branding/menu config
- character creation config
- clothing config
- world runtime config
- world run generation config
- village population config
- passive simulation config
- exam config
- training config
- player base config
- combat config
- progression config
- jutsu configs
- enemy configs
- summon configs

## Character Creation

Domain files:

- `lib/character/character_generator.dart`
- `lib/character/character_roll.dart`
- `lib/character/player_profile.dart`
- `lib/screens/character_creation_screen.dart`
- `lib/ui/character/`

Character creation rolls random identity and chakra data from config while allowing player customization of clothing and ability point allocation.

## World Generation

Domain files:

- `lib/world/world_run_generator.dart`
- `lib/world/generated_world_run.dart`
- `lib/config/models/world_run_config.dart`
- `lib/config/models/village_population_config.dart`

The world generator supports a staged first-demo flow:

1. Generate starting village first.
2. Enter the game quickly.
3. Generate/store the remaining villages and NPCs in the background.

NPCs are generated with role, village, alignment, bingo-list status, active state, and config-derived stats.

## Persistence

Domain files:

- `lib/data/shinobi_database.dart`
- `lib/data/first_demo_store.dart`

Drift is used through custom SQL statements. Current persistence includes:

- discovered jutsu
- demo sessions
- world state
- player profiles
- first-demo runs
- first-demo villages
- first-demo ninjas

Design rule: persist large world/NPC data, but only actively simulate entities near the player.

## Overworld

Domain files:

- `lib/game/shinobi_world_game.dart`
- `lib/game/player_component.dart`
- `lib/game/enemy_component.dart`
- `lib/game/npc_manager_component.dart`
- `lib/game/procedural_world_map.dart`
- `lib/world/day_night_cycle.dart`
- `lib/world/encounter_detector.dart`

`ShinobiWorldGame` owns the Flame runtime. It loads the procedural map, player, joystick, NPC manager, camera follow, encounter trigger, and HUD state publication.

`NpcManagerComponent` spawns/despawns active enemy components around the player based on enemy spawn config.

`ProceduralWorldMap` renders placeholder grass, roads, and buildings from map config and generated village positions.

## Jutsu Practice

Domain files:

- `lib/jutsu/jutsu_loadout_selector.dart`
- `lib/jutsu/overworld_practice_controller.dart`

Jutsu loadouts are selected from config. Overworld practice spends chakra, grants jutsu EXP, and reduces required hand seals over levels according to training config.

Secondary chakra nature costs are increased by the character profile's configured multiplier.

## Combat

Domain files:

- `lib/combat/`
- `lib/screens/combat_screen.dart`
- `lib/ui/combat/`

Combat is turn-based. Speed determines turn order. Current combat supports:

- basic attack
- jutsu use
- chakra spending
- enemy response with AI jutsu preference
- victory, defeat, and flee outcomes
- returning combat results to the overworld

Fatal attack reaction windows are represented in config but are not yet fully implemented in battle resolution.

## Dependency Direction

Preferred dependency flow:

```text
YAML assets -> config models -> domain controllers/services -> screens/components -> UI widgets
```

Avoid reverse dependencies. UI should not parse YAML. Config models should not depend on Flame runtime state. Combat should not directly own overworld behavior.

## Important Architecture Decisions

- Use YAML for all gameplay values.
- Use Drift for persistent large data and generated world state.
- Use Flame for overworld runtime.
- Use Flutter widgets for menus, character creation, combat screens, and HUD overlays.
- Use procedural placeholder visuals until real art is supplied.
- Keep distant NPCs persisted/passive; active simulation only near player.

