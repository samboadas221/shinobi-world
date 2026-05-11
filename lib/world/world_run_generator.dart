import 'dart:math';

import '../config/models/count_range.dart';
import '../config/models/village_population_config.dart';
import '../config/models/world_run_config.dart';
import 'generated_world_run.dart';

class WorldRunGenerator {
  const WorldRunGenerator({
    required this.runConfig,
    required this.populationConfig,
  });

  final WorldRunConfig runConfig;
  final VillagePopulationConfig populationConfig;

  GeneratedWorldRun generateStartingVillageOnly() {
    final seed = _rollWith(Random(), runConfig.seed);
    final random = Random(seed);
    final villageNames = [...runConfig.villageNamePool]..shuffle(random);
    final villageCount = _rollWith(random, runConfig.villageCount);
    final villages = <GeneratedVillage>[];
    final ninjas = <GeneratedNinja>[];

    // Pick a starting index randomly now
    final startingIndex = random.nextInt(villageCount);

    // Only generate the starting village
    final startingVillage = _createVillage(
      random,
      startingIndex,
      villageNames[startingIndex],
    );
    villages.add(startingVillage);
    ninjas.addAll(_createVillageNinjas(random, startingVillage));

    return GeneratedWorldRun(
      seed: seed,
      villages: villages,
      ninjas: ninjas,
      startingVillage: startingVillage,
      rogueCount: 0, // Will be filled in phase 2
    );
  }

  GeneratedWorldRun generateRemaining(GeneratedWorldRun partialRun) {
    final random = Random(partialRun.seed);
    final villageNames = [...runConfig.villageNamePool]..shuffle(random);
    final villageCount = _rollWith(random, runConfig.villageCount);
    final villages = <GeneratedVillage>[partialRun.startingVillage];
    final ninjas = <GeneratedNinja>[...partialRun.ninjas];

    // Identify which index was the starting village based on name
    final startingIndex = villageNames.indexOf(partialRun.startingVillage.name);

    for (var index = 0; index < villageCount; index++) {
      if (index == startingIndex) {
        continue;
      }
      final village = _createVillage(random, index, villageNames[index]);
      villages.add(village);
      ninjas.addAll(_createVillageNinjas(random, village));
    }
    final rogueNinjas = _createRogueNinjas(random, villageCount);
    ninjas.addAll(rogueNinjas);

    return GeneratedWorldRun(
      seed: partialRun.seed,
      villages: villages,
      ninjas: ninjas,
      startingVillage: partialRun.startingVillage,
      rogueCount: rogueNinjas.length,
    );
  }

  GeneratedVillage _createVillage(Random random, int index, String name) {
    final size = _rollWith(random, runConfig.villageSize);
    final tier = populationConfig.tierForSize(size);
    return GeneratedVillage(
      id: 'village_$index',
      name: name,
      size: size,
      sizeLabel: tier.label,
      adultPopulation: _rollWith(random, tier.adultPopulation),
      x: random.nextDouble() * 16000,
      y: random.nextDouble() * 16000,
    );
  }

  List<GeneratedNinja> _createVillageNinjas(
    Random random,
    GeneratedVillage village,
  ) {
    final tier = populationConfig.tierForSize(village.size);
    final ninjas = <GeneratedNinja>[];
    for (final entry in tier.roles.entries) {
      final count = _rollWith(random, entry.value);
      for (var index = 0; index < count; index++) {
        ninjas.add(
          _createNinja(
            random: random,
            id: '${village.id}_${entry.key}_$index',
            role: entry.key,
            villageId: village.id,
            alignment: 'village',
            bingoListed: entry.key == 'bingo_list',
            active: false,
          ),
        );
      }
    }
    return ninjas;
  }

  List<GeneratedNinja> _createRogueNinjas(Random random, int villageCount) {
    final count =
        villageCount * _rollWith(random, runConfig.rogue.countPerVillage);
    return List.generate(count, (index) {
      return _createNinja(
        random: random,
        id: 'rogue_$index',
        role: 'rogue_ninja',
        villageId: 'none',
        alignment: _rollAlignment(random),
        bingoListed: random.nextDouble() <= runConfig.rogue.bingoListChance,
        active: false,
      );
    });
  }

  GeneratedNinja _createNinja({
    required Random random,
    required String id,
    required String role,
    required String villageId,
    required String alignment,
    required bool bingoListed,
    required bool active,
  }) {
    return GeneratedNinja(
      id: id,
      name:
          '${_pick(random, runConfig.names.first)} '
          '${_pick(random, runConfig.names.clan)}',
      role: role,
      villageId: villageId,
      alignment: alignment,
      bingoListed: bingoListed,
      active: active,
      stats: _rollStats(random, role),
    );
  }

  Map<String, int> _rollStats(Random random, String role) {
    final statRanges = populationConfig.roleStats[role]!;
    return {
      for (final entry in statRanges.stats.entries)
        entry.key: _rollWith(random, entry.value),
    };
  }

  String _rollAlignment(Random random) {
    final roll = random.nextDouble();
    var cursor = 0.0;
    for (final entry in runConfig.rogue.alignments.entries) {
      cursor += entry.value;
      if (roll <= cursor) {
        return entry.key;
      }
    }
    return runConfig.rogue.alignments.keys.last;
  }

  String _pick(Random random, List<String> values) {
    return values[random.nextInt(values.length)];
  }

  int _rollWith(Random random, CountRange range) {
    return range.min + random.nextInt(range.max - range.min + 1);
  }
}
