import 'dart:convert';

import 'package:drift/drift.dart';

import '../character/player_profile.dart';
import '../world/generated_world_run.dart';

class FirstDemoStore {
  const FirstDemoStore(this._database);

  final GeneratedDatabase _database;

  Future<void> prepareTables() async {
    await _database.customStatement(
      'CREATE TABLE IF NOT EXISTS first_demo_runs ('
      'seed INTEGER PRIMARY KEY, '
      'starting_village_id TEXT NOT NULL, '
      'village_count INTEGER NOT NULL, '
      'ninja_count INTEGER NOT NULL, '
      'rogue_count INTEGER NOT NULL, '
      'created_at TEXT NOT NULL'
      ')',
    );
    await _database.customStatement(
      'CREATE TABLE IF NOT EXISTS first_demo_villages ('
      'run_seed INTEGER NOT NULL, '
      'id TEXT NOT NULL, '
      'name TEXT NOT NULL, '
      'size INTEGER NOT NULL, '
      'size_label TEXT NOT NULL, '
      'adult_population INTEGER NOT NULL, '
      'x REAL NOT NULL DEFAULT 0.0, '
      'y REAL NOT NULL DEFAULT 0.0, '
      'PRIMARY KEY (run_seed, id)'
      ')',
    );
    await _prepareNinjaTable();
    await _database.customStatement(
      'CREATE TABLE IF NOT EXISTS first_demo_player_profiles ('
      'run_seed INTEGER PRIMARY KEY, '
      'name TEXT NOT NULL, '
      'gender TEXT NOT NULL, '
      'natural_nature TEXT NOT NULL, '
      'secondary_nature TEXT NOT NULL, '
      'secondary_cost_multiplier REAL NOT NULL, '
      'total_points INTEGER NOT NULL, '
      'spent_points TEXT NOT NULL, '
      'clothing TEXT NOT NULL, '
      'clothing_color_label TEXT NOT NULL, '
      'created_at TEXT NOT NULL'
      ')',
    );
  }

  Future<void> storeRun({
    required PlayerProfile profile,
    required GeneratedWorldRun run,
  }) async {
    await _deleteRun(run.seed);
    await _insertPlayerProfile(profile, run.seed);
    await _insertRun(run);
    for (final village in run.villages) {
      await _insertVillage(run.seed, village);
    }
    for (final ninja in run.ninjas) {
      await _insertNinja(run.seed, ninja);
    }
  }

  Future<void> storeRemainingNinjas({
    required int seed,
    required List<GeneratedVillage> villages,
    required List<GeneratedNinja> ninjas,
    required String startingVillageId,
  }) async {
    // Update the run record counts
    await _database.customStatement(
      'UPDATE first_demo_runs SET village_count = ?, ninja_count = ? WHERE seed = ?',
      [villages.length, ninjas.length, seed],
    );

    // Insert only the new ones
    for (final village in villages) {
      if (village.id != startingVillageId) {
        await _insertVillage(seed, village);
      }
    }
    for (final ninja in ninjas) {
      if (ninja.villageId != startingVillageId) {
        await _insertNinja(seed, ninja);
      }
    }
  }

  Future<void> _prepareNinjaTable() async {
    await _database.customStatement(
      'CREATE TABLE IF NOT EXISTS first_demo_ninjas ('
      'run_seed INTEGER NOT NULL, '
      'id TEXT NOT NULL, '
      'name TEXT NOT NULL, '
      'role TEXT NOT NULL, '
      'village_id TEXT NOT NULL, '
      'alignment TEXT NOT NULL, '
      'bingo_listed INTEGER NOT NULL, '
      'active INTEGER NOT NULL, '
      "stats TEXT NOT NULL DEFAULT '{}', "
      'PRIMARY KEY (run_seed, id)'
      ')',
    );
    await _tryAddNinjaStatsColumn();
    await _tryAddVillageLocationColumns();
  }

  Future<void> _deleteRun(int seed) async {
    await _database.customStatement(
      'DELETE FROM first_demo_ninjas WHERE run_seed = ?',
      [seed],
    );
    await _database.customStatement(
      'DELETE FROM first_demo_villages WHERE run_seed = ?',
      [seed],
    );
    await _database.customStatement(
      'DELETE FROM first_demo_player_profiles WHERE run_seed = ?',
      [seed],
    );
    await _database.customStatement(
      'DELETE FROM first_demo_runs WHERE seed = ?',
      [seed],
    );
  }

  Future<void> _insertPlayerProfile(PlayerProfile profile, int seed) {
    return _database.customStatement(
      'INSERT INTO first_demo_player_profiles VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        seed,
        profile.name,
        profile.gender,
        profile.naturalNature,
        profile.secondaryNature,
        profile.secondaryChakraCostMultiplier,
        profile.totalPoints,
        jsonEncode(profile.spentPoints),
        jsonEncode(profile.clothing),
        profile.clothingColorLabel,
        DateTime.now().toIso8601String(),
      ],
    );
  }

  Future<void> _insertRun(GeneratedWorldRun run) {
    return _database.customStatement(
      'INSERT INTO first_demo_runs VALUES (?, ?, ?, ?, ?, ?)',
      [
        run.seed,
        run.startingVillage.id,
        run.villages.length,
        run.ninjas.length,
        run.rogueCount,
        DateTime.now().toIso8601String(),
      ],
    );
  }

  Future<void> _insertVillage(int seed, GeneratedVillage village) {
    return _database.customStatement(
      'INSERT INTO first_demo_villages VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
      [
        seed,
        village.id,
        village.name,
        village.size,
        village.sizeLabel,
        village.adultPopulation,
        village.x,
        village.y,
      ],
    );
  }

  Future<void> _insertNinja(int seed, GeneratedNinja ninja) {
    return _database.customStatement(
      'INSERT INTO first_demo_ninjas VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      [
        seed,
        ninja.id,
        ninja.name,
        ninja.role,
        ninja.villageId,
        ninja.alignment,
        ninja.bingoListed ? 1 : 0,
        ninja.active ? 1 : 0,
        jsonEncode(ninja.stats),
      ],
    );
  }

  Future<void> _tryAddNinjaStatsColumn() async {
    try {
      await _database.customStatement(
        'ALTER TABLE first_demo_ninjas '
        "ADD COLUMN stats TEXT NOT NULL DEFAULT '{}'",
      );
    } catch (_) {
      return;
    }
  }

  Future<void> _tryAddVillageLocationColumns() async {
    try {
      await _database.customStatement(
        'ALTER TABLE first_demo_villages '
        'ADD COLUMN x REAL NOT NULL DEFAULT 0.0',
      );
      await _database.customStatement(
        'ALTER TABLE first_demo_villages '
        'ADD COLUMN y REAL NOT NULL DEFAULT 0.0',
      );
    } catch (_) {
      // Columns might already exist
    }
  }
}
