import 'package:yaml/yaml.dart';

import 'count_range.dart';
import 'yaml_readers.dart';

class VillagePopulationConfig {
  const VillagePopulationConfig({required this.tiers, required this.roleStats});

  factory VillagePopulationConfig.fromYaml(YamlMap yaml) {
    final source = yaml['village_configuration'] as YamlMap;
    final tiers = source['size_tiers'] as YamlList;
    final roleStats = source['role_stats'] as YamlMap;
    return VillagePopulationConfig(
      tiers: tiers.cast<YamlMap>().map(VillageSizeTierConfig.fromYaml).toList(),
      roleStats: {
        for (final entry in roleStats.entries)
          entry.key as String: NinjaStatRangeConfig.fromYaml(
            entry.value as YamlMap,
          ),
      },
    );
  }

  final List<VillageSizeTierConfig> tiers;
  final Map<String, NinjaStatRangeConfig> roleStats;

  VillageSizeTierConfig tierForSize(int size) {
    return tiers.firstWhere((tier) => tier.size == size);
  }
}

class NinjaStatRangeConfig {
  const NinjaStatRangeConfig({required this.stats});

  factory NinjaStatRangeConfig.fromYaml(YamlMap yaml) {
    return NinjaStatRangeConfig(
      stats: {
        for (final entry in yaml.entries)
          entry.key as String: CountRange.fromYaml(entry.value as YamlMap),
      },
    );
  }

  final Map<String, CountRange> stats;
}

class VillageSizeTierConfig {
  const VillageSizeTierConfig({
    required this.size,
    required this.label,
    required this.roles,
    required this.adultPopulation,
  });

  factory VillageSizeTierConfig.fromYaml(YamlMap yaml) {
    final roles = yaml['roles'] as YamlMap;
    return VillageSizeTierConfig(
      size: readInt(yaml, 'size'),
      label: readString(yaml, 'label'),
      roles: {
        for (final entry in roles.entries)
          entry.key as String: CountRange.fromYaml(entry.value as YamlMap),
      },
      adultPopulation: CountRange.fromYaml(yaml['adult_population'] as YamlMap),
    );
  }

  final int size;
  final String label;
  final Map<String, CountRange> roles;
  final CountRange adultPopulation;
}
