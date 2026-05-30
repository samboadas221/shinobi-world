import '../config/models/enemy_config.dart';
import '../config/models/jutsu_affinity_config.dart';
import '../config/models/jutsu_config.dart';
import '../config/models/player_config.dart';

class BattleRequest {
  const BattleRequest({
    required this.player,
    required this.playerName,
    required this.playerChakraNature,
    required this.playerSecondaryNature,
    required this.secondaryCostMultiplier,
    required this.playerJutsu,
    required this.playerCurrentHealth,
    required this.playerCurrentChakra,
    required this.enemy,
    required this.enemyJutsu,
    required this.enemyCurrentHealth,
    required this.enemyCurrentChakra,
    required this.jutsuAffinities,
  });

  final PlayerConfig player;
  final String playerName;
  final String playerChakraNature;
  final String playerSecondaryNature;
  final double secondaryCostMultiplier;
  final List<JutsuConfig> playerJutsu;
  final int playerCurrentHealth;
  final int playerCurrentChakra;
  final EnemyConfig enemy;
  final List<JutsuConfig> enemyJutsu;
  final int enemyCurrentHealth;
  final int enemyCurrentChakra;
  final JutsuAffinityConfig jutsuAffinities;
}
