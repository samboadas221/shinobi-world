import 'dart:math';
import '../config/models/stats_scaling_config.dart';

class NinjaStats {
  const NinjaStats({
    required this.level,
    required this.scalingTiers,
    required this.spentPoints,
  });

  final int level;
  final Map<String, String> scalingTiers;
  final Map<String, int> spentPoints;

  /// Creates a new NinjaStats with all tiers randomly rolled (S, A, B, C, D, E)
  /// and points distributed or set to 0.
  factory NinjaStats.rollNew({required int level, Random? random}) {
    final r = random ?? Random();
    const possibleTiers = ['S', 'A', 'B', 'C', 'D', 'E'];
    const spendableStats = [
      'HP',
      'CP',
      'SP',
      'Speed',
      'SpeedReaction',
      'SpeedSeal',
      'ChakraControl',
      'ChakraBuffer',
      'Taijutsu'
    ];

    final scalingTiers = <String, String>{};
    for (final stat in spendableStats) {
      scalingTiers[stat] = possibleTiers[r.nextInt(possibleTiers.length)];
    }
    // LV and Armor get base/default tiers
    scalingTiers['LV'] = 'B';
    scalingTiers['Armor'] = 'B';

    final spentPoints = <String, int>{
      for (final stat in spendableStats) stat: 0,
    };

    // Auto-allocate points if level > 1
    final stats = NinjaStats(
      level: level,
      scalingTiers: scalingTiers,
      spentPoints: spentPoints,
    );

    if (level > 1) {
      return stats.autoAllocatePoints((level - 1) * 20, random: r);
    }
    return stats;
  }

  /// Automatically allocates a number of points randomly among spendable stats.
  NinjaStats autoAllocatePoints(int points, {Random? random}) {
    final r = random ?? Random();
    const spendableStats = [
      'HP',
      'CP',
      'SP',
      'Speed',
      'SpeedReaction',
      'SpeedSeal',
      'ChakraControl',
      'ChakraBuffer',
      'Taijutsu'
    ];

    final newSpent = Map<String, int>.from(spentPoints);
    for (var i = 0; i < points; i++) {
      final stat = spendableStats[r.nextInt(spendableStats.length)];
      newSpent[stat] = (newSpent[stat] ?? 0) + 1;
    }

    return NinjaStats(
      level: level,
      scalingTiers: scalingTiers,
      spentPoints: newSpent,
    );
  }

  /// Calculates a specific stat value using the [StatsScalingConfig].
  int calculate(String statKey, StatsScalingConfig config) {
    if (statKey == 'LV') return level;
    final base = config.bases[statKey] ?? 0.0;
    final maxVal = config.maxes[statKey] ?? 9999.0;
    if (statKey == 'Armor') return base.toInt();

    final points = spentPoints[statKey] ?? 0;
    final tier = scalingTiers[statKey] ?? 'B';
    final tierMultiplier = config.tiers[tier] ?? 1.0;
    final statMultiplier = config.multipliers[statKey] ?? 1.0;

    final value = base + (points * tierMultiplier * statMultiplier);
    return value.clamp(base, maxVal).toInt();
  }

  /// Serializes NinjaStats to a Map for database storage.
  Map<String, dynamic> toJson() {
    return {
      'level': level,
      'scalingTiers': scalingTiers,
      'spentPoints': spentPoints,
    };
  }

  /// Deserializes NinjaStats from a Map.
  factory NinjaStats.fromJson(Map<String, dynamic> json) {
    final level = json['level'] as int? ?? 1;
    final scalingTiers = Map<String, String>.from(json['scalingTiers'] ?? {});
    final spentPoints = Map<String, int>.from(json['spentPoints'] ?? {});
    return NinjaStats(
      level: level,
      scalingTiers: scalingTiers,
      spentPoints: spentPoints,
    );
  }
}
