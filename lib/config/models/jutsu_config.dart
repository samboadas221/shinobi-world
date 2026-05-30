import 'package:yaml/yaml.dart';

import 'yaml_readers.dart';

// Effect types that a jutsu can apply in combat.
enum JutsuEffectType {
  armorBuff,
  speedBuff,
  healHp,
  healChakra,
  enemyArmorDebuff,
  enemySpeedDebuff,
}

class JutsuEffect {
  const JutsuEffect({
    required this.type,
    required this.value,
    required this.durationTurns,
  });

  factory JutsuEffect.fromYaml(YamlMap yaml) {
    final typeStr = yaml['type'] as String;
    return JutsuEffect(
      type: _parseEffectType(typeStr),
      value: (yaml['value'] as num).toDouble(),
      durationTurns: (yaml['duration_turns'] as num? ?? 0).toInt(),
    );
  }

  final JutsuEffectType type;

  /// For buffs/debuffs: the stat change amount. For heals: the HP/chakra amount.
  final double value;

  /// Turns the effect lasts. 0 = instant (no tracking needed).
  final int durationTurns;

  bool get isInstant => durationTurns == 0;
  bool get targetsSelf =>
      type == JutsuEffectType.armorBuff ||
      type == JutsuEffectType.speedBuff ||
      type == JutsuEffectType.healHp ||
      type == JutsuEffectType.healChakra;

  static JutsuEffectType _parseEffectType(String raw) {
    switch (raw) {
      case 'armor_buff':
        return JutsuEffectType.armorBuff;
      case 'speed_buff':
        return JutsuEffectType.speedBuff;
      case 'heal_hp':
        return JutsuEffectType.healHp;
      case 'heal_chakra':
        return JutsuEffectType.healChakra;
      case 'enemy_armor_debuff':
        return JutsuEffectType.enemyArmorDebuff;
      case 'enemy_speed_debuff':
        return JutsuEffectType.enemySpeedDebuff;
      default:
        throw ArgumentError('Unknown jutsu effect type: $raw');
    }
  }
}

class JutsuConfig {
  const JutsuConfig({
    required this.id,
    required this.displayName,
    required this.chakraNature,
    required this.damage,
    required this.chakraCost,
    required this.handSeals,
    required this.castTime,
    this.speed = 20,
    this.handSealSpeed = 10,
    this.chakraControl = 20,
    this.expGain = 5,
    this.nextLevelId,
    this.nextLevelExpRequired,
    this.effects = const [],
  });

  factory JutsuConfig.fromYaml(YamlMap yaml) {
    final jutsu = yaml['jutsu'] as YamlMap;
    final rawEffects = jutsu['effects'] as YamlList?;
    return JutsuConfig(
      id: readString(jutsu, 'id'),
      displayName: readString(jutsu, 'display_name'),
      chakraNature: readString(jutsu, 'chakra_nature'),
      damage: readInt(jutsu, 'damage'),
      chakraCost: readInt(jutsu, 'chakra_cost'),
      handSeals: readStringList(jutsu, 'hand_seals'),
      castTime: readDouble(jutsu, 'cast_time_seconds'),
      speed: (jutsu['speed'] as num?)?.toInt() ?? 20,
      handSealSpeed: (jutsu['hand_seal_speed'] as num?)?.toInt() ?? 10,
      chakraControl: (jutsu['chakra_control'] as num?)?.toInt() ?? 20,
      expGain: (jutsu['exp_gain'] as num?)?.toInt() ?? 5,
      nextLevelId: jutsu['next_level_id'] as String?,
      nextLevelExpRequired: (jutsu['next_level_exp_required'] as num?)?.toInt(),
      effects: rawEffects != null
          ? rawEffects.cast<YamlMap>().map(JutsuEffect.fromYaml).toList()
          : const [],
    );
  }

  final String id;
  final String displayName;
  final String chakraNature;
  final int damage;
  final int chakraCost;
  final List<String> handSeals;
  final double castTime;

  /// Jutsu projectile/travel speed (higher = faster).
  final int speed;

  /// Minimum SpeedSeal stat required to cast this jutsu.
  final int handSealSpeed;

  /// Minimum ChakraControl stat required to cast this jutsu.
  final int chakraControl;

  /// EXP awarded to the player per overworld cast.
  final int expGain;

  /// ID of the next-level version of this jutsu (null if no upgrade chain).
  final String? nextLevelId;

  /// Cumulative jutsu-specific EXP required to unlock the next level.
  final int? nextLevelExpRequired;

  /// Combat effects applied when this jutsu is used.
  final List<JutsuEffect> effects;

  bool get hasEffects => effects.isNotEmpty;
}
