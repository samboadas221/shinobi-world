import 'package:yaml/yaml.dart';

import 'count_range.dart';
import 'yaml_readers.dart';

class WorldRunConfig {
  const WorldRunConfig({
    required this.seed,
    required this.villageCount,
    required this.villageSize,
    required this.villageNamePool,
    required this.rogue,
    required this.names,
  });

  factory WorldRunConfig.fromYaml(YamlMap yaml) {
    final run = yaml['run_generation'] as YamlMap;
    return WorldRunConfig(
      seed: CountRange.fromYaml(run['seed'] as YamlMap),
      villageCount: CountRange.fromYaml(run['village_count'] as YamlMap),
      villageSize: CountRange.fromYaml(run['village_size'] as YamlMap),
      villageNamePool: readStringList(run, 'village_name_pool'),
      rogue: RogueGenerationConfig.fromYaml(run['rogue_ninja'] as YamlMap),
      names: NpcNameConfig.fromYaml(run['npc_names'] as YamlMap),
    );
  }

  final CountRange seed;
  final CountRange villageCount;
  final CountRange villageSize;
  final List<String> villageNamePool;
  final RogueGenerationConfig rogue;
  final NpcNameConfig names;
}

class RogueGenerationConfig {
  const RogueGenerationConfig({
    required this.countPerVillage,
    required this.alignments,
    required this.bingoListChance,
  });

  factory RogueGenerationConfig.fromYaml(YamlMap yaml) {
    final alignments = yaml['alignments'] as YamlMap;
    return RogueGenerationConfig(
      countPerVillage: CountRange.fromYaml(
        yaml['count_per_village'] as YamlMap,
      ),
      alignments: {
        for (final entry in alignments.entries)
          entry.key as String: (entry.value as num).toDouble(),
      },
      bingoListChance: readDouble(yaml, 'bingo_list_chance'),
    );
  }

  final CountRange countPerVillage;
  final Map<String, double> alignments;
  final double bingoListChance;
}

class NpcNameConfig {
  const NpcNameConfig({required this.first, required this.clan});

  factory NpcNameConfig.fromYaml(YamlMap yaml) {
    return NpcNameConfig(
      first: readStringList(yaml, 'first'),
      clan: readStringList(yaml, 'clan'),
    );
  }

  final List<String> first;
  final List<String> clan;
}
