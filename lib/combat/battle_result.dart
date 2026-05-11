enum BattleOutcome { victory, defeat, fled }

class BattleResult {
  const BattleResult({
    required this.outcome,
    required this.playerHealth,
    required this.playerChakra,
    required this.enemyHealth,
    required this.enemyChakra,
  });

  final BattleOutcome outcome;
  final int playerHealth;
  final int playerChakra;
  final int enemyHealth;
  final int enemyChakra;

  bool get victory => outcome == BattleOutcome.victory;
  bool get defeated => outcome == BattleOutcome.defeat;
  int get playerEndHealth => playerHealth;
  int get playerEndChakra => playerChakra;
}
