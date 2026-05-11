import 'package:yaml/yaml.dart';

import 'yaml_readers.dart';

class ProgressionConfig {
  const ProgressionConfig({
    required this.globalExpMultiplier,
    required this.roguePathExpMultiplier,
    required this.rankThresholds,
  });

  factory ProgressionConfig.fromYaml(YamlMap yaml) {
    final progression = yaml['progression'] as YamlMap;
    return ProgressionConfig(
      globalExpMultiplier: readDouble(progression, 'global_exp_multiplier'),
      roguePathExpMultiplier: readDouble(
        progression,
        'rogue_path_exp_multiplier',
      ),
      rankThresholds: readIntMap(progression, 'rank_thresholds'),
    );
  }

  final double globalExpMultiplier;
  final double roguePathExpMultiplier;
  final Map<String, int> rankThresholds;
}
