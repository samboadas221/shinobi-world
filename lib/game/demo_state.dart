class DemoState {
  const DemoState({
    required this.villageName,
    required this.playerName,
    required this.runSeed,
    required this.villageCount,
    required this.ninjaCount,
    required this.trainingBoost,
    required this.phase,
    required this.cycleProgress,
    required this.playerChakraNature,
    required this.playerSecondaryNature,
    required this.playerJutsuNames,
    required this.currentChakra,
    required this.maxChakra,
    required this.practiceLog,
    required this.practiceJutsus,
    required this.enemyName,
    required this.enemyJutsuNames,
    required this.databaseStatus,
    required this.playerTileX,
    required this.playerTileY,
  });

  factory DemoState.empty() {
    return const DemoState(
      villageName: '',
      playerName: '',
      runSeed: 0,
      villageCount: 0,
      ninjaCount: 0,
      trainingBoost: 0,
      phase: '',
      cycleProgress: 0,
      playerChakraNature: '',
      playerSecondaryNature: '',
      playerJutsuNames: [],
      currentChakra: 0,
      maxChakra: 0,
      practiceLog: '',
      practiceJutsus: [],
      enemyName: '',
      enemyJutsuNames: [],
      databaseStatus: '',
      playerTileX: 0.0,
      playerTileY: 0.0,
    );
  }

  final String villageName;
  final String playerName;
  final int runSeed;
  final int villageCount;
  final int ninjaCount;
  final double trainingBoost;
  final String phase;
  final double cycleProgress;
  final String playerChakraNature;
  final String playerSecondaryNature;
  final List<String> playerJutsuNames;
  final int currentChakra;
  final int maxChakra;
  final String practiceLog;
  final List<JutsuPracticeState> practiceJutsus;
  final String enemyName;
  final List<String> enemyJutsuNames;
  final String databaseStatus;
  final double playerTileX;
  final double playerTileY;
}

class JutsuPracticeState {
  const JutsuPracticeState({
    required this.id,
    required this.name,
    required this.cost,
    required this.level,
    required this.requiredSeals,
  });

  final String id;
  final String name;
  final int cost;
  final int level;
  final int requiredSeals;
}
