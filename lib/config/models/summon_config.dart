import 'package:yaml/yaml.dart';

import 'yaml_readers.dart';

class SummonContractConfig {
  const SummonContractConfig({
    required this.id,
    required this.displayName,
    required this.summons,
  });

  factory SummonContractConfig.fromYaml(YamlMap yaml) {
    final contract = yaml['summon_contract'] as YamlMap;
    final summons = contract['summons'] as YamlList;
    return SummonContractConfig(
      id: readString(contract, 'id'),
      displayName: readString(contract, 'display_name'),
      summons: summons.cast<YamlMap>().map(SummonConfig.fromYaml).toList(),
    );
  }

  final String id;
  final String displayName;
  final List<SummonConfig> summons;
}

class SummonConfig {
  const SummonConfig({
    required this.id,
    required this.displayName,
    required this.chakraCost,
    required this.cooldown,
  });

  factory SummonConfig.fromYaml(YamlMap yaml) {
    return SummonConfig(
      id: readString(yaml, 'id'),
      displayName: readString(yaml, 'display_name'),
      chakraCost: readInt(yaml, 'chakra_cost'),
      cooldown: readDouble(yaml, 'cooldown_seconds'),
    );
  }

  final String id;
  final String displayName;
  final int chakraCost;
  final double cooldown;
}
