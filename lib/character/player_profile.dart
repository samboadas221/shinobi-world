class PlayerProfile {
  const PlayerProfile({
    required this.name,
    required this.gender,
    required this.naturalNature,
    required this.secondaryNature,
    required this.secondaryChakraCostMultiplier,
    required this.totalPoints,
    required this.spentPoints,
    required this.clothing,
    required this.clothingColorLabel,
  });

  final String name;
  final String gender;
  final String naturalNature;
  final String secondaryNature;
  final double secondaryChakraCostMultiplier;
  final int totalPoints;
  final Map<String, int> spentPoints;
  final Map<String, String> clothing;
  final String clothingColorLabel;

  int get unspentPoints {
    return totalPoints -
        spentPoints.values.fold(0, (sum, value) => sum + value);
  }
}
