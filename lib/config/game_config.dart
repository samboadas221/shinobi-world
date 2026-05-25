import 'models/app_config.dart';
import 'models/character_config.dart';
import 'models/clothing_config.dart';
import 'models/combat_config.dart';
import 'models/enemy_config.dart';
import 'models/jutsu_config.dart';
import 'models/player_config.dart';
import 'models/progression_config.dart';
import 'models/summon_config.dart';
import 'models/village_population_config.dart';
import 'models/world_config.dart';
import 'models/world_rules_config.dart';
import 'models/world_run_config.dart';
import 'models/stats_scaling_config.dart';
import 'models/jutsu_progression_config.dart';

class GameConfig {
  const GameConfig({
    required this.app,
    required this.character,
    required this.clothing,
    required this.world,
    required this.worldRun,
    required this.villagePopulation,
    required this.training,
    required this.player,
    required this.combat,
    required this.progression,
    required this.jutsus,
    required this.enemies,
    required this.summons,
    required this.statsScaling,
    required this.jutsuProgression,
  });

  final AppConfig app;
  final CharacterCreationConfig character;
  final ClothingConfig clothing;
  final WorldConfig world;
  final WorldRunConfig worldRun;
  final VillagePopulationConfig villagePopulation;
  final TrainingConfig training;
  final PlayerConfig player;
  final CombatConfig combat;
  final ProgressionConfig progression;
  final List<JutsuConfig> jutsus;
  final List<EnemyConfig> enemies;
  final List<SummonContractConfig> summons;
  final StatsScalingConfig statsScaling;
  final JutsuProgressionConfig jutsuProgression;
}
