import 'package:yaml/yaml.dart';

class StatsScalingConfig {
  const StatsScalingConfig({
    required this.tiers,
    required this.multipliers,
    required this.bases,
    required this.maxes,
  });

  factory StatsScalingConfig.fromYaml(YamlMap yaml) {
    final root = yaml['stats_scaling'] as YamlMap;
    final tiers = root['tiers'] as YamlMap;
    final multipliers = root['multipliers'] as YamlMap;
    final bases = root['bases'] as YamlMap;
    final maxes = root['maxes'] as YamlMap;

    return StatsScalingConfig(
      tiers: {
        for (final entry in tiers.entries)
          entry.key as String: (entry.value as num).toDouble(),
      },
      multipliers: {
        for (final entry in multipliers.entries)
          entry.key as String: (entry.value as num).toDouble(),
      },
      bases: {
        for (final entry in bases.entries)
          entry.key as String: (entry.value as num).toDouble(),
      },
      maxes: {
        for (final entry in maxes.entries)
          entry.key as String: (entry.value as num).toDouble(),
      },
    );
  }

  final Map<String, double> tiers;
  final Map<String, double> multipliers;
  final Map<String, double> bases;
  final Map<String, double> maxes;
}
