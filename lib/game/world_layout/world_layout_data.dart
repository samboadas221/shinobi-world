import 'dart:ui';

enum RoadMaterial { dirt, stone }

class LayoutRoad {
  const LayoutRoad({required this.rect, required this.material});
  final Rect rect;
  final RoadMaterial material;
}

class LayoutHighway {
  const LayoutHighway({required this.rect, required this.material});
  final Rect rect;
  final RoadMaterial material;
}

enum BuildingType {
  house,
  kageOffice,
  ninjaAcademy,
  forbiddenLibrary,
  centralMarket,
  hairStore,
  clothStore,
  supplyStore,
  armorStore,
  weaponStore,
  libraryStore,
}

class LayoutBuilding {
  const LayoutBuilding({required this.rect, required this.type});
  final Rect rect;
  final BuildingType type;
}

class LayoutTrainingField {
  const LayoutTrainingField({required this.rect});
  final Rect rect;
}

class WorldLayoutData {
  const WorldLayoutData({
    required this.roads,
    required this.highways,
    required this.buildings,
    required this.trainingFields,
    required this.playerSpawnX,
    required this.playerSpawnY,
  });

  final List<LayoutRoad> roads;
  final List<LayoutHighway> highways;
  final List<LayoutBuilding> buildings;
  final List<LayoutTrainingField> trainingFields;
  final double playerSpawnX;
  final double playerSpawnY;
}
