import 'dart:math';
import '../../config/models/world_config.dart';
import '../../world/generated_world_run.dart';
import 'building_layout_generator.dart';
import 'road_network_generator.dart';
import 'world_layout_data.dart';

class WorldLayoutGenerator {
  const WorldLayoutGenerator();

  Future<WorldLayoutData> generateLayout({
    required GeneratedWorldRun run,
    required WorldMapConfig mapConfig,
  }) {
    return generateWorldLayout(run: run, mapConfig: mapConfig);
  }

  Future<WorldLayoutData> generateWorldLayout({
    required GeneratedWorldRun run,
    required WorldMapConfig mapConfig,
    void Function(String villageName, int index, int total)? onProgress,
  }) async {
    final roads = <LayoutRoad>[];
    final buildings = <LayoutBuilding>[];
    final trainingFields = <LayoutTrainingField>[];
    final highways = <LayoutHighway>[];

    const buildingGen = BuildingLayoutGenerator();
    final villageSpawnPoints = <String, Point<double>>{};
    final villageRoadsMap = <String, List<LayoutRoad>>{};

    int index = 0;
    final total = run.allVillages.length;

    // 1. Generate local village layouts for ALL precalculated villages
    for (final village in run.allVillages) {
      index++;
      if (onProgress != null) {
        onProgress(village.name, index, total);
      }
      // Yield to the Flutter engine to draw the loading bar
      await Future.delayed(const Duration(milliseconds: 10));

      final villageRandom = village.id == run.startingVillage.id
          ? Random(run.seed)
          : Random((run.seed + village.id.hashCode).abs() % 1000000000);
      final villageRoads = <LayoutRoad>[];
      
      final spawnPoint = buildingGen.generateVillageLayout(
        random: villageRandom,
        village: village,
        mapConfig: mapConfig,
        seed: run.seed,
        highways: const [],
        otherVillages: run.allVillages
            .where((v) => v.id != village.id && v.id != 'none')
            .toList(),
        outRoads: villageRoads,
        outBuildings: buildings,
        outTrainingFields: trainingFields,
      );

      roads.addAll(villageRoads);
      villageRoadsMap[village.id] = villageRoads;
      villageSpawnPoints[village.id] = spawnPoint;
    }

    // 2. Generate highways between all villages using RNG connections
    const roadGen = RoadNetworkGenerator();
    final generatedEdges = <String>{};

    for (final village in run.allVillages) {
      final connections = roadGen.getRngConnections(village, run.allVillages);

      for (final other in connections) {
        // Unique edge key to avoid generating the same highway twice
        final edgeKey = village.id.compareTo(other.id) < 0 
            ? '${village.id}_${other.id}' 
            : '${other.id}_${village.id}';
            
        if (generatedEdges.contains(edgeKey)) continue;
        generatedEdges.add(edgeKey);

        final roadsA = villageRoadsMap[village.id] ?? const [];
        final roadsB = villageRoadsMap[other.id] ?? const [];

        final highwaySegment = roadGen.generateHighwayBetween(
          villageA: village,
          villageB: other,
          roadsA: roadsA,
          roadsB: roadsB,
          buildings: buildings,
          mapConfig: mapConfig,
          isStartingA: village.id == run.startingVillage.id,
          isStartingB: other.id == run.startingVillage.id,
        );

        highways.addAll(highwaySegment);
      }
      // Yield to keep UI smooth during highway generation
      await Future.delayed(const Duration(milliseconds: 5));
    }

    final startingSpawn = villageSpawnPoints[run.startingVillage.id] ?? Point(run.startingVillage.x, run.startingVillage.y);

    return WorldLayoutData(
      roads: roads,
      highways: highways,
      buildings: buildings,
      trainingFields: trainingFields,
      playerSpawnX: startingSpawn.x,
      playerSpawnY: startingSpawn.y,
    );
  }

  WorldLayoutData generateLayoutForStartingVillage({
    required GeneratedWorldRun run,
    required WorldMapConfig mapConfig,
  }) {
    final random = Random(run.seed);
    final roads = <LayoutRoad>[];
    final buildings = <LayoutBuilding>[];
    final trainingFields = <LayoutTrainingField>[];

    const buildingGen = BuildingLayoutGenerator();
    final core = buildingGen.generateVillageLayout(
      random: random,
      village: run.startingVillage,
      mapConfig: mapConfig,
      seed: run.seed,
      highways: const [],
      otherVillages: run.villages
          .where((v) => v.id != run.startingVillage.id && v.id != 'none')
          .toList(),
      outRoads: roads,
      outBuildings: buildings,
      outTrainingFields: trainingFields,
    );

    // Generate exit roads from starting village towards neighbors (80% length)
    const roadGen = RoadNetworkGenerator();
    final highways = roadGen.generateHighwaysForVillage(
      village: run.startingVillage,
      run: run,
      mapConfig: mapConfig,
      roads: roads,
      isStartingVillage: true,
    );

    return WorldLayoutData(
      roads: roads,
      highways: highways,
      buildings: buildings,
      trainingFields: trainingFields,
      playerSpawnX: core.x,
      playerSpawnY: core.y,
    );
  }

  WorldLayoutData generateLayoutForVillage({
    required GeneratedVillage village,
    required GeneratedWorldRun run,
    required WorldMapConfig mapConfig,
  }) {
    final random = Random(run.seed + village.id.hashCode);
    final roads = <LayoutRoad>[];
    final buildings = <LayoutBuilding>[];
    final trainingFields = <LayoutTrainingField>[];

    const buildingGen = BuildingLayoutGenerator();
    final core = buildingGen.generateVillageLayout(
      random: random,
      village: village,
      mapConfig: mapConfig,
      seed: run.seed,
      highways: const [],
      otherVillages: run.villages
          .where((v) => v.id != village.id && v.id != 'none')
          .toList(),
      outRoads: roads,
      outBuildings: buildings,
      outTrainingFields: trainingFields,
    );

    // Generate exit/connector roads from this village towards neighbors (20% + vertical segment)
    const roadGen = RoadNetworkGenerator();
    final highways = roadGen.generateHighwaysForVillage(
      village: village,
      run: run,
      mapConfig: mapConfig,
      roads: roads,
      isStartingVillage: false,
    );

    return WorldLayoutData(
      roads: roads,
      highways: highways,
      buildings: buildings,
      trainingFields: trainingFields,
      playerSpawnX: core.x,
      playerSpawnY: core.y,
    );
  }
}
