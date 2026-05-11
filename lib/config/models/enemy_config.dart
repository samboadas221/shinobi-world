import 'package:flame/components.dart';
import 'package:yaml/yaml.dart';

import 'count_range.dart';
import 'visual_config.dart';
import 'yaml_readers.dart';

class EnemyConfig {
  const EnemyConfig({
    required this.id,
    required this.displayName,
    required this.expReward,
    required this.size,
    required this.visual,
    required this.stats,
    required this.movementSpeed,
    required this.jutsuCount,
    required this.usableJutsuPool,
    required this.ai,
  });

  factory EnemyConfig.fromYaml(YamlMap yaml) {
    final enemy = yaml['enemy'] as YamlMap;
    final size = enemy['size'] as YamlMap;
    return EnemyConfig(
      id: readString(enemy, 'id'),
      displayName: readString(enemy, 'display_name'),
      expReward: readInt(enemy, 'exp_reward'),
      size: Vector2(readDouble(size, 'width'), readDouble(size, 'height')),
      visual: VisualConfig.fromYaml(enemy['visual'] as YamlMap),
      stats: readIntMap(enemy, 'stats'),
      movementSpeed: readDouble(enemy, 'movement_speed'),
      jutsuCount: CountRange.fromYaml(enemy['jutsu_count'] as YamlMap),
      usableJutsuPool: readStringList(enemy, 'usable_jutsu_pool'),
      ai: EnemyAiConfig.fromYaml(enemy['ai'] as YamlMap),
    );
  }

  final String id;
  final String displayName;
  final int expReward;
  final Vector2 size;
  final VisualConfig visual;
  final Map<String, int> stats;
  final double movementSpeed;
  final CountRange jutsuCount;
  final List<String> usableJutsuPool;
  final EnemyAiConfig ai;
}

class EnemyAiConfig {
  const EnemyAiConfig({
    required this.aggression,
    required this.jutsuPreference,
    required this.retreatHealthRatio,
  });

  factory EnemyAiConfig.fromYaml(YamlMap yaml) {
    return EnemyAiConfig(
      aggression: readDouble(yaml, 'aggression'),
      jutsuPreference: readDouble(yaml, 'jutsu_preference'),
      retreatHealthRatio: readDouble(yaml, 'retreat_health_ratio'),
    );
  }

  final double aggression;
  final double jutsuPreference;
  final double retreatHealthRatio;
}
