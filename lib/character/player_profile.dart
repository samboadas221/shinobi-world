import 'ninja_stats.dart';

class PlayerProfile {
  const PlayerProfile({
    required this.name,
    required this.gender,
    required this.naturalNature,
    required this.secondaryNature,
    required this.secondaryChakraCostMultiplier,
    required this.stats,
    required this.clothing,
    required this.clothingColorLabel,
  });

  final String name;
  final String gender;
  final String naturalNature;
  final String secondaryNature;
  final double secondaryChakraCostMultiplier;
  final NinjaStats stats;
  final Map<String, String> clothing;
  final String clothingColorLabel;

  int get totalPoints => (stats.level - 1) * 20;

  int get spentPointsSum => stats.spentPoints.values.fold(0, (sum, val) => sum + val);

  int get unspentPoints => totalPoints - spentPointsSum;

  PlayerProfile copyWith({
    String? name,
    String? gender,
    String? naturalNature,
    String? secondaryNature,
    double? secondaryChakraCostMultiplier,
    NinjaStats? stats,
    Map<String, String>? clothing,
    String? clothingColorLabel,
  }) {
    return PlayerProfile(
      name: name ?? this.name,
      gender: gender ?? this.gender,
      naturalNature: naturalNature ?? this.naturalNature,
      secondaryNature: secondaryNature ?? this.secondaryNature,
      secondaryChakraCostMultiplier: secondaryChakraCostMultiplier ?? this.secondaryChakraCostMultiplier,
      stats: stats ?? this.stats,
      clothing: clothing ?? this.clothing,
      clothingColorLabel: clothingColorLabel ?? this.clothingColorLabel,
    );
  }
}
