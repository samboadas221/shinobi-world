import 'dart:math';
import 'dart:ui';
import '../../config/models/world_config.dart';
import '../../world/generated_world_run.dart';
import 'world_layout_data.dart';

// Grid cell type constants
const _kEmpty = 0;
const _kRoad = 1;
const _kBuilding = 2;
const _kField = 3;

// Special building type keys from YAML
const _kTypeTrainingField = 'training_field';
const _kTypeCentralMarket = 'central_market';

enum _Zone { military, commercial, residential }

/// Maps YAML type string → BuildingType enum.
/// Returns null for special types handled separately (training_field, central_market).
BuildingType? _buildingTypeFor(String type) {
  switch (type) {
    case 'kage_office':
      return BuildingType.kageOffice;
    case 'academy':
      return BuildingType.ninjaAcademy;
    case 'library':
      return BuildingType.forbiddenLibrary;
    case 'hair_store':
      return BuildingType.hairStore;
    case 'cloth_store':
      return BuildingType.clothStore;
    case 'supply_store':
      return BuildingType.supplyStore;
    case 'armor_store':
      return BuildingType.armorStore;
    case 'weapon_store':
      return BuildingType.weaponStore;
    case 'library_store':
      return BuildingType.libraryStore;
    default:
      return null; // handled as special case
  }
}

/// Road-first village layout generator.
///
/// Algorithm:
///   1. Grow spine roads (90-degree turns) from a random core point.
///   2. Grow straight branch roads off spines, enforcing minimum spacing.
///   3. Grow exit roads toward other villages (or all 4 cardinal directions).
///   4. Fix spawn tile: if the core point is surrounded by roads, make it road.
///   5. Emit all road tiles.
///   6. Assign zones by angle from core (random rotation per seed).
///   7. Place mandatory zone buildings first (fail → retry with larger grid).
///   8. Place optional zone buildings (skip gracefully if no lot available).
///   9. Fill residential lots with houses until target_houses is met.
///  10. Add highway connector roads.
///
/// All tunable values come from assets/configs/world/map.yaml → map.layout.generator.
class BuildingLayoutGenerator {
  const BuildingLayoutGenerator();

  Point<double> generateVillageLayout({
    required Random random,
    required GeneratedVillage village,
    required WorldMapConfig mapConfig,
    required int seed,
    required List<LayoutHighway> highways,
    required List<GeneratedVillage> otherVillages,
    required List<LayoutRoad> outRoads,
    required List<LayoutBuilding> outBuildings,
    required List<LayoutTrainingField> outTrainingFields,
  }) {
    final gen = mapConfig.layout.generator;
    final tier = gen.tierFor(village.size);

    final baseCols = tier.gridCols.roll(random);
    final baseRows = tier.gridRows.roll(random);

    for (var attempt = 0; attempt < 30; attempt++) {
      final cols =
          baseCols + attempt * (tier.gridExpandPerAttemptTiles * 2.5).toInt();
      final rows =
          baseRows + attempt * (tier.gridExpandPerAttemptTiles * 2.5).toInt();
      final tempRoads = <LayoutRoad>[];
      final tempBuildings = <LayoutBuilding>[];
      final tempFields = <LayoutTrainingField>[];
      final outSpawn = <Point<double>>[];

      final ok = _tryGenerate(
        random: random,
        village: village,
        mapConfig: mapConfig,
        seed: seed,
        highways: highways,
        otherVillages: otherVillages,
        cols: cols,
        rows: rows,
        outRoads: tempRoads,
        outBuildings: tempBuildings,
        outTrainingFields: tempFields,
        outSpawn: outSpawn,
      );

      if (ok) {
        outRoads.addAll(tempRoads);
        outBuildings.addAll(tempBuildings);
        outTrainingFields.addAll(tempFields);
        return outSpawn.first;
      }
    }
    return Point(village.x, village.y);
  }

  bool _tryGenerate({
    required Random random,
    required GeneratedVillage village,
    required WorldMapConfig mapConfig,
    required int seed,
    required List<LayoutHighway> highways,
    required List<GeneratedVillage> otherVillages,
    required int cols,
    required int rows,
    required List<LayoutRoad> outRoads,
    required List<LayoutBuilding> outBuildings,
    required List<LayoutTrainingField> outTrainingFields,
    required List<Point<double>> outSpawn,
  }) {
    final ts = mapConfig.tileSize;
    final layout = mapConfig.layout;
    final gen = layout.generator;
    final g = gen.global;
    final tier = gen.tierFor(village.size);

    final startX = village.x - (cols * ts) / 2;
    final startY = village.y - (rows * ts) / 2;
    final hasStone = village.size >= 4 || (seed + village.size) % 2 == 0;
    final stoneMat = hasStone ? RoadMaterial.stone : RoadMaterial.dirt;

    // [cols][rows] tile type grid + fast road lookup
    final grid = List.generate(cols, (_) => List.filled(rows, _kEmpty));
    final roadGrid = List.generate(cols, (_) => List.filled(rows, false));

    // ── 1. Random core point in the inner 50% of the grid ─────────────────
    final coreX = (cols * 0.25 + random.nextDouble() * cols * 0.5).floor();
    final coreY = (rows * 0.25 + random.nextDouble() * rows * 0.5).floor();

    // ── 2. Grow spine roads ────────────────────────────────────────────────
    final spinePoints = <_Pos>[];
    final numSpines = g.numSpines.roll(random);
    final dirs = [
      [1, 0],
      [-1, 0],
      [0, 1],
      [0, -1],
    ]..shuffle(random);

    for (var s = 0; s < numSpines && s < dirs.length; s++) {
      final d = dirs[s];
      final len = (g.spineLengthFraction.roll(random) * cols).floor();
      _growRoad(
        grid,
        roadGrid,
        random,
        coreX,
        coreY,
        d[0],
        d[1],
        len,
        cols,
        rows,
        g.spineWidthTiles,
        spinePoints,
        g,
      );
    }
    if (spinePoints.isEmpty) return false;

    // ── 3. Branch roads with minimum spacing check ─────────────────────────
    final numBranches = g.numBranchesBase + village.size * g.numBranchesPerSize;
    final branchDirs = [
      [0, 1],
      [0, -1],
      [1, 0],
      [-1, 0],
    ];
    for (var b = 0; b < numBranches; b++) {
      final origin = spinePoints[random.nextInt(spinePoints.length)];
      final dir = branchDirs[random.nextInt(4)];
      if (_hasTooCloseParallelRoad(
        roadGrid,
        origin.x,
        origin.y,
        dir[0],
        dir[1],
        g.minRoadSpacingTiles,
        cols,
        rows,
      )) {
        continue;
      }
      final len = g.branchLengthTiles.roll(random);
      _growRoad(
        grid,
        roadGrid,
        random,
        origin.x,
        origin.y,
        dir[0],
        dir[1],
        len,
        cols,
        rows,
        g.branchWidthTiles,
        null,
        g,
      );
    }

    // ── FIX 1: Spawn tile ─────────────────────────────────────────────────
    // If the village core (spawn point) is surrounded by roads on at least 3
    // cardinal sides, it looks unnatural as a lone grass tile. Mark it as road.
    if (_isSurroundedByRoads(roadGrid, coreX, coreY, cols, rows)) {
      grid[coreX][coreY] = _kRoad;
      roadGrid[coreX][coreY] = true;
    }

    // ── 5. Emit road tiles ─────────────────────────────────────────────────
    for (var x = 0; x < cols; x++) {
      for (var y = 0; y < rows; y++) {
        if (roadGrid[x][y]) {
          outRoads.add(
            LayoutRoad(
              rect: Rect.fromLTWH(startX + x * ts, startY + y * ts, ts, ts),
              material: stoneMat,
            ),
          );
        }
      }
    }

    // ── 6. Zone assignment ─────────────────────────────────────────────────
    final mRatio = layout.militaryZoneRatio;
    final cRatio = layout.commercialZoneRatio;
    final total = mRatio + cRatio + layout.residentialZoneRatio;
    final milEnd = (mRatio / total) * 2 * pi;
    final comEnd = milEnd + (cRatio / total) * 2 * pi;
    final rotation = random.nextDouble() * 2 * pi;

    // ── 7 & 8. Place buildings by zone (mandatory then optional) ──────────
    if (!_placeZone(
      tier.militaryZone,
      _Zone.military,
      grid,
      roadGrid,
      outBuildings,
      outTrainingFields,
      coreX,
      coreY,
      rotation,
      milEnd,
      comEnd,
      cols,
      rows,
      startX,
      startY,
      ts,
      random,
    )) {
      return false;
    }

    if (!_placeZone(
      tier.commercialZone,
      _Zone.commercial,
      grid,
      roadGrid,
      outBuildings,
      outTrainingFields,
      coreX,
      coreY,
      rotation,
      milEnd,
      comEnd,
      cols,
      rows,
      startX,
      startY,
      ts,
      random,
    )) {
      return false;
    }

    // ── 9. Houses ──────────────────────────────────────────────────────────
    final resLots = <_Pos>[];
    for (var x = 0; x < cols; x++) {
      for (var y = 0; y < rows; y++) {
        if (grid[x][y] != _kEmpty) continue;
        if (_tileZone(x, y, coreX, coreY, rotation, milEnd, comEnd) !=
            _Zone.residential) {
          continue;
        }
        if (_hasRoadNeighbor(roadGrid, x, y, 1, 1, cols, rows)) {
          resLots.add(_Pos(x, y));
        }
      }
    }
    resLots.shuffle(random);

    final targetHouseCount = tier.residentialZone.targetHouses.roll(random);
    int housesPlaced = 0;
    for (final lot in resLots) {
      if (housesPlaced >= targetHouseCount) break;
      final hw = tier.residentialZone.houseTiles.rollWidth(random);
      final hh = tier.residentialZone.houseTiles.rollHeight(random);
      if (!_isAreaEmpty(grid, lot.x, lot.y, hw, hh, cols, rows)) continue;
      _occupy(grid, roadGrid, lot.x, lot.y, hw, hh, _kBuilding);
      outBuildings.add(
        LayoutBuilding(
          rect: Rect.fromLTWH(
            startX + lot.x * ts,
            startY + lot.y * ts,
            hw * ts,
            hh * ts,
          ),
          type: BuildingType.house,
        ),
      );
      housesPlaced++;
    }

    if (housesPlaced < targetHouseCount &&
        housesPlaced < tier.residentialZone.targetHouses.min) {
      return false;
    }

    // Capture spawn point absolute coordinates
    final px = startX + coreX * ts + ts / 2;
    final py = startY + coreY * ts + ts / 2;
    outSpawn.add(Point(px, py));

    return true;
  }

  // ── Zone placement ────────────────────────────────────────────────────────

  /// Places all buildings defined by [zoneConfig] into [zone].
  /// Mandatory entries: must all be placed or returns false (triggers retry).
  /// Optional entries: tried in order, silently skipped if no lot is found.
  /// Returns true iff all mandatory buildings were successfully placed.
  bool _placeZone(
    ZoneConfig zoneConfig,
    _Zone zone,
    List<List<int>> grid,
    List<List<bool>> roadGrid,
    List<LayoutBuilding> outBuildings,
    List<LayoutTrainingField> outTrainingFields,
    int coreX,
    int coreY,
    double rotation,
    double milEnd,
    double comEnd,
    int cols,
    int rows,
    double startX,
    double startY,
    double ts,
    Random random,
  ) {
    // Mandatory: fail generation if any can't be placed
    for (final entry in zoneConfig.mandatory) {
      for (var i = 0; i < entry.count; i++) {
        final ok = _placeEntry(
          entry: entry,
          mandatory: true,
          zone: zone,
          grid: grid,
          roadGrid: roadGrid,
          outBuildings: outBuildings,
          outTrainingFields: outTrainingFields,
          coreX: coreX,
          coreY: coreY,
          rotation: rotation,
          milEnd: milEnd,
          comEnd: comEnd,
          cols: cols,
          rows: rows,
          startX: startX,
          startY: startY,
          ts: ts,
          random: random,
        );
        if (!ok) return false;
      }
    }

    // Optional: try but never fail
    for (final entry in zoneConfig.optional) {
      for (var i = 0; i < entry.count; i++) {
        _placeEntry(
          entry: entry,
          mandatory: false,
          zone: zone,
          grid: grid,
          roadGrid: roadGrid,
          outBuildings: outBuildings,
          outTrainingFields: outTrainingFields,
          coreX: coreX,
          coreY: coreY,
          rotation: rotation,
          milEnd: milEnd,
          comEnd: comEnd,
          cols: cols,
          rows: rows,
          startX: startX,
          startY: startY,
          ts: ts,
          random: random,
        );
      }
    }

    return true;
  }

  /// Places a single building entry. Returns false only when [mandatory] is
  /// true and no suitable lot exists (signals the caller to retry).
  bool _placeEntry({
    required ZoneBuildingEntry entry,
    required bool mandatory,
    required _Zone zone,
    required List<List<int>> grid,
    required List<List<bool>> roadGrid,
    required List<LayoutBuilding> outBuildings,
    required List<LayoutTrainingField> outTrainingFields,
    required int coreX,
    required int coreY,
    required double rotation,
    required double milEnd,
    required double comEnd,
    required int cols,
    required int rows,
    required double startX,
    required double startY,
    required double ts,
    required Random random,
  }) {
    final w = entry.tiles.rollWidth(random);
    final h = entry.tiles.rollHeight(random);

    // Training field → LayoutTrainingField (special type)
    if (entry.type == _kTypeTrainingField) {
      final pos = _findLot(
        grid,
        roadGrid,
        w,
        h,
        zone,
        coreX,
        coreY,
        rotation,
        milEnd,
        comEnd,
        cols,
        rows,
        random,
      );
      if (pos == null) return !mandatory; // optional: ok; mandatory: fail
      _occupy(grid, roadGrid, pos.x, pos.y, w, h, _kField);
      outTrainingFields.add(
        LayoutTrainingField(
          rect: Rect.fromLTWH(
            startX + pos.x * ts,
            startY + pos.y * ts,
            w * ts,
            h * ts,
          ),
        ),
      );
      return true;
    }

    // Central market → fills plaza area with stall clusters
    if (entry.type == _kTypeCentralMarket) {
      final pos = _findLot(
        grid,
        roadGrid,
        w,
        h,
        zone,
        coreX,
        coreY,
        rotation,
        milEnd,
        comEnd,
        cols,
        rows,
        random,
      );
      if (pos == null) return !mandatory;
      _occupy(grid, roadGrid, pos.x, pos.y, w, h, _kRoad);
      for (var sx = pos.x + 1; sx < pos.x + w - 1; sx += 3) {
        for (var sy = pos.y + 1; sy < pos.y + h - 1; sy += 3) {
          if (sx + 1 < cols && sy + 1 < rows) {
            outBuildings.add(
              LayoutBuilding(
                rect: Rect.fromLTWH(
                  startX + sx * ts,
                  startY + sy * ts,
                  2 * ts,
                  2 * ts,
                ),
                type: BuildingType.centralMarket,
              ),
            );
          }
        }
      }
      return true;
    }

    // Standard building → LayoutBuilding
    final type = _buildingTypeFor(entry.type);
    if (type == null) return true; // unknown type — silently skip

    final pos = _findLot(
      grid,
      roadGrid,
      w,
      h,
      zone,
      coreX,
      coreY,
      rotation,
      milEnd,
      comEnd,
      cols,
      rows,
      random,
    );
    if (pos == null) return !mandatory;
    _occupy(grid, roadGrid, pos.x, pos.y, w, h, _kBuilding);
    outBuildings.add(
      LayoutBuilding(
        rect: Rect.fromLTWH(
          startX + pos.x * ts,
          startY + pos.y * ts,
          w * ts,
          h * ts,
        ),
        type: type,
      ),
    );
    return true;
  }

  // ── Road growth ──────────────────────────────────────────────────────────

  void _growRoad(
    List<List<int>> grid,
    List<List<bool>> roadGrid,
    Random random,
    int sx,
    int sy,
    int dx,
    int dy,
    int length,
    int cols,
    int rows,
    int width,
    List<_Pos>? trackPoints,
    VillageGeneratorGlobalConfig g,
  ) {
    int x = sx, y = sy;
    int curDx = dx, curDy = dy;
    int stepsUntilTurn = g.straightRunTiles.roll(random);
    int stepsSince = 0;

    for (var i = 0; i < length; i++) {
      if (width > 1 && stepsSince >= stepsUntilTurn) {
        if (curDx != 0) {
          curDy = random.nextBool() ? 1 : -1;
          curDx = 0;
        } else {
          curDx = random.nextBool() ? 1 : -1;
          curDy = 0;
        }
        stepsSince = 0;
        stepsUntilTurn = g.straightRunTiles.roll(random);
      }

      x = (x + curDx).clamp(2, cols - 3);
      y = (y + curDy).clamp(2, rows - 3);

      for (var w = 0; w < width; w++) {
        final rx = (curDx == 0) ? (x + w).clamp(0, cols - 1) : x;
        final ry = (curDy == 0) ? (y + w).clamp(0, rows - 1) : y;
        if (grid[rx][ry] != _kBuilding && grid[rx][ry] != _kField) {
          grid[rx][ry] = _kRoad;
          roadGrid[rx][ry] = true;
        }
      }
      trackPoints?.add(_Pos(x, y));
      stepsSince++;
    }
  }

  bool _hasTooCloseParallelRoad(
    List<List<bool>> roadGrid,
    int sx,
    int sy,
    int branchDx,
    int branchDy,
    int minSpacing,
    int cols,
    int rows,
  ) {
    final perpX = branchDy.abs();
    final perpY = branchDx.abs();
    for (var d = 1; d <= minSpacing; d++) {
      for (final sign in [-1, 1]) {
        final nx = (sx + perpX * d * sign).clamp(0, cols - 1);
        final ny = (sy + perpY * d * sign).clamp(0, rows - 1);
        if (roadGrid[nx][ny]) return true;
      }
    }
    return false;
  }

  // ── Spawn tile helper ─────────────────────────────────────────────────────

  /// Returns true if at least 3 of the 4 cardinal neighbors of (x, y) are roads.
  /// Used to decide whether the village spawn/core tile should be paved over.
  bool _isSurroundedByRoads(
    List<List<bool>> roadGrid,
    int x,
    int y,
    int cols,
    int rows,
  ) {
    int count = 0;
    for (final d in [
      [x - 1, y],
      [x + 1, y],
      [x, y - 1],
      [x, y + 1],
    ]) {
      if (d[0] >= 0 &&
          d[0] < cols &&
          d[1] >= 0 &&
          d[1] < rows &&
          roadGrid[d[0]][d[1]]) {
        count++;
      }
    }
    return count >= 3;
  }

  // ── Building lot helpers ──────────────────────────────────────────────────

  _Pos? _findLot(
    List<List<int>> grid,
    List<List<bool>> roadGrid,
    int w,
    int h,
    _Zone targetZone,
    int coreX,
    int coreY,
    double rotation,
    double milEnd,
    double comEnd,
    int cols,
    int rows,
    Random random,
  ) {
    final candidates = <_Pos>[];
    for (var x = 0; x <= cols - w; x++) {
      for (var y = 0; y <= rows - h; y++) {
        final zone = _tileZone(
          x + w ~/ 2,
          y + h ~/ 2,
          coreX,
          coreY,
          rotation,
          milEnd,
          comEnd,
        );
        if (zone != targetZone) continue;
        if (!_isAreaEmpty(grid, x, y, w, h, cols, rows)) continue;
        if (!_hasRoadNeighbor(roadGrid, x, y, w, h, cols, rows)) continue;
        candidates.add(_Pos(x, y));
      }
    }
    if (candidates.isEmpty) return null;
    return candidates[random.nextInt(candidates.length)];
  }

  _Zone _tileZone(
    int tx,
    int ty,
    int coreX,
    int coreY,
    double rotation,
    double milEnd,
    double comEnd,
  ) {
    final dx = tx - coreX;
    final dy = ty - coreY;
    if (dx == 0 && dy == 0) return _Zone.residential;
    var angle = atan2(dy.toDouble(), dx.toDouble()) - rotation;
    while (angle < 0) {
      angle += 2 * pi;
    }
    while (angle >= 2 * pi) {
      angle -= 2 * pi;
    }
    if (angle < milEnd) return _Zone.military;
    if (angle < comEnd) return _Zone.commercial;
    return _Zone.residential;
  }

  bool _isAreaEmpty(
    List<List<int>> grid,
    int x,
    int y,
    int w,
    int h,
    int cols,
    int rows,
  ) {
    if (x < 0 || y < 0 || x + w > cols || y + h > rows) return false;
    for (var i = 0; i < w; i++) {
      for (var j = 0; j < h; j++) {
        if (grid[x + i][y + j] != _kEmpty) return false;
      }
    }
    return true;
  }

  bool _hasRoadNeighbor(
    List<List<bool>> roadGrid,
    int x,
    int y,
    int w,
    int h,
    int cols,
    int rows,
  ) {
    for (var i = -1; i <= w; i++) {
      for (var j = -1; j <= h; j++) {
        if (i >= 0 && i < w && j >= 0 && j < h) continue;
        final nx = x + i;
        final ny = y + j;
        if (nx >= 0 && nx < cols && ny >= 0 && ny < rows && roadGrid[nx][ny]) {
          return true;
        }
      }
    }
    return false;
  }

  void _occupy(
    List<List<int>> grid,
    List<List<bool>> roadGrid,
    int x,
    int y,
    int w,
    int h,
    int type,
  ) {
    for (var i = 0; i < w; i++) {
      for (var j = 0; j < h; j++) {
        if (x + i < grid.length && y + j < grid[0].length) {
          grid[x + i][y + j] = type;
          if (type == _kBuilding || type == _kField) {
            roadGrid[x + i][y + j] = false;
          }
        }
      }
    }
  }
}

class _Pos {
  const _Pos(this.x, this.y);
  final int x;
  final int y;
}
