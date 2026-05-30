import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';

import '../character/player_profile.dart';
import '../combat/battle_request.dart';
import '../combat/battle_result.dart';
import '../config/game_config.dart';
import '../config/models/enemy_config.dart';
import '../config/models/jutsu_config.dart';
import '../config/models/player_config.dart';
import '../config/models/count_range.dart';
import '../config/models/visual_config.dart';
import '../data/shinobi_database.dart';
import '../jutsu/jutsu_loadout_selector.dart';
import '../jutsu/overworld_practice_controller.dart';
import '../world/day_night_cycle.dart';
import '../world/encounter_detector.dart';
import '../world/generated_world_run.dart';
import 'collision_registry.dart';
import 'demo_state.dart';
import 'active_ninja_component.dart';
import 'enemy_component.dart';
import 'ninja_spawner_component.dart';
import 'player_component.dart';
import 'procedural_world_map.dart';
import 'world_layout/world_layout_data.dart';
import 'package:flutter/material.dart' show Colors, Paint, EdgeInsets;

class ShinobiWorldGame extends FlameGame
    with
        HasKeyboardHandlerComponents,
        HasCollisionDetection,
        ScrollDetector,
        ScaleDetector {
  ShinobiWorldGame({
    required this.config,
    required this.database,
    required this.profile,
    required this.run,
    required this.layoutData,
  }) : _cycle = DayNightCycle(config.world.time);

  final GameConfig config;
  final ShinobiDatabase database;
  final PlayerProfile profile;
  GeneratedWorldRun run;
  final WorldLayoutData layoutData;
  final ValueNotifier<DemoState> demoState = ValueNotifier(DemoState.empty());
  final ValueNotifier<BattleRequest?> encounterRequest = ValueNotifier(null);
  final DayNightCycle _cycle;
  final Random _random = Random();

  late final List<JutsuConfig> playerJutsu;
  late EnemyConfig _enemyConfig;
  late List<JutsuConfig> _enemyJutsu;
  late final PlayerComponent player;
  EnemyComponent? _collidingEnemy;
  ActiveNinjaComponent? _collidingNinja;
  late final NinjaSpawnerComponent spawner;
  JoystickComponent? joystick;
  late final OverworldPracticeController _practice;
  OverworldPracticeController get practice => _practice;
  late int _currentHealth;
  late int _enemyHealth;
  late int _enemyChakra;
  double _encounterCooldown = 0;
  bool _encounterStarted = false;
  bool _playerLoaded = false;
  String _databaseStatus = 'Preparing local database';

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _chooseLoadouts();
    _currentHealth = profile.stats.calculate('HP', config.statsScaling);
    _practice = OverworldPracticeController(
      training: config.training,
      profile: profile,
      jutsu: playerJutsu,
      statsScaling: config.statsScaling,
      jutsuProgression: config.jutsuProgression,
    );

    await _loadWorld();
    await _prepareDatabase();
    _publishState();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _cycle.update(dt);
    _regenChakra(dt);
    _updateEncounter(dt);
    _publishState();
  }

  void finishEncounter(BattleResult result) {
    encounterRequest.value = null;
    if (result.victory) {
      _collidingEnemy?.removeFromParent();
      if (_collidingNinja != null) {
        spawner.markKilled(_collidingNinja!.ninjaId);
      }
    }
    _collidingEnemy = null;
    _collidingNinja = null;
    _encounterStarted = false;
    _encounterCooldown = config.world.map.encounters.retriggerCooldown;
    player.resetMovement();

    // Persist health/chakra changes.
    _currentHealth = result.playerEndHealth;
    _practice.currentChakra = result.playerEndChakra;

    // Award EXP for jutsus cast in battle.
    for (final jutsuId in result.castedJutsuIds) {
      _practice.awardJutsuBattleExp(
        jutsuId,
        seed: run.seed,
        database: database,
      );
    }

    // If defeated, reset for demo purposes.
    if (result.defeated) {
      _currentHealth = profile.stats.calculate('HP', config.statsScaling);
      _practice.currentChakra = _practice.maxChakra;
    }
    resumeEngine();
    _publishState();
  }

  /// Debug-only: immediately starts a combat encounter with the nearest
  /// visible [ActiveNinjaComponent], regardless of alignment.
  /// Does nothing if an encounter is already running or no ninjas are active.
  void debugForceEncounter() {
    if (_encounterStarted) return;
    final activeNinjas = world.children.whereType<ActiveNinjaComponent>();
    if (activeNinjas.isEmpty) return;

    // Find the nearest ninja to the player.
    ActiveNinjaComponent? nearest;
    double nearestDist = double.infinity;
    for (final ninja in activeNinjas) {
      final dist = (ninja.position - player.position).length;
      if (dist < nearestDist) {
        nearestDist = dist;
        nearest = ninja;
      }
    }
    if (nearest == null) return;

    // Temporarily set cooldown to 0 and force overlap via synthetic call.
    _encounterCooldown = 0;
    _collidingNinja = nearest;

    final statsMap = {
      'health': nearest.stats.calculate('HP', config.statsScaling),
      'chakra': nearest.stats.calculate('CP', config.statsScaling),
      'speed': nearest.stats.calculate('Speed', config.statsScaling),
      'attack': nearest.stats.calculate('Taijutsu', config.statsScaling),
      'defense': nearest.stats.calculate('Armor', config.statsScaling),
    };
    _enemyConfig = EnemyConfig(
      id: nearest.ninjaId,
      displayName: nearest.ninjaName,
      expReward: nearest.stats.level * 15 + 30,
      size: Vector2(16, 16),
      visual: const VisualConfig(
        bodyColor: Colors.red,
        headbandColor: Colors.black,
      ),
      stats: statsMap,
      movementSpeed: nearest.walkSpeed,
      jutsuCount: const CountRange(min: 2, max: 4),
      usableJutsuPool: const [],
      ai: const EnemyAiConfig(
        aggression: 0.7,
        jutsuPreference: 0.6,
        retreatHealthRatio: 0.15,
      ),
      spawn: const EnemySpawnConfig(
        spawnRatePerMinute: 0,
        maxActive: 0,
        spawnCheckSeconds: 9999,
        spawnChancePerCheck: 0,
        spawnDistanceMin: 0,
        spawnDistanceMax: 0,
        despawnDistanceMultiplier: 0,
      ),
    );
    final enemyJutsuCount = 2 + _random.nextInt(3);
    final shuffled = List<JutsuConfig>.from(config.jutsus)..shuffle(_random);
    _enemyJutsu = shuffled.take(enemyJutsuCount).toList();
    _enemyHealth = statsMap['health']!;
    _enemyChakra = statsMap['chakra']!;

    final dynamicPlayerConfig = PlayerConfig(
      displayName: profile.name,
      movementSpeed: config.player.movementSpeed,
      size: config.player.size,
      visual: config.player.visual,
      maxHealth: profile.stats.calculate('HP', config.statsScaling),
      maxChakra: profile.stats.calculate('CP', config.statsScaling),
      stats: PlayerStats(
        speed: profile.stats.calculate('Speed', config.statsScaling),
        attack: profile.stats.calculate('Taijutsu', config.statsScaling),
        defense: profile.stats.calculate('Armor', config.statsScaling),
      ),
      chakraNaturePool: config.player.chakraNaturePool,
      startingJutsuCount: config.player.startingJutsuCount,
      starterJutsuPool: config.player.starterJutsuPool,
    );

    _encounterStarted = true;
    player.resetMovement();
    encounterRequest.value = BattleRequest(
      player: dynamicPlayerConfig,
      playerName: profile.name,
      playerChakraNature: profile.naturalNature,
      playerSecondaryNature: profile.secondaryNature,
      secondaryCostMultiplier: profile.secondaryChakraCostMultiplier,
      playerJutsu: playerJutsu,
      playerCurrentHealth: _currentHealth,
      playerCurrentChakra: _practice.currentChakra,
      enemy: _enemyConfig,
      enemyJutsu: _enemyJutsu,
      enemyCurrentHealth: _enemyHealth,
      enemyCurrentChakra: _enemyChakra,
      jutsuAffinities: config.jutsuAffinities,
    );
    pauseEngine();
  }

  /// Returns the display name of the practiced jutsu, or null if the player
  /// doesn't have enough chakra.
  String? practiceJutsu(String jutsuId) {
    final result = _practice.practiceJutsu(
      jutsuId,
      seed: run.seed,
      database: database,
    );
    _publishState();
    return result;
  }

  void updateRun(GeneratedWorldRun newRun) {
    run = newRun;
    _publishState();
  }

  Future<void> _loadWorld() async {
    final map = ProceduralWorldMap(
      config: config.world.map,
      run: run,
      layoutData: layoutData,
    );
    world.add(map);

    // ── Collision registry ──────────────────────────────────────────────────
    final collisionCfg = config.world.map.collision;
    final registry = CollisionRegistry(
      cellSize: collisionCfg.gridCellSizePx,
      structureMargin: collisionCfg.structureMarginPx,
    );
    registry.registerLayout(layoutData);

    // ── Player ──────────────────────────────────────────────────────────────
    final spawnPosition = Vector2(
      layoutData.playerSpawnX,
      layoutData.playerSpawnY,
    );
    player = PlayerComponent(
      config: config.player,
      spawnPosition: spawnPosition,
      collisionRegistry: registry,
    );
    world.add(player);
    _playerLoaded = true;

    // ── NPC Spawner ─────────────────────────────────────────────────────────
    spawner = NinjaSpawnerComponent(
      run: run,
      config: config.world.map.npcSpawn,
      database: database,
      tileSize: config.world.map.tileSize,
    );
    world.add(spawner);

    // ── Camera ──────────────────────────────────────────────────────────────
    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.zoom = config.world.map.cameraZoom;
    camera.follow(player, snap: true);

    final isDesktop =
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;

    if (!isDesktop) {
      joystick = JoystickComponent(
        knob: CircleComponent(
          radius: 16,
          paint: Paint()..color = Colors.white54,
        ),
        background: CircleComponent(
          radius: 40,
          paint: Paint()..color = Colors.black38,
        ),
        margin: const EdgeInsets.only(left: 32, bottom: 32),
      );
      camera.viewport.add(joystick!);
    }
  }

  @override
  void onScroll(PointerScrollInfo info) {
    var zoom = camera.viewfinder.zoom;
    zoom += info.scrollDelta.global.y > 0 ? -0.1 : 0.1;
    zoom = zoom.clamp(0.2, 5.0);
    camera.viewfinder.zoom = zoom;
  }

  late double _startZoom;

  @override
  void onScaleStart(ScaleStartInfo info) {
    _startZoom = camera.viewfinder.zoom;
  }

  @override
  void onScaleUpdate(ScaleUpdateInfo info) {
    var zoom = _startZoom * info.scale.global.x;
    zoom = zoom.clamp(0.2, 5.0);
    camera.viewfinder.zoom = zoom;
  }

  void _chooseLoadouts() {
    final selector = JutsuLoadoutSelector(_random);
    playerJutsu = selector.choosePlayerJutsu(
      config: config.player,
      allJutsu: config.jutsus,
      chakraNature: profile.naturalNature,
      secondaryNature: profile.secondaryNature,
    );
    if (config.enemies.isNotEmpty) {
      _enemyConfig = config.enemies[_random.nextInt(config.enemies.length)];
      _enemyJutsu = selector.chooseEnemyJutsu(
        config: _enemyConfig,
        allJutsu: config.jutsus,
      );
      _enemyHealth = _enemyConfig.stats['health']!;
      _enemyChakra = _enemyConfig.stats['chakra']!;
    } else {
      _enemyConfig = EnemyConfig(
        id: 'dummy',
        displayName: 'Dummy Scout',
        ai: const EnemyAiConfig(
          jutsuPreference: 0.5,
          aggression: 0.5,
          retreatHealthRatio: 0.2,
        ),
        spawn: const EnemySpawnConfig(
          spawnRatePerMinute: 0,
          maxActive: 0,
          spawnCheckSeconds: 9999,
          spawnChancePerCheck: 0,
          spawnDistanceMin: 0,
          spawnDistanceMax: 0,
          despawnDistanceMultiplier: 0,
        ),
        stats: const {
          'health': 100,
          'chakra': 100,
          'attack': 10,
          'defense': 5,
          'speed': 10,
        },
        visual: const VisualConfig(
          bodyColor: Colors.grey,
          headbandColor: Colors.black,
        ),
        expReward: 50,
        size: Vector2(32, 32),
        movementSpeed: 100,
        jutsuCount: const CountRange(min: 1, max: 1),
        usableJutsuPool: const [],
      );
      _enemyJutsu = const [];
      _enemyHealth = 100;
      _enemyChakra = 100;
    }
  }

  Future<void> _prepareDatabase() async {
    await database.prepareDemoData();
    await database.recordSessionVillage(run.startingVillage.id);
    for (final jutsu in config.jutsus) {
      await database.upsertDiscoveredJutsu(
        id: jutsu.id,
        displayName: jutsu.displayName,
        chakraNature: jutsu.chakraNature,
      );
    }
    final progressList = await database.loadPlayerJutsus(run.seed);
    _practice.initJutsuProgress(progressList);

    final tableCount = await database.contentTableCount();
    _databaseStatus = '$tableCount content tables ready';
  }

  void _regenChakra(double dt) {
    _practice.regen(dt);
  }

  void _updateEncounter(double dt) {
    if (_encounterCooldown > 0) {
      _encounterCooldown -= dt;
      return;
    }
    if (_encounterStarted) return;

    final detector = EncounterDetector(config.world.map.encounters);
    final enemies = world.children.whereType<EnemyComponent>();
    EnemyComponent? collidingEnemy;
    for (final enemy in enemies) {
      if (detector.overlaps(player, enemy)) {
        collidingEnemy = enemy;
        break;
      }
    }

    ActiveNinjaComponent? collidingNinja;
    if (collidingEnemy == null) {
      final activeNinjas = world.children.whereType<ActiveNinjaComponent>();
      for (final ninja in activeNinjas) {
        // Trigger combat on contact with any ninja — alignment check controls
        // rewards and encounter tone, not whether combat occurs at all.
        if (detector.overlaps(player, ninja)) {
          collidingNinja = ninja;
          break;
        }
      }
    }

    if (collidingEnemy == null && collidingNinja == null) return;

    if (collidingEnemy != null) {
      _collidingEnemy = collidingEnemy;
      _enemyConfig = collidingEnemy.config;
      _enemyJutsu = collidingEnemy.knownJutsu;
      _enemyHealth = _enemyConfig.stats['health']!;
      _enemyChakra = _enemyConfig.stats['chakra']!;
    } else if (collidingNinja != null) {
      _collidingNinja = collidingNinja;

      final statsMap = {
        'health': collidingNinja.stats.calculate('HP', config.statsScaling),
        'chakra': collidingNinja.stats.calculate('CP', config.statsScaling),
        'speed': collidingNinja.stats.calculate('Speed', config.statsScaling),
        'attack': collidingNinja.stats.calculate('Taijutsu', config.statsScaling),
        'defense': collidingNinja.stats.calculate('Armor', config.statsScaling),
      };

      _enemyConfig = EnemyConfig(
        id: collidingNinja.ninjaId,
        displayName: collidingNinja.ninjaName,
        expReward: collidingNinja.stats.level * 15 + 30,
        size: Vector2(16, 16),
        visual: const VisualConfig(
          bodyColor: Colors.red,
          headbandColor: Colors.black,
        ),
        stats: statsMap,
        movementSpeed: collidingNinja.walkSpeed,
        jutsuCount: const CountRange(min: 2, max: 4),
        usableJutsuPool: const [],
        ai: const EnemyAiConfig(
          aggression: 0.7,
          jutsuPreference: 0.6,
          retreatHealthRatio: 0.15,
        ),
        spawn: const EnemySpawnConfig(
          spawnRatePerMinute: 0,
          maxActive: 0,
          spawnCheckSeconds: 9999,
          spawnChancePerCheck: 0,
          spawnDistanceMin: 0,
          spawnDistanceMax: 0,
          despawnDistanceMultiplier: 0,
        ),
      );

      final enemyJutsuCount = 2 + _random.nextInt(3); // 2 to 4 jutsus
      final shuffled = List<JutsuConfig>.from(config.jutsus)..shuffle(_random);
      _enemyJutsu = shuffled.take(enemyJutsuCount).toList();

      _enemyHealth = statsMap['health']!;
      _enemyChakra = statsMap['chakra']!;
    }

    final dynamicPlayerConfig = PlayerConfig(
      displayName: profile.name,
      movementSpeed: config.player.movementSpeed,
      size: config.player.size,
      visual: config.player.visual,
      maxHealth: profile.stats.calculate('HP', config.statsScaling),
      maxChakra: profile.stats.calculate('CP', config.statsScaling),
      stats: PlayerStats(
        speed: profile.stats.calculate('Speed', config.statsScaling),
        attack: profile.stats.calculate('Taijutsu', config.statsScaling),
        defense: profile.stats.calculate('Armor', config.statsScaling),
      ),
      chakraNaturePool: config.player.chakraNaturePool,
      startingJutsuCount: config.player.startingJutsuCount,
      starterJutsuPool: config.player.starterJutsuPool,
    );

    _encounterStarted = true;
    player.resetMovement();
    encounterRequest.value = BattleRequest(
      player: dynamicPlayerConfig,
      playerName: profile.name,
      playerChakraNature: profile.naturalNature,
      playerSecondaryNature: profile.secondaryNature,
      secondaryCostMultiplier: profile.secondaryChakraCostMultiplier,
      playerJutsu: playerJutsu,
      playerCurrentHealth: _currentHealth,
      playerCurrentChakra: _practice.currentChakra,
      enemy: _enemyConfig,
      enemyJutsu: _enemyJutsu,
      enemyCurrentHealth: _enemyHealth,
      enemyCurrentChakra: _enemyChakra,
      jutsuAffinities: config.jutsuAffinities,
    );
    pauseEngine();
  }

  void _publishState() {
    demoState.value = DemoState(
      villageName: run.startingVillage.name,
      playerName: profile.name,
      runSeed: run.seed,
      villageCount: run.villages.length,
      ninjaCount: run.ninjas.length,
      trainingBoost: config.training.fieldBoostPercent,
      phase: _cycle.phase,
      cycleProgress: _cycle.progress,
      playerChakraNature: profile.naturalNature,
      playerSecondaryNature: profile.secondaryNature,
      playerJutsuNames: playerJutsu.map((jutsu) => jutsu.displayName).toList(),
      currentChakra: _practice.currentChakra,
      maxChakra: _practice.maxChakra,
      practiceLog: _practice.practiceLog,
      practiceJutsus: _practice.practiceStates(),
      enemyName: _enemyConfig.displayName,
      enemyJutsuNames: _enemyJutsu.map((jutsu) => jutsu.displayName).toList(),
      databaseStatus: _databaseStatus,
      playerTileX: _playerLoaded
          ? player.position.x / config.world.map.tileSize
          : 0.0,
      playerTileY: _playerLoaded
          ? player.position.y / config.world.map.tileSize
          : 0.0,
    );
  }
}
