import 'package:flame/components.dart';
import 'package:yaml/yaml.dart';

import 'count_range.dart';
import 'visual_config.dart';
import 'yaml_readers.dart';

class PlayerConfig {
  const PlayerConfig({
    required this.displayName,
    required this.movementSpeed,
    required this.size,
    required this.visual,
    required this.maxChakra,
    required this.maxHealth,
    required this.stats,
    required this.chakraNaturePool,
    required this.startingJutsuCount,
    required this.starterJutsuPool,
  });

  factory PlayerConfig.fromYaml(YamlMap yaml) {
    final player = yaml['player'] as YamlMap;
    final size = player['size'] as YamlMap;
    return PlayerConfig(
      displayName: readString(player, 'display_name'),
      movementSpeed: readDouble(player, 'movement_speed'),
      size: Vector2(readDouble(size, 'width'), readDouble(size, 'height')),
      visual: VisualConfig.fromYaml(player['visual'] as YamlMap),
      maxChakra: readInt(player, 'max_chakra'),
      maxHealth: readInt(player, 'max_health'),
      stats: PlayerStats.fromYaml(player['stats'] as YamlMap),
      chakraNaturePool: readStringList(player, 'chakra_nature_pool'),
      startingJutsuCount: CountRange.fromYaml(
        player['starting_jutsu_count'] as YamlMap,
      ),
      starterJutsuPool: readStringList(player, 'starter_jutsu_pool'),
    );
  }

  final String displayName;
  final double movementSpeed;
  final Vector2 size;
  final VisualConfig visual;
  final int maxChakra;
  final int maxHealth;
  final PlayerStats stats;
  final List<String> chakraNaturePool;
  final CountRange startingJutsuCount;
  final List<String> starterJutsuPool;
}

class PlayerStats {
  const PlayerStats({
    required this.speed,
    required this.attack,
    required this.defense,
  });

  factory PlayerStats.fromYaml(YamlMap yaml) {
    return PlayerStats(
      speed: readInt(yaml, 'speed'),
      attack: readInt(yaml, 'attack'),
      defense: readInt(yaml, 'defense'),
    );
  }

  final int speed;
  final int attack;
  final int defense;
}
