import 'dart:convert';
import 'dart:math';

import 'package:flame/components.dart';

import '../character/ninja_stats.dart';
import '../config/models/world_config.dart';
import '../data/shinobi_database.dart';
import '../world/generated_world_run.dart';
import 'active_ninja_component.dart';
import 'shinobi_world_game.dart';

/// Manages the lifecycle of NPC ninjas on the overworld.
///
/// Responsibilities:
///   - At startup: queries the DB for ninjas of the starting village and
///     a small sample from other villages, building a passive pool.
///   - Every [spawnCheckInterval] seconds: spawns ninjas from the passive
///     pool that are outside the player's viewport but within range, and
///     despawns ones that wandered too far.
///   - Tracks permanently killed ninjas so they are never re-spawned.
///
/// All thresholds are driven by [NpcSpawnConfig] from map.yaml.
class NinjaSpawnerComponent extends Component
    with HasGameReference<ShinobiWorldGame> {
  NinjaSpawnerComponent({
    required this.run,
    required this.config,
    required this.database,
    required this.tileSize,
  });

  final GeneratedWorldRun run;
  final NpcSpawnConfig config;
  final ShinobiDatabase database;
  final double tileSize;

  final Random _random = Random();
  final Set<String> _killedIds = {};
  final List<Map<String, dynamic>> _passivePool = [];

  // id -> component
  final Map<String, ActiveNinjaComponent> _activeNinjas = {};

  double _checkTimer = 0;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _buildPassivePool();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _checkTimer += dt;
    if (_checkTimer < config.spawnCheckIntervalSeconds) return;
    _checkTimer = 0;
    _runSpawnDespawnCycle();
  }

  // ── Setup ─────────────────────────────────────────────────────────────────

  Future<void> _buildPassivePool() async {
    final village = run.startingVillage;
    final sizeRange = config.rangeForSize(village.sizeLabel);
    final totalTarget =
        sizeRange.min + _random.nextInt(sizeRange.max - sizeRange.min + 1);

    // Split the pool into three guaranteed buckets:
    //  • home:    friendly ninjas from the starting village
    //  • hostile: rogue ninjas (alignment=bad) from any village
    //  • neutral: ninjas from other villages (not rogues)
    final homeLimit = (totalTarget * config.homeVillageRatio).round();
    final hostileLimit = (totalTarget * config.hostileRatio).round();
    final neutralLimit = totalTarget - homeLimit - hostileLimit;

    final homeNinjas = await database.loadNinjasForVillage(
      run.seed,
      village.id,
      limit: homeLimit,
    );
    final hostileNinjas = await database.loadHostileNinjas(
      run.seed,
      limit: hostileLimit,
    );
    final neutralNinjas = await database.loadNinjasForOtherVillages(
      run.seed,
      village.id,
      limit: neutralLimit.clamp(0, 9999),
    );

    _passivePool
      ..addAll(homeNinjas)
      ..addAll(hostileNinjas)
      ..addAll(neutralNinjas);
  }

  // ── Spawn / Despawn ───────────────────────────────────────────────────────

  void _runSpawnDespawnCycle() {
    final playerPos = game.player.position;

    // Despawn ninjas that are too far away.
    final despawnPx = config.despawnBeyondTiles * tileSize;
    final toRemove = <String>[];
    for (final entry in _activeNinjas.entries) {
      final dist = (entry.value.position - playerPos).length;
      if (dist > despawnPx) {
        toRemove.add(entry.key);
        // Return to passive pool unless killed.
        final row = _findRowById(entry.key);
        if (row != null && !_killedIds.contains(entry.key)) {
          _passivePool.add(row);
        }
      }
    }
    for (final id in toRemove) {
      _activeNinjas[id]?.removeFromParent();
      _activeNinjas.remove(id);
    }

    // Spawn new ninjas from the passive pool if they're in the buffer zone.
    final bufferPx = config.spawnBufferTiles * tileSize;

    // Limit how many we process per cycle to avoid spikes.
    final candidates = _passivePool
        .where((r) => !_killedIds.contains(r['id'] as String))
        .take(10)
        .toList();

    for (final row in candidates) {
      final id = row['id'] as String;
      if (_activeNinjas.containsKey(id)) continue;

      // Pick a random spawn point around the player at the buffer distance.
      final spawnPos = _randomSpawnPoint(playerPos, bufferPx);

      // Parse stats and role from DB row
      final statsJson = row['stats'] as String? ?? '{}';
      final stats = NinjaStats.fromJson(jsonDecode(statsJson));
      final role = row['role'] as String? ?? 'genin';

      // Map database alignment + village to overworld alignment
      final dbAlignment = row['alignment'] as String? ?? 'neutral';
      final dbVillageId = row['village_id'] as String;

      String overworldAlignment = 'neutral';
      if (dbAlignment == 'bad') {
        overworldAlignment = 'hostile';
      } else if (dbAlignment == 'village') {
        if (dbVillageId == run.startingVillage.id) {
          overworldAlignment = 'friendly';
        } else {
          overworldAlignment = 'neutral';
        }
      }

      final component = ActiveNinjaComponent(
        ninjaId: id,
        ninjaName: row['name'] as String,
        villageId: row['village_id'] as String,
        alignment: overworldAlignment,
        spawnPoint: spawnPos,
        walkSpeed: config.walkSpeedPx,
        wanderRadius: config.wanderRadiusTiles * tileSize,
        stats: stats,
        role: role,
      );

      _activeNinjas[id] = component;
      _passivePool.removeWhere((r) => r['id'] == id);
      game.world.add(component);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Picks a spawn point at approximately [radius] px from [center],
  /// at a random angle.
  Vector2 _randomSpawnPoint(Vector2 center, double radius) {
    final angle = _random.nextDouble() * 2 * pi;
    final dist = radius + _random.nextDouble() * tileSize * 5;
    return center + Vector2(cos(angle) * dist, sin(angle) * dist);
  }

  Map<String, dynamic>? _findRowById(String id) {
    // Passive pool was already cleared for this id; rebuild from active entry.
    final comp = _activeNinjas[id];
    if (comp == null) return null;
    return {
      'id': comp.ninjaId,
      'name': comp.ninjaName,
      'village_id': comp.villageId,
      'alignment': comp.alignment == 'hostile' ? 'bad' : 'village',
      'stats': jsonEncode(comp.stats.toJson()),
      'role': comp.role,
    };
  }

  /// Marks a ninja as permanently killed (won't re-spawn this session).
  void markKilled(String ninjaId) {
    _killedIds.add(ninjaId);
    _passivePool.removeWhere((r) => r['id'] == ninjaId);
    _activeNinjas[ninjaId]?.removeFromParent();
    _activeNinjas.remove(ninjaId);
  }

  /// Count of currently active (visible) ninjas on the overworld.
  int get activeCount => _activeNinjas.length;
}
