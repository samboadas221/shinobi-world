import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shinobi_world/combat/battle_controller.dart';
import 'package:shinobi_world/combat/battle_request.dart';
import 'package:shinobi_world/config/game_config_loader.dart';

import 'package:shinobi_world/config/models/enemy_config.dart';
import 'package:shinobi_world/config/models/visual_config.dart';
import 'package:shinobi_world/config/models/count_range.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('attack and jutsu actions update combat state', () async {
    final config = await GameConfigLoader.load();
    final fireball = config.jutsus.firstWhere(
      (jutsu) => jutsu.id == 'fireball',
    );
    const mockAi = EnemyAiConfig(
      jutsuPreference: 0.5,
      aggression: 0.5,
      retreatHealthRatio: 0.2,
    );
    const mockSpawn = EnemySpawnConfig(
      spawnCheckSeconds: 10,
      spawnChancePerCheck: 0.5,
      spawnDistanceMin: 100,
      spawnDistanceMax: 200,
      maxActive: 5,
      despawnDistanceMultiplier: 2.0,
      spawnRatePerMinute: 6.0,
    );
    const mockVisual = VisualConfig(
      bodyColor: Colors.black,
      headbandColor: Colors.white,
    );
    final mockEnemy = EnemyConfig(
      id: 'scout',
      displayName: 'Scout',
      ai: mockAi,
      spawn: mockSpawn,
      stats: const {
        'health': 100,
        'chakra': 100,
        'attack': 10,
        'defense': 5,
        'speed': 10,
      },
      visual: mockVisual,
      expReward: 50,
      size: Vector2(32, 32),
      movementSpeed: 100.0,
      jutsuCount: const CountRange(min: 1, max: 1),
      usableJutsuPool: const ['fireball'],
    );

    final request = BattleRequest(
      player: config.player,
      playerName: 'Test Shinobi',
      playerChakraNature: 'fire',
      playerSecondaryNature: 'water',
      secondaryCostMultiplier: 1.25,
      playerJutsu: [fireball],
      playerCurrentHealth: config.player.maxHealth,
      playerCurrentChakra: config.player.maxChakra,
      enemy: mockEnemy,
      enemyJutsu: const [],
      enemyCurrentHealth: 100,
      enemyCurrentChakra: 100,
    );

    final attackBattle = BattleController(
      request: request,
      config: config.combat,
    );
    attackBattle.playerAttack();
    expect(
      attackBattle.enemy.currentHealth,
      lessThan(attackBattle.enemy.maxHealth),
    );

    final jutsuBattle = BattleController(
      request: request,
      config: config.combat,
    );
    jutsuBattle.playerUseJutsu(fireball);
    expect(
      jutsuBattle.player.currentChakra,
      lessThan(jutsuBattle.player.maxChakra),
    );
    expect(
      jutsuBattle.enemy.currentHealth,
      lessThan(jutsuBattle.enemy.maxHealth),
    );
  });
}
