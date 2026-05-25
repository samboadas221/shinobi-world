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
import 'demo_state.dart';
import 'enemy_component.dart';
import 'npc_manager_component.dart';
import 'player_component.dart';
import 'procedural_world_map.dart';
import 'world_layout/world_layout_data.dart';
import 'package:flutter/material.dart' show Colors, Paint, EdgeInsets;
import 'package:flame/experimental.dart';

class ShinobiWorldGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection, ScrollDetector, ScaleDetector {
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
    }
    _collidingEnemy = null;
    _encounterStarted = false;
    _encounterCooldown = config.world.map.encounters.retriggerCooldown;
    player.resetMovement();

    // Persist health/chakra changes
    _currentHealth = result.playerEndHealth;
    _practice.currentChakra = result.playerEndChakra;

    // Award EXP for jutsus cast in battle
    for (final jutsuId in result.castedJutsuIds) {
      _practice.awardJutsuBattleExp(jutsuId, seed: run.seed, database: database);
    }

    // If defeated, reset for demo purposes
    if (result.defeated) {
      _currentHealth = profile.stats.calculate('HP', config.statsScaling);
      _practice.currentChakra = _practice.maxChakra;
    }
    resumeEngine();
    _publishState();
  }

  /// Returns the display name of the practiced jutsu, or null if
  /// the player doesn't have enough chakra.
  String? practiceJutsu(String jutsuId) {
    final result = _practice.practiceJutsu(jutsuId, seed: run.seed, database: database);
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

    // Spawn player at the pre-calculated starting village core road/grass tile spawn point
    final spawnPosition = Vector2(
      layoutData.playerSpawnX,
      layoutData.playerSpawnY,
    );

    player = PlayerComponent(
      config: config.player,
      spawnPosition: spawnPosition,
    );
    world.add(player);
    _playerLoaded = true;

    final npcManager = NpcManagerComponent(configs: config.enemies);
    world.add(npcManager);

    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.zoom = config.world.map.cameraZoom;
    camera.follow(player, snap: true);

    // Set bounds based on rolled tile size
    final mapWidth = run.mapWidthTiles * config.world.map.tileSize;
    final mapHeight = run.mapHeightTiles * config.world.map.tileSize;
    camera.setBounds(
      Rectangle.fromLTWH(
        0,
        0,
        mapWidth,
        mapHeight,
      ),
    );

    final isDesktop = defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;

    if (!isDesktop) {
      joystick = JoystickComponent(
        knob: CircleComponent(radius: 16, paint: Paint()..color = Colors.white54),
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
    if (_encounterStarted) {
      return;
    }
    final detector = EncounterDetector(config.world.map.encounters);
    final enemies = world.children.whereType<EnemyComponent>();
    EnemyComponent? collidingEnemy;
    for (final enemy in enemies) {
      if (detector.overlaps(player, enemy)) {
        collidingEnemy = enemy;
        break;
      }
    }

    if (collidingEnemy == null) {
      return;
    }

    _collidingEnemy = collidingEnemy;
    _enemyConfig = collidingEnemy.config;
    _enemyJutsu = collidingEnemy.knownJutsu;
    _enemyHealth = _enemyConfig.stats['health']!;
    _enemyChakra = _enemyConfig.stats['chakra']!;

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
      playerTileX: _playerLoaded ? player.position.x / config.world.map.tileSize : 0.0,
      playerTileY: _playerLoaded ? player.position.y / config.world.map.tileSize : 0.0,
    );
  }
}
