import 'dart:math';
import 'package:flame/components.dart';
import '../config/models/enemy_config.dart';
import '../jutsu/jutsu_loadout_selector.dart';
import 'enemy_component.dart';
import 'shinobi_world_game.dart';

class NpcManagerComponent extends Component
    with HasGameReference<ShinobiWorldGame> {
  NpcManagerComponent({required this.configs});

  final List<EnemyConfig> configs;
  final Random _random = Random();
  late Timer _spawnTimer;

  // Track active enemies by config ID
  final Map<String, List<EnemyComponent>> _activeEnemies = {};

  @override
  void onLoad() {
    for (final config in configs) {
      _activeEnemies[config.id] = [];
    }

    final interval = configs
        .map((config) => config.spawn.spawnCheckSeconds)
        .reduce(min);
    _spawnTimer = Timer(interval, onTick: _updateNpcs, repeat: true);
  }

  @override
  void update(double dt) {
    _spawnTimer.update(dt);
  }

  void _updateNpcs() {
    final playerPos = game.player.position;
    final viewportSize = game.camera.viewport.size;
    final maxDespawnDist = configs
        .map(
          (config) =>
              viewportSize.length * config.spawn.despawnDistanceMultiplier,
        )
        .reduce(max);

    // 1. Despawn enemies that are too far away
    for (final config in configs) {
      final activeList = _activeEnemies[config.id]!;
      for (var i = activeList.length - 1; i >= 0; i--) {
        final enemy = activeList[i];
        if (enemy.position.distanceTo(playerPos) > maxDespawnDist) {
          enemy.removeFromParent();
          activeList.removeAt(i);
        }
      }
    }

    // 2. Spawn new enemies
    for (final config in configs) {
      final activeList = _activeEnemies[config.id]!;
      if (activeList.length < config.spawn.maxActive) {
        if (_random.nextDouble() < config.spawn.spawnChancePerCheck) {
          _spawnEnemy(config);
        }
      }
    }
  }

  void _spawnEnemy(EnemyConfig config) {
    final playerPos = game.player.position;

    // Spawn outside the viewport but inside despawn radius
    final angle = _random.nextDouble() * 2 * pi;
    final distance =
        config.spawn.spawnDistanceMin +
        _random.nextDouble() *
            (config.spawn.spawnDistanceMax - config.spawn.spawnDistanceMin);

    final spawnPos =
        playerPos + Vector2(cos(angle) * distance, sin(angle) * distance);

    // Keep within world bounds
    final bounds = game.config.world.map.bounds;
    spawnPos.x = spawnPos.x.clamp(0.0, bounds.x);
    spawnPos.y = spawnPos.y.clamp(0.0, bounds.y);

    final enemyJutsu = JutsuLoadoutSelector(
      _random,
    ).chooseEnemyJutsu(config: config, allJutsu: game.config.jutsus);

    final enemy = EnemyComponent(
      config: config,
      knownJutsu: enemyJutsu,
      spawnPosition: spawnPos,
    );

    game.world.add(enemy);
    _activeEnemies[config.id]!.add(enemy);
  }
}
