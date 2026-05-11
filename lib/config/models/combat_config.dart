import 'package:yaml/yaml.dart';

import 'yaml_readers.dart';

class CombatConfig {
  const CombatConfig({
    required this.turns,
    required this.reaction,
    required this.ui,
    required this.damage,
  });

  final TurnConfig turns;
  final ReactionConfig reaction;
  final CombatUiConfig ui;
  final DamageConfig damage;
}

class TurnConfig {
  const TurnConfig({
    required this.turnDuration,
    required this.speedOrderDivisor,
    required this.previewParticipants,
  });

  factory TurnConfig.fromYaml(YamlMap yaml) {
    final turns = yaml['turns'] as YamlMap;
    final participants = turns['preview_participants'] as YamlList;
    return TurnConfig(
      turnDuration: readDouble(turns, 'turn_duration_seconds'),
      speedOrderDivisor: readDouble(turns, 'speed_order_divisor'),
      previewParticipants: participants
          .cast<YamlMap>()
          .map(TurnParticipantConfig.fromYaml)
          .toList(),
    );
  }

  final double turnDuration;
  final double speedOrderDivisor;
  final List<TurnParticipantConfig> previewParticipants;
}

class TurnParticipantConfig {
  const TurnParticipantConfig({
    required this.id,
    required this.displayName,
    required this.speed,
  });

  factory TurnParticipantConfig.fromYaml(YamlMap yaml) {
    return TurnParticipantConfig(
      id: readString(yaml, 'id'),
      displayName: readString(yaml, 'display_name'),
      speed: readInt(yaml, 'speed'),
    );
  }

  final String id;
  final String displayName;
  final int speed;
}

class ReactionConfig {
  const ReactionConfig({
    required this.duration,
    required this.buttonCount,
    required this.buttonPool,
    required this.lethalThresholdRatio,
    required this.evadeTiming,
    required this.counterTiming,
  });

  factory ReactionConfig.fromYaml(YamlMap yaml) {
    final reaction = yaml['reaction_window'] as YamlMap;
    final difficulty = reaction['input_difficulty'] as YamlMap;
    final outcomes = reaction['outcomes'] as YamlMap;
    return ReactionConfig(
      duration: readDouble(reaction, 'duration_seconds'),
      buttonCount: readInt(difficulty, 'button_count'),
      buttonPool: readStringList(difficulty, 'button_pool'),
      lethalThresholdRatio: readDouble(reaction, 'lethal_threshold_ratio'),
      evadeTiming: readDouble(outcomes, 'evade_timing_seconds'),
      counterTiming: readDouble(outcomes, 'counter_timing_seconds'),
    );
  }

  final double duration;
  final int buttonCount;
  final List<String> buttonPool;
  final double lethalThresholdRatio;
  final double evadeTiming;
  final double counterTiming;
}

class CombatUiConfig {
  const CombatUiConfig({
    required this.screenTitle,
    required this.initialLog,
    required this.actions,
  });

  factory CombatUiConfig.fromYaml(YamlMap yaml) {
    final ui = yaml['combat_ui'] as YamlMap;
    final actions = ui['actions'] as YamlMap;
    return CombatUiConfig(
      screenTitle: readString(ui, 'screen_title'),
      initialLog: readString(ui, 'initial_log'),
      actions: {
        for (final entry in actions.entries)
          entry.key as String: entry.value as String,
      },
    );
  }

  final String screenTitle;
  final String initialLog;
  final Map<String, String> actions;
}

class DamageConfig {
  const DamageConfig({
    required this.basicAttackMultiplier,
    required this.defenseReductionMultiplier,
    required this.minimumDamage,
  });

  factory DamageConfig.fromYaml(YamlMap yaml) {
    final damage = yaml['damage'] as YamlMap;
    return DamageConfig(
      basicAttackMultiplier: readDouble(damage, 'basic_attack_multiplier'),
      defenseReductionMultiplier: readDouble(
        damage,
        'defense_reduction_multiplier',
      ),
      minimumDamage: readInt(damage, 'minimum_damage'),
    );
  }

  final double basicAttackMultiplier;
  final double defenseReductionMultiplier;
  final int minimumDamage;
}
