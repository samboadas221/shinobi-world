import 'ninja_stats.dart';
import 'player_profile.dart';

class CharacterRoll {
  const CharacterRoll({
    required this.name,
    required this.gender,
    required this.naturalNature,
    required this.secondaryNature,
    required this.stats,
    required this.clothing,
    required this.clothingColorLabel,
  });

  final String name;
  final String gender;
  final String naturalNature;
  final String secondaryNature;
  final NinjaStats stats;
  final Map<String, String> clothing;
  final String clothingColorLabel;

  CharacterRoll copyWith({
    String? name,
    String? gender,
    NinjaStats? stats,
    Map<String, String>? clothing,
    String? clothingColorLabel,
  }) {
    return CharacterRoll(
      name: name ?? this.name,
      gender: gender ?? this.gender,
      naturalNature: this.naturalNature,
      secondaryNature: this.secondaryNature,
      stats: stats ?? this.stats,
      clothing: clothing ?? this.clothing,
      clothingColorLabel: clothingColorLabel ?? this.clothingColorLabel,
    );
  }

  PlayerProfile toProfile(double secondaryCostMultiplier) {
    return PlayerProfile(
      name: name,
      gender: gender,
      naturalNature: naturalNature,
      secondaryNature: secondaryNature,
      secondaryChakraCostMultiplier: secondaryCostMultiplier,
      stats: stats,
      clothing: clothing,
      clothingColorLabel: clothingColorLabel,
    );
  }
}
