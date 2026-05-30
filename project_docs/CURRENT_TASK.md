# CURRENT TASK

## Active Task

NPC Spawning & Overworld Combat Collision Fixes.

## Status

Completed.

## Progress

### Jutsu System
- Created `assets/configs/jutsu/jutsu_affinities.yaml` — global elemental affinity multipliers and opposite element map
- Updated all 10 existing jutsu YAML files to the new extended schema (added `speed`, `hand_seal_speed`, `chakra_control`, `exp_gain`)
- Created 5 new jutsu YAML files: `fire_wall.yaml`, `water_shield.yaml`, `cyclone_armor.yaml`, `mud_wall.yaml`, `thunder_clap.yaml`
- Updated `jutsu_progression.yaml` with max levels for all 15 jutsus
- Updated `config_manifest.yaml` with all new paths and `jutsu_affinities` key
- Extended `lib/config/models/jutsu_config.dart` with `JutsuEffect`, `JutsuEffectType`, and optional fields
- Created `lib/config/models/jutsu_affinity_config.dart` with `multiplierFor()` logic
- Updated `lib/config/game_config.dart` and `game_config_loader.dart` to load affinity config
- Updated `lib/combat/battle_participant.dart` with buff/debuff tracking and `tickEffects()`
- Updated `lib/combat/damage_resolver.dart` to apply affinity multipliers
- Updated `lib/combat/battle_request.dart` to carry `jutsuAffinities`
- Updated `lib/combat/battle_controller.dart` to wire affinity damage and apply/tick effects
- Updated `lib/combat/battle_setup.dart` to use new named base stat params
- Wrote `assets/docs/jutsu_documentation.md` — full developer reference

### Collision System
- Created `lib/world/collision/aabb_rect.dart` — pure-Dart zero-dependency AABB type
- Created `lib/world/collision/overworld_collision_grid.dart` — spatial hash grid
- Created `lib/game/collision_registry.dart` — bridges WorldLayoutData to the grid
- Updated `lib/game/player_component.dart` — collision check + axis-separated sliding
- Added `collision` and `npc_spawn` sections to `assets/configs/world/map.yaml`
- Extended `lib/config/models/world_config.dart` with `CollisionMapConfig` and `NpcSpawnConfig`

### NPC Spawning
- Created `lib/game/active_ninja_component.dart` — wandering NPC Flame component
- Updated `lib/data/first_demo_store.dart` — added `loadNinjasForVillage` and `loadNinjasForOtherVillages`
- Updated `lib/data/shinobi_database.dart` — exposed the two new query methods
- Created `lib/game/ninja_spawner_component.dart` — passive pool, spawn/despawn cycle, kill tracking

### Combat Screen Overhaul
- Rewrote `lib/screens/combat_screen.dart` — dark RPG layout: VS header, participant panels, log, action bar
- Rewrote `lib/ui/combat/combat_participant_panel.dart` — animated HP/chakra bars, effect badges, mini stats
- Rewrote `lib/ui/combat/combat_action_bar.dart` — styled buttons with slide-up jutsu panel
- Rewrote `lib/ui/combat/combat_log.dart` — monospaced dark log with fade-out on old entries
- Created `lib/ui/combat/jutsu_selection_panel.dart` — element-colored jutsu card grid

### Wiring
- Updated `lib/game/shinobi_world_game.dart` — creates CollisionRegistry, passes it to PlayerComponent, spawns NinjaSpawnerComponent instead of NpcManagerComponent, adds jutsuAffinities to BattleRequest

## Affected Files

### New
- `assets/configs/jutsu/jutsu_affinities.yaml`
- `assets/configs/jutsu/fire_wall.yaml`
- `assets/configs/jutsu/water_shield.yaml`
- `assets/configs/jutsu/cyclone_armor.yaml`
- `assets/configs/jutsu/mud_wall.yaml`
- `assets/configs/jutsu/thunder_clap.yaml`
- `assets/docs/jutsu_documentation.md`
- `lib/config/models/jutsu_affinity_config.dart`
- `lib/world/collision/aabb_rect.dart`
- `lib/world/collision/overworld_collision_grid.dart`
- `lib/game/collision_registry.dart`
- `lib/game/active_ninja_component.dart`
- `lib/game/ninja_spawner_component.dart`
- `lib/ui/combat/jutsu_selection_panel.dart`

### Modified
- `assets/configs/jutsu/jutsu_progression.yaml`
- `assets/configs/jutsu/fireball.yaml` (+ 9 more jutsu YAMLs)
- `assets/configs/config_manifest.yaml`
- `assets/configs/world/map.yaml`
- `lib/config/models/jutsu_config.dart`
- `lib/config/models/world_config.dart`
- `lib/config/game_config.dart`
- `lib/config/game_config_loader.dart`
- `lib/combat/battle_participant.dart`
- `lib/combat/damage_resolver.dart`
- `lib/combat/battle_request.dart`
- `lib/combat/battle_controller.dart`
- `lib/combat/battle_setup.dart`
- `lib/game/player_component.dart`
- `lib/game/shinobi_world_game.dart`
- `lib/data/first_demo_store.dart`
- `lib/data/shinobi_database.dart`
- `lib/screens/combat_screen.dart`
- `lib/ui/combat/combat_participant_panel.dart`
- `lib/ui/combat/combat_action_bar.dart`
- `lib/ui/combat/combat_log.dart`

## Warnings

None.

## Blockers

None.

## Next Steps

1. User to run the game and verify collision stops the player at building walls.
2. User to verify NPC ninjas appear near the starting village and wander.
3. User to verify the new dark RPG combat screen looks correct.
4. User to verify affinity multipliers affect jutsu damage (check combat log).
5. Consider adding jutsu level-up chains (next_level_id YAML is ready, needs Dart promotion logic).
