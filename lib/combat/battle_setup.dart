import 'battle_participant.dart';
import 'battle_request.dart';

class BattleSetup {
  const BattleSetup(this.request);

  final BattleRequest request;

  List<BattleParticipant> participantsByTurnOrder() {
    final participants = [player(), enemy()];
    participants.sort((a, b) => b.speed.compareTo(a.speed));
    return participants;
  }

  BattleParticipant player() {
    return BattleParticipant(
      name: request.playerName,
      maxHealth: request.player.maxHealth,
      currentHealth: request.playerCurrentHealth,
      maxChakra: request.player.maxChakra,
      currentChakra: request.playerCurrentChakra,
      speed: request.player.stats.speed,
      attack: request.player.stats.attack,
      defense: request.player.stats.defense,
      jutsu: request.playerJutsu,
    );
  }

  BattleParticipant enemy() {
    return BattleParticipant(
      name: request.enemy.displayName,
      maxHealth: request.enemy.stats['health']!,
      currentHealth: request.enemyCurrentHealth,
      maxChakra: request.enemy.stats['chakra']!,
      currentChakra: request.enemyCurrentChakra,
      speed: request.enemy.stats['speed']!,
      attack: request.enemy.stats['attack']!,
      defense: request.enemy.stats['defense']!,
      jutsu: request.enemyJutsu,
    );
  }
}
