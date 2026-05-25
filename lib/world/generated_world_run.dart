import '../character/ninja_stats.dart';

class GeneratedWorldRun {
  const GeneratedWorldRun({
    required this.seed,
    required this.villages,
    required this.ninjas,
    required this.startingVillage,
    required this.rogueCount,
    required this.mapWidthTiles,
    required this.mapHeightTiles,
    required this.allVillages,
  });

  final int seed;
  final List<GeneratedVillage> villages;
  final List<GeneratedNinja> ninjas;
  final GeneratedVillage startingVillage;
  final int rogueCount;
  final int mapWidthTiles;
  final int mapHeightTiles;
  final List<GeneratedVillage> allVillages;
}

class GeneratedVillage {
  const GeneratedVillage({
    required this.id,
    required this.name,
    required this.size,
    required this.sizeLabel,
    required this.adultPopulation,
    required this.x,
    required this.y,
  });

  final String id;
  final String name;
  final int size;
  final String sizeLabel;
  final int adultPopulation;
  final double x;
  final double y;
}

class GeneratedNinja {
  const GeneratedNinja({
    required this.id,
    required this.name,
    required this.role,
    required this.villageId,
    required this.alignment,
    required this.bingoListed,
    required this.active,
    required this.stats,
  });

  final String id;
  final String name;
  final String role;
  final String villageId;
  final String alignment;
  final bool bingoListed;
  final bool active;
  final NinjaStats stats;
}
