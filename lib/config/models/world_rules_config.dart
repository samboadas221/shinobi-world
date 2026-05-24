import 'package:yaml/yaml.dart';

import 'yaml_readers.dart';

class PassiveSimulationConfig {
  const PassiveSimulationConfig({
    required this.strengthGainIntervalMinutes,
    required this.strengthGainPercent,
    required this.casualtyIntervalMinutes,
    required this.casualtyMin,
    required this.casualtyMax,
    required this.activeRadiusTiles,
  });

  factory PassiveSimulationConfig.fromYaml(YamlMap yaml) {
    final passive = yaml['passive_simulation'] as YamlMap;
    return PassiveSimulationConfig(
      strengthGainIntervalMinutes: readInt(
        passive,
        'strength_gain_interval_minutes',
      ),
      strengthGainPercent: readDouble(passive, 'strength_gain_percent'),
      casualtyIntervalMinutes: readInt(passive, 'casualty_interval_minutes'),
      casualtyMin: readInt(passive, 'casualty_min'),
      casualtyMax: readInt(passive, 'casualty_max'),
      activeRadiusTiles: readInt(passive, 'active_radius_tiles'),
    );
  }

  final int strengthGainIntervalMinutes;
  final double strengthGainPercent;
  final int casualtyIntervalMinutes;
  final int casualtyMin;
  final int casualtyMax;
  final int activeRadiusTiles;
}


class TrainingConfig {
  const TrainingConfig({
    required this.fieldBoostPercent,
    required this.chakraPracticeCostMultiplier,
    required this.jutsuExpPerCast,
    required this.sealReductionLevelInterval,
    required this.minimumRequiredSeals,
    required this.chakraRegenPerTick,
    required this.chakraRegenIntervalSeconds,
  });

  factory TrainingConfig.fromYaml(YamlMap yaml) {
    final training = yaml['training'] as YamlMap;
    return TrainingConfig(
      fieldBoostPercent: readDouble(training, 'field_boost_percent'),
      chakraPracticeCostMultiplier: readDouble(
        training,
        'chakra_practice_cost_multiplier',
      ),
      jutsuExpPerCast: readInt(training, 'jutsu_exp_per_cast'),
      sealReductionLevelInterval: readInt(
        training,
        'seal_reduction_level_interval',
      ),
      minimumRequiredSeals: readInt(training, 'minimum_required_seals'),
      chakraRegenPerTick: readInt(training, 'chakra_regen_per_tick'),
      chakraRegenIntervalSeconds: readDouble(
        training,
        'chakra_regen_interval_seconds',
      ),
    );
  }

  final double fieldBoostPercent;
  final double chakraPracticeCostMultiplier;
  final int jutsuExpPerCast;
  final int sealReductionLevelInterval;
  final int minimumRequiredSeals;
  final int chakraRegenPerTick;
  final double chakraRegenIntervalSeconds;
}
