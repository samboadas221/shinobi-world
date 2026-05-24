import 'dart:math';
import '../config/models/count_range.dart';
import '../config/models/village_population_config.dart';
import '../config/models/world_config.dart';
import '../config/models/world_run_config.dart';
import 'generated_world_run.dart';
import 'generators/village_position_solver.dart';

class WorldRunGenerator {
  WorldRunGenerator({
    required this.runConfig,
    required this.populationConfig,
    required this.mapConfig,
  });

  final WorldRunConfig runConfig;
  final VillagePopulationConfig populationConfig;
  final WorldMapConfig mapConfig;

  late final List<GeneratedVillage> allPreCalculatedVillages;

  GeneratedWorldRun generateStartingVillageOnly() {
    final seed = _roll(runConfig.seed);
    final random = Random(seed);

    final mapWidthTiles = mapConfig.mapSizeTiles.rollWidth(random);
    final mapHeightTiles = mapConfig.mapSizeTiles.rollHeight(random);

    final startingVillageName =
        runConfig.villageNamePool[random.nextInt(
          runConfig.villageNamePool.length,
        )];
    final size = _roll(runConfig.villageSize);

    final startingVillage = GeneratedVillage(
      id: 'v_start',
      name: startingVillageName,
      size: size,
      sizeLabel: populationConfig.tierForSize(size).label,
      adultPopulation: _roll(populationConfig.tierForSize(size).adultPopulation),
      x: (mapWidthTiles * mapConfig.tileSize) / 2,
      y: (mapHeightTiles * mapConfig.tileSize) / 2,
    );

    final currentVillages = <GeneratedVillage>[startingVillage];
    final totalCount = _roll(runConfig.villageCount);
    final usedNames = {startingVillageName};

    const solver = VillagePositionSolver();

    for (var i = 1; i < totalCount; i++) {
      String name;
      do {
        name =
            runConfig.villageNamePool[random.nextInt(
              runConfig.villageNamePool.length,
            )];
      } while (usedNames.contains(name) &&
          usedNames.length < runConfig.villageNamePool.length);
      usedNames.add(name);

      final size = _roll(runConfig.villageSize);
      final pos = solver.findValidPosition(
        random: random,
        tileSize: mapConfig.tileSize,
        runConfig: runConfig,
        existingVillages: currentVillages,
        mapWidthTiles: mapWidthTiles,
        mapHeightTiles: mapHeightTiles,
      );

      final village = GeneratedVillage(
        id: 'v_$i',
        name: name,
        size: size,
        sizeLabel: populationConfig.tierForSize(size).label,
        adultPopulation: _roll(
          populationConfig.tierForSize(size).adultPopulation,
        ),
        x: pos.x,
        y: pos.y,
      );

      currentVillages.add(village);
    }

    allPreCalculatedVillages = currentVillages;

    final ninjas = _createSimpleNinjas(random, startingVillage);

    return GeneratedWorldRun(
      seed: seed,
      villages: [startingVillage], // Return ONLY starting village initially
      ninjas: ninjas,
      startingVillage: startingVillage,
      rogueCount: 0,
      mapWidthTiles: mapWidthTiles,
      mapHeightTiles: mapHeightTiles,
      allVillages: currentVillages,
    );
  }

  GeneratedWorldRun generateRemaining(GeneratedWorldRun partialRun) {
    // Kept for backward compatibility / tests
    final random = Random(partialRun.seed);
    final currentVillages = List<GeneratedVillage>.from(allPreCalculatedVillages);
    final currentNinjas = List<GeneratedNinja>.from(partialRun.ninjas);

    for (final village in currentVillages) {
      if (village.id == partialRun.startingVillage.id) continue;
      currentNinjas.addAll(_createSimpleNinjas(random, village));
    }

    final rogueNinjas = generateRogueNinjas(random, currentVillages.length);
    currentNinjas.addAll(rogueNinjas);

    return GeneratedWorldRun(
      seed: partialRun.seed,
      villages: currentVillages,
      ninjas: currentNinjas,
      startingVillage: partialRun.startingVillage,
      rogueCount: rogueNinjas.length,
      mapWidthTiles: partialRun.mapWidthTiles,
      mapHeightTiles: partialRun.mapHeightTiles,
      allVillages: partialRun.allVillages,
    );
  }

  List<GeneratedNinja> generateNinjasForVillage(Random random, GeneratedVillage village) {
    return _createSimpleNinjas(random, village);
  }

  List<GeneratedNinja> generateRogueNinjas(Random random, int villageCount) {
    final list = <GeneratedNinja>[];
    final rogueCount = villageCount * _roll(runConfig.rogue.countPerVillage);
    for (var i = 0; i < rogueCount; i++) {
      list.add(
        GeneratedNinja(
          id: 'rogue_$i',
          name:
              '${_pick(random, runConfig.names.first)} '
              '${_pick(random, runConfig.names.clan)}',
          role: 'rogue_ninja',
          villageId: 'none',
          alignment: 'bad',
          bingoListed: random.nextDouble() <= runConfig.rogue.bingoListChance,
          active: false,
          stats: const {
            'health': 100,
            'chakra': 100,
            'attack': 15,
            'defense': 10,
            'speed': 10,
          },
        ),
      );
    }
    return list;
  }

  List<GeneratedNinja> _createSimpleNinjas(
    Random random,
    GeneratedVillage village,
  ) {
    final list = <GeneratedNinja>[];
    final tier = populationConfig.tierForSize(village.size);
    for (final entry in tier.roles.entries) {
      final count = _roll(entry.value);
      for (var j = 0; j < count; j++) {
        list.add(
          GeneratedNinja(
            id: '${village.id}_${entry.key}_$j',
            name:
                '${_pick(random, runConfig.names.first)} '
                '${_pick(random, runConfig.names.clan)}',
            role: entry.key,
            villageId: village.id,
            alignment: 'village',
            bingoListed: entry.key == 'bingo_list',
            active: false,
            stats: const {
              'health': 100,
              'chakra': 100,
              'attack': 15,
              'defense': 10,
              'speed': 10,
            },
          ),
        );
      }
    }
    return list;
  }

  int _roll(CountRange range) {
    if (range.max <= range.min) return range.min;
    return range.min + Random().nextInt(range.max - range.min + 1);
  }

  String _pick(Random random, List<String> values) {
    return values[random.nextInt(values.length)];
  }
}
