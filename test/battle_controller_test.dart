import 'package:flutter_test/flutter_test.dart';
import 'package:shinobi_world/combat/battle_controller.dart';
import 'package:shinobi_world/combat/battle_request.dart';
import 'package:shinobi_world/config/game_config_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('attack and jutsu actions update combat state', () async {
    final config = await GameConfigLoader.load();
    final fireball = config.jutsus.firstWhere(
      (jutsu) => jutsu.id == 'fireball',
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
      enemy: config.enemies.single,
      enemyJutsu: const [],
      enemyCurrentHealth: config.enemies.single.stats['health']!,
      enemyCurrentChakra: config.enemies.single.stats['chakra']!,
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
