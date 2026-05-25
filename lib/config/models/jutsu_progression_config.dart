import 'package:yaml/yaml.dart';
import 'yaml_readers.dart';

class JutsuProgressionConfig {
  const JutsuProgressionConfig({
    required this.expPerUse,
    required this.expToNextLevel,
    required this.chakraReductionPercent,
    required this.handSealsReduction,
    required this.damageBoostPercent,
    required this.maxLevels,
  });

  factory JutsuProgressionConfig.fromYaml(YamlMap yaml) {
    final root = yaml['jutsu_progression'] as YamlMap;
    final bonuses = root['bonuses'] as YamlMap;
    final maxLevels = root['max_levels'] as YamlMap;

    return JutsuProgressionConfig(
      expPerUse: readInt(root, 'exp_per_use'),
      expToNextLevel: readInt(root, 'exp_to_next_level'),
      chakraReductionPercent: readDouble(bonuses, 'chakra_reduction_percent'),
      handSealsReduction: readInt(bonuses, 'hand_seals_reduction'),
      damageBoostPercent: readDouble(bonuses, 'damage_boost_percent'),
      maxLevels: {
        for (final entry in maxLevels.entries)
          entry.key as String: (entry.value as num).toInt(),
      },
    );
  }

  final int expPerUse;
  final int expToNextLevel;
  final double chakraReductionPercent;
  final int handSealsReduction;
  final double damageBoostPercent;
  final Map<String, int> maxLevels;
}
