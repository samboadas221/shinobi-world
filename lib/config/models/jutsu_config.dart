import 'package:yaml/yaml.dart';

import 'yaml_readers.dart';

class JutsuConfig {
  const JutsuConfig({
    required this.id,
    required this.displayName,
    required this.chakraNature,
    required this.damage,
    required this.chakraCost,
    required this.handSeals,
    required this.castTime,
  });

  factory JutsuConfig.fromYaml(YamlMap yaml) {
    final jutsu = yaml['jutsu'] as YamlMap;
    return JutsuConfig(
      id: readString(jutsu, 'id'),
      displayName: readString(jutsu, 'display_name'),
      chakraNature: readString(jutsu, 'chakra_nature'),
      damage: readInt(jutsu, 'damage'),
      chakraCost: readInt(jutsu, 'chakra_cost'),
      handSeals: readStringList(jutsu, 'hand_seals'),
      castTime: readDouble(jutsu, 'cast_time_seconds'),
    );
  }

  final String id;
  final String displayName;
  final String chakraNature;
  final int damage;
  final int chakraCost;
  final List<String> handSeals;
  final double castTime;
}
