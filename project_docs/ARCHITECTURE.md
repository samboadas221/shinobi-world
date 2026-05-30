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
- world runtime config (includes collision + npc spawn sub-configs)
- world run generation config
- village population config
- training config
- player base config
- combat config (turns, reaction, ui, damage)
- progression config
- jutsu configs (list, one per file)
- jutsu affinity config
- jutsu progression config
- enemy configs
- summon configs
- stats scaling config

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
- `lib/game/world_layout/world_layout_generator.dart`
- `lib/game/world_layout/building_layout_generator.dart`
- `lib/game/world_layout/road_network_generator.dart`

The world generator supports a staged first-demo flow:

1. Generate starting village first using an iterative layout solver.
2. Enter the game quickly.
3. Generate/store the remaining villages, inter-village highways, and NPCs in the background.

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

Design rule: persist large world/NPC data; only actively simulate entities near the player.

Added in 2026-05-26: `loadNinjasForVillage` and `loadNinjasForOtherVillages` queries support the NPC spawner.

## Overworld

Domain files:

- `lib/game/shinobi_world_game.dart` — main coordinator
- `lib/game/player_component.dart` — player movement + collision check
- `lib/game/enemy_component.dart` — overworld enemy actor
- `lib/game/npc_manager_component.dart` — deprecated stub, replaced by NinjaSpawnerComponent
- `lib/game/ninja_spawner_component.dart` — active NPC lifecycle (pool → spawn → despawn)
- `lib/game/active_ninja_component.dart` — individual wandering NPC Flame component
- `lib/game/procedural_world_map.dart` — renders map from layout data
- `lib/world/day_night_cycle.dart`
- `lib/world/encounter_detector.dart`

`ShinobiWorldGame` owns the Flame runtime. It creates the collision registry, loads the map, spawns the player with collision support, starts the NPC spawner, and manages the encounter trigger and HUD state.

## Structure Collision System

Domain files:

- `lib/world/collision/aabb_rect.dart` — pure-Dart zero-dependency AABB value type
- `lib/world/collision/overworld_collision_grid.dart` — spatial hash grid; O(1) per-frame queries
- `lib/game/collision_registry.dart` — populates the grid from WorldLayoutData.buildings at load time

`PlayerComponent.update()` tests its new position against the collision registry each frame. On collision, it attempts axis-separated sliding (X only, then Y only) before reverting to the previous position. This allows the player to slide along building walls.

Config: `assets/configs/world/map.yaml` → `collision:` section (`CollisionMapConfig`).

## NPC Spawning

Domain files:

- `lib/game/ninja_spawner_component.dart`
- `lib/game/active_ninja_component.dart`

`NinjaSpawnerComponent` loads a passive pool of DB ninjas (home village + other villages) at startup. Every N seconds (config-driven), it spawns ninjas from the pool into a buffer zone around the player and despawns ones beyond the despawn radius, returning them to the passive pool. Killed NPCs are permanently excluded from re-spawn this session.

`ActiveNinjaComponent` wanders randomly within a configurable radius of its spawn point and is color-coded by alignment (blue=friendly, grey=neutral, red=hostile).

Config: `assets/configs/world/map.yaml` → `npc_spawn:` section (`NpcSpawnConfig`).

## Jutsu Practice

Domain files:

- `lib/jutsu/jutsu_loadout_selector.dart`
- `lib/jutsu/overworld_practice_controller.dart`

Jutsu loadouts are selected from config. Overworld practice spends chakra, grants jutsu EXP, and reduces required hand seals over levels according to training config.

Secondary chakra nature costs are increased by the character profile's configured multiplier.

## Jutsu System

Domain files:

- `lib/config/models/jutsu_config.dart` — `JutsuConfig`, `JutsuEffect`, `JutsuEffectType`
- `lib/config/models/jutsu_affinity_config.dart` — `JutsuAffinityConfig` with `multiplierFor()`
- `lib/config/models/jutsu_progression_config.dart`
- `assets/configs/jutsu/jutsu_affinities.yaml`
- `assets/configs/jutsu/*.yaml` — one file per jutsu (15 total as of 2026-05-26)

### Affinity Multipliers

When a jutsu is used in combat, `DamageResolver.jutsuDamage()` calls `JutsuAffinityConfig.multiplierFor()` which returns a multiplier based on the match between the jutsu's element and the caster's primary/secondary natures:

- Primary match: 1.25×
- Secondary match: 1.10×
- Neutral: 1.00×
- Opposite of primary: 0.75×
- Opposite of secondary: 0.90×

All multipliers are configurable in `jutsu_affinities.yaml`.

### Jutsu Effects

Jutsus can declare a list of `effects:` in their YAML file. Each effect has a `type`, `value`, and `duration_turns`. Supported types:

- `armor_buff` / `speed_buff` — buff caster's stat for N turns; auto-reverted on expiry
- `heal_hp` / `heal_chakra` — instant restore (duration 0)
- `enemy_armor_debuff` / `enemy_speed_debuff` — debuff opponent's stat for N turns

Effects are tracked in `BattleParticipant._activeEffects` and ticked down by `tickEffects()` at the start of each enemy turn.

## Combat

Domain files:

- `lib/combat/battle_request.dart` — carries player/enemy config, natures, jutsu affinities into combat
- `lib/combat/battle_setup.dart` — builds BattleParticipant instances from a request
- `lib/combat/battle_participant.dart` — mutable combat actor; tracks HP, chakra, stats, active effects
- `lib/combat/battle_controller.dart` — turn loop; resolves attacks, jutsu, effects, turn order
- `lib/combat/damage_resolver.dart` — basic attack and jutsu damage with affinity multipliers
- `lib/combat/battle_result.dart` — outcome value object passed back to the overworld
- `lib/screens/combat_screen.dart` — full-screen dark RPG combat UI
- `lib/ui/combat/combat_participant_panel.dart` — animated HP/chakra bars, effect badges, mini stats
- `lib/ui/combat/combat_action_bar.dart` — Attack/Jutsu/Flee buttons with slide-up jutsu panel
- `lib/ui/combat/jutsu_selection_panel.dart` — element-colored jutsu card grid
- `lib/ui/combat/combat_log.dart` — monospaced dark log with fade-out

Combat is turn-based. Speed determines turn order. Current combat supports:

- basic attack
- jutsu use with elemental affinity multipliers
- timed stat effects (buffs/debuffs) applied to participants
- chakra spending
- enemy AI jutsu preference
- victory, defeat, and flee outcomes
- returning combat results to the overworld (health, chakra, casted jutsu IDs for EXP)

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
- Collision uses a pure-Dart AABB spatial hash grid — no Flame collision system dependency — so it can be unit-tested independently.
- Each jutsu lives in its own YAML file; the manifest lists them explicitly so adding jutsus requires zero Dart changes.
