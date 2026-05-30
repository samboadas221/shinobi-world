import 'battle_participant.dart';
import 'battle_request.dart';

class BattleSetup {
  const BattleSetup(this.request);

  final BattleRequest request;

  BattleParticipant player() {
    return BattleParticipant(
      name: request.playerName,
      maxHealth: request.player.maxHealth,
      currentHealth: request.playerCurrentHealth,
      maxChakra: request.player.maxChakra,
      currentChakra: request.playerCurrentChakra,
      baseSpeed: request.player.stats.speed,
      baseAttack: request.player.stats.attack,
      baseDefense: request.player.stats.defense,
      jutsu: request.playerJutsu,
    );
  }

  BattleParticipant enemy() {
    return BattleParticipant(
      name: request.enemy.displayName,
      maxHealth: request.enemyCurrentHealth,
      currentHealth: request.enemyCurrentHealth,
      maxChakra: request.enemyCurrentChakra,
      currentChakra: request.enemyCurrentChakra,
      baseSpeed: request.enemy.stats['speed'] ?? 10,
      baseAttack: request.enemy.stats['attack'] ?? 10,
      baseDefense: request.enemy.stats['defense'] ?? 5,
      jutsu: request.enemyJutsu,
    );
  }
}
