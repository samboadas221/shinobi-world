import 'player_profile.dart';

class CharacterRoll {
  const CharacterRoll({
    required this.name,
    required this.gender,
    required this.naturalNature,
    required this.secondaryNature,
    required this.totalPoints,
    required this.spentPoints,
    required this.clothing,
    required this.clothingColorLabel,
  });

  final String name;
  final String gender;
  final String naturalNature;
  final String secondaryNature;
  final int totalPoints;
  final Map<String, int> spentPoints;
  final Map<String, String> clothing;
  final String clothingColorLabel;

  CharacterRoll copyWith({
    String? name,
    String? gender,
    Map<String, int>? spentPoints,
    Map<String, String>? clothing,
    String? clothingColorLabel,
  }) {
    return CharacterRoll(
      name: name ?? this.name,
      gender: gender ?? this.gender,
      naturalNature: naturalNature,
      secondaryNature: secondaryNature,
      totalPoints: totalPoints,
      spentPoints: spentPoints ?? this.spentPoints,
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
      totalPoints: totalPoints,
      spentPoints: spentPoints,
      clothing: clothing,
      clothingColorLabel: clothingColorLabel,
    );
  }
}
