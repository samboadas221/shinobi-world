import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';

import '../character/player_profile.dart';
import '../world/generated_world_run.dart';
import 'first_demo_store.dart';

class ShinobiDatabase extends GeneratedDatabase {
  ShinobiDatabase(super.executor);

  factory ShinobiDatabase.open() {
    return ShinobiDatabase(_openConnection());
  }

  @override
  Iterable<TableInfo<Table, Object?>> get allTables => const [];

  @override
  int get schemaVersion => 1;

  Future<void> prepareDemoData() async {
    await customStatement(
      'CREATE TABLE IF NOT EXISTS discovered_jutsu ('
      'id TEXT PRIMARY KEY, '
      'display_name TEXT NOT NULL, '
      'chakra_nature TEXT NOT NULL, '
      'discovered_at TEXT NOT NULL'
      ')',
    );
    await customStatement(
      'CREATE TABLE IF NOT EXISTS demo_sessions ('
      'id INTEGER PRIMARY KEY AUTOINCREMENT, '
      'village_id TEXT NOT NULL, '
      'started_at TEXT NOT NULL'
      ')',
    );
    await customStatement(
      'CREATE TABLE IF NOT EXISTS world_state ('
      'key TEXT PRIMARY KEY, '
      'value TEXT NOT NULL, '
      'updated_at TEXT NOT NULL'
      ')',
    );
    await customStatement(
      'CREATE TABLE IF NOT EXISTS player_profiles ('
      'id TEXT PRIMARY KEY, '
      'rank TEXT NOT NULL, '
      'path TEXT NOT NULL, '
      'updated_at TEXT NOT NULL'
      ')',
    );
    await FirstDemoStore(this).prepareTables();
  }

  Future<void> recordSessionVillage(String villageId) {
    return customStatement(
      'INSERT INTO demo_sessions (village_id, started_at) VALUES (?, ?)',
      [villageId, DateTime.now().toIso8601String()],
    );
  }

  Future<void> upsertDiscoveredJutsu({
    required String id,
    required String displayName,
    required String chakraNature,
  }) {
    return customStatement(
      'INSERT OR REPLACE INTO discovered_jutsu '
      '(id, display_name, chakra_nature, discovered_at) VALUES (?, ?, ?, ?)',
      [id, displayName, chakraNature, DateTime.now().toIso8601String()],
    );
  }

  Future<int> discoveredJutsuCount() async {
    final row = await customSelect(
      'SELECT COUNT(*) AS total FROM discovered_jutsu',
    ).getSingle();
    return row.read<int>('total');
  }

  Future<int> contentTableCount() async {
    final row = await customSelect(
      "SELECT COUNT(*) AS total FROM sqlite_master "
      "WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
    ).getSingle();
    return row.read<int>('total');
  }

  Future<void> storeFirstDemoRun({
    required PlayerProfile profile,
    required GeneratedWorldRun run,
  }) async {
    await FirstDemoStore(this).storeRun(profile: profile, run: run);
  }

  Future<void> storeRemainingNinjas({
    required int seed,
    required List<GeneratedVillage> villages,
    required List<GeneratedNinja> ninjas,
    required String startingVillageId,
  }) async {
    await FirstDemoStore(this).storeRemainingNinjas(
      seed: seed,
      villages: villages,
      ninjas: ninjas,
      startingVillageId: startingVillageId,
    );
  }

  Future<void> savePlayerJutsu({
    required int seed,
    required String jutsuId,
    required int level,
    required int exp,
  }) {
    return FirstDemoStore(this).savePlayerJutsu(
      seed: seed,
      jutsuId: jutsuId,
      level: level,
      exp: exp,
    );
  }

  Future<List<Map<String, dynamic>>> loadPlayerJutsus(int seed) {
    return FirstDemoStore(this).loadPlayerJutsus(seed);
  }

  Future<PlayerProfile?> loadPlayerProfile(int seed) {
    return FirstDemoStore(this).loadPlayerProfile(seed);
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/shinobi_world.sqlite');
    return NativeDatabase.createInBackground(file);
  });
}
