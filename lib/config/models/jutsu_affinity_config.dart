import 'package:yaml/yaml.dart';

import 'yaml_readers.dart';

/// Holds elemental affinity damage/cost multipliers and the
/// bidirectional map of opposite elements.
class JutsuAffinityConfig {
  const JutsuAffinityConfig({
    required this.primaryMultiplier,
    required this.secondaryMultiplier,
    required this.neutralMultiplier,
    required this.oppositePrimaryMultiplier,
    required this.oppositeSecondaryMultiplier,
    required this.opposites,
  });

  factory JutsuAffinityConfig.fromYaml(YamlMap yaml) {
    final root = yaml['jutsu_affinities'] as YamlMap;
    final rawOpposites = root['opposites'] as YamlMap;
    return JutsuAffinityConfig(
      primaryMultiplier: readDouble(root, 'primary_multiplier'),
      secondaryMultiplier: readDouble(root, 'secondary_multiplier'),
      neutralMultiplier: readDouble(root, 'neutral_multiplier'),
      oppositePrimaryMultiplier: readDouble(
        root,
        'opposite_primary_multiplier',
      ),
      oppositeSecondaryMultiplier: readDouble(
        root,
        'opposite_secondary_multiplier',
      ),
      opposites: {
        for (final e in rawOpposites.entries)
          e.key as String: e.value as String,
      },
    );
  }

  final double primaryMultiplier;
  final double secondaryMultiplier;
  final double neutralMultiplier;
  final double oppositePrimaryMultiplier;
  final double oppositeSecondaryMultiplier;

  /// Maps each element to its opposite. 'none' means no opposite.
  final Map<String, String> opposites;

  /// Returns the damage multiplier for a caster with the given natures
  /// using a jutsu of [jutsuNature].
  double multiplierFor({
    required String jutsuNature,
    required String casterPrimary,
    required String casterSecondary,
  }) {
    if (jutsuNature == casterPrimary) return primaryMultiplier;
    if (jutsuNature == casterSecondary) return secondaryMultiplier;

    final oppositePrimary = opposites[casterPrimary];
    if (oppositePrimary != null &&
        oppositePrimary != 'none' &&
        jutsuNature == oppositePrimary) {
      return oppositePrimaryMultiplier;
    }

    final oppositeSecondary = opposites[casterSecondary];
    if (oppositeSecondary != null &&
        oppositeSecondary != 'none' &&
        jutsuNature == oppositeSecondary) {
      return oppositeSecondaryMultiplier;
    }

    return neutralMultiplier;
  }
}
