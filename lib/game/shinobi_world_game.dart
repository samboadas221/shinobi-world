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
import 'package:flutter/material.dart' show Colors, Paint, EdgeInsets;
import 'package:flame/experimental.dart';

class ShinobiWorldGame extends FlameGame with HasKeyboardHandlerComponents {
  ShinobiWorldGame({
    required this.config,
    required this.database,
    required this.profile,
    required this.run,
  }) : _cycle = DayNightCycle(config.world.time);

  final GameConfig config;
  final ShinobiDatabase database;
  final PlayerProfile profile;
  GeneratedWorldRun run;
  final ValueNotifier<DemoState> demoState = ValueNotifier(DemoState.empty());
  final ValueNotifier<BattleRequest?> encounterRequest = ValueNotifier(null);
  final DayNightCycle _cycle;
  final Random _random = Random();

  late final GeneratedVillage _spawnVillage;
  late final List<JutsuConfig> playerJutsu;
  late EnemyConfig _enemyConfig;
  late List<JutsuConfig> _enemyJutsu;
  late final PlayerComponent player;
  EnemyComponent? _collidingEnemy;
  late final JoystickComponent joystick;
  late final OverworldPracticeController _practice;
  late int _currentHealth;
  late int _enemyHealth;
  late int _enemyChakra;
  double _encounterCooldown = 0;
  bool _encounterStarted = false;
  String _databaseStatus = 'Preparing local database';

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _spawnVillage = run.startingVillage;
    _chooseLoadouts();
    _currentHealth = config.player.maxHealth;
    _practice = OverworldPracticeController(
      player: config.player,
      training: config.training,
      profile: profile,
      jutsu: playerJutsu,
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
    _encounterCooldown = config.world.encounters.retriggerCooldown;
    player.resetMovement();

    // Persist health/chakra changes
    _currentHealth = result.playerEndHealth;
    _practice.currentChakra = result.playerEndChakra;

    // If defeated, reset for demo purposes
    if (result.defeated) {
      _currentHealth = config.player.maxHealth;
      _practice.currentChakra = config.player.maxChakra;
    }
    resumeEngine();
    _publishState();
  }

  /// Returns the display name of the practiced jutsu, or null if
  /// the player doesn't have enough chakra.
  String? practiceJutsu(String jutsuId) {
    final result = _practice.practiceJutsu(jutsuId);
    _publishState();
    return result;
  }

  void updateRun(GeneratedWorldRun newRun) {
    run = newRun;
    _publishState();
  }

  Future<void> _loadWorld() async {
    final map = ProceduralWorldMap(config: config.world.map, run: run);
    world.add(map);

    player = PlayerComponent(
      config: config.player,
      spawnPosition: Vector2(_spawnVillage.x, _spawnVillage.y),
    );
    world.add(player);

    final npcManager = NpcManagerComponent(configs: config.enemies);
    world.add(npcManager);

    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.zoom = config.world.map.cameraZoom;
    camera.follow(player, snap: true);

    // Set bounds
    camera.setBounds(
      Rectangle.fromLTWH(
        0,
        0,
        config.world.map.bounds.x,
        config.world.map.bounds.y,
      ),
    );

    joystick = JoystickComponent(
      knob: CircleComponent(radius: 16, paint: Paint()..color = Colors.white54),
      background: CircleComponent(
        radius: 40,
        paint: Paint()..color = Colors.black38,
      ),
      margin: const EdgeInsets.only(left: 32, bottom: 32),
    );
    camera.viewport.add(joystick);
  }

  void _chooseLoadouts() {
    final selector = JutsuLoadoutSelector(_random);
    playerJutsu = selector.choosePlayerJutsu(
      config: config.player,
      allJutsu: config.jutsus,
      chakraNature: profile.naturalNature,
      secondaryNature: profile.secondaryNature,
    );
    _enemyConfig = config.enemies[_random.nextInt(config.enemies.length)];
    _enemyJutsu = selector.chooseEnemyJutsu(
      config: _enemyConfig,
      allJutsu: config.jutsus,
    );
    _enemyHealth = _enemyConfig.stats['health']!;
    _enemyChakra = _enemyConfig.stats['chakra']!;
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
    final detector = EncounterDetector(config.world.encounters);
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

    _encounterStarted = true;
    player.resetMovement();
    encounterRequest.value = BattleRequest(
      player: config.player,
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
      maxChakra: config.player.maxChakra,
      practiceLog: _practice.practiceLog,
      practiceJutsus: _practice.practiceStates(),
      enemyName: _enemyConfig.displayName,
      enemyJutsuNames: _enemyJutsu.map((jutsu) => jutsu.displayName).toList(),
      databaseStatus: _databaseStatus,
    );
  }
}
