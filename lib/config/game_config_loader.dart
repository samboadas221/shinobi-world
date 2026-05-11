import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';

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
import 'game_config.dart';

class GameConfigLoader {
  static const _manifestPath = 'assets/configs/config_manifest.yaml';

  static Future<GameConfig> load() async {
    final manifest = await _loadMap(_manifestPath);
    final configs = manifest['configs'] as YamlMap;

    final world = WorldConfig(
      time: WorldTimeConfig.fromYaml(
        await _loadManifestMap(configs, 'world_time'),
      ),
      villages: VillageConfig.listFromYaml(
        await _loadManifestMap(configs, 'world_villages'),
      ),
      map: WorldMapConfig.fromYaml(
        await _loadManifestMap(configs, 'world_map'),
      ),
      encounters: EncounterConfig.fromYaml(
        await _loadManifestMap(configs, 'world_encounters'),
      ),
    );

    return GameConfig(
      app: AppConfig.fromYaml(await _loadManifestMap(configs, 'app_brand')),
      character: CharacterCreationConfig.fromYaml(
        await _loadManifestMap(configs, 'character_creation'),
      ),
      clothing: ClothingConfig.fromYaml(
        await _loadManifestMap(configs, 'character_clothing'),
      ),
      world: world,
      worldRun: WorldRunConfig.fromYaml(
        await _loadManifestMap(configs, 'world_run_generation'),
      ),
      villagePopulation: VillagePopulationConfig.fromYaml(
        await _loadManifestMap(configs, 'world_village_configuration'),
      ),
      passiveSimulation: PassiveSimulationConfig.fromYaml(
        await _loadManifestMap(configs, 'world_passive_simulation'),
      ),
      exam: ExamConfig.fromYaml(await _loadManifestMap(configs, 'world_exam')),
      training: TrainingConfig.fromYaml(
        await _loadManifestMap(configs, 'world_training'),
      ),
      player: PlayerConfig.fromYaml(
        await _loadManifestMap(configs, 'player_base'),
      ),
      combat: CombatConfig(
        turns: TurnConfig.fromYaml(
          await _loadManifestMap(configs, 'combat_turns'),
        ),
        reaction: ReactionConfig.fromYaml(
          await _loadManifestMap(configs, 'combat_reaction'),
        ),
        ui: CombatUiConfig.fromYaml(
          await _loadManifestMap(configs, 'combat_ui'),
        ),
        damage: DamageConfig.fromYaml(
          await _loadManifestMap(configs, 'combat_damage'),
        ),
      ),
      progression: ProgressionConfig.fromYaml(
        await _loadManifestMap(configs, 'progression_exp'),
      ),
      jutsus: await _loadList(configs['jutsu'], JutsuConfig.fromYaml),
      enemies: await _loadList(configs['enemies'], EnemyConfig.fromYaml),
      summons: await _loadList(
        configs['summons'],
        SummonContractConfig.fromYaml,
      ),
    );
  }

  static Future<YamlMap> _loadManifestMap(YamlMap manifest, String key) {
    return _loadMap('assets/${manifest[key]}');
  }

  static Future<List<T>> _loadList<T>(
    Object? paths,
    T Function(YamlMap yaml) parser,
  ) async {
    final yamlPaths = paths as YamlList;
    final items = <T>[];
    for (final path in yamlPaths) {
      items.add(parser(await _loadMap('assets/$path')));
    }
    return items;
  }

  static Future<YamlMap> _loadMap(String path) async {
    final rawYaml = await rootBundle.loadString(path);
    return loadYaml(rawYaml) as YamlMap;
  }
}
