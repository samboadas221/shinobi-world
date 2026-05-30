import 'dart:math';
import 'dart:ui';
import '../../config/models/world_config.dart';
import '../../world/generated_world_run.dart';
import 'world_layout_data.dart';

class RoadNetworkGenerator {
  const RoadNetworkGenerator();

  List<GeneratedVillage> getRngConnections(
    GeneratedVillage village,
    List<GeneratedVillage> allVillages,
  ) {
    return _getRngConnections(village, allVillages);
  }

  List<LayoutHighway> generateHighwayBetween({
    required GeneratedVillage villageA,
    required GeneratedVillage villageB,
    required List<LayoutRoad> roadsA,
    required List<LayoutRoad> roadsB,
    required List<LayoutBuilding> buildings,
    required WorldMapConfig mapConfig,
    required bool isStartingA,
    required bool isStartingB,
  }) {
    final highways = <LayoutHighway>[];

    // Determine consistent drawing source/target
    GeneratedVillage source = villageA;
    GeneratedVillage target = villageB;
    List<LayoutRoad> sourceRoads = roadsA;
    List<LayoutRoad> targetRoads = roadsB;

    final aIsSource =
        isStartingA || (!isStartingB && _compareIds(villageA.id, villageB.id));
    if (!aIsSource) {
      source = villageB;
      target = villageA;
      sourceRoads = roadsB;
      targetRoads = roadsA;
    }

    final dx = target.x - source.x;
    final dy = target.y - source.y;
    final isHorizontal = dx.abs() > dy.abs();

    LayoutRoad? sourceExtreme;
    LayoutRoad? targetExtreme;

    if (isHorizontal) {
      if (dx > 0) {
        sourceExtreme = _findClearExtremeRoad(
          roads: sourceRoads,
          buildings: buildings,
          getVal: (r) => r.rect.right,
          findMax: true,
          isHorizontal: isHorizontal,
          dx: dx,
          dy: dy,
          mapConfig: mapConfig,
          isSource: true,
        );
        targetExtreme = _findClearExtremeRoad(
          roads: targetRoads,
          buildings: buildings,
          getVal: (r) => r.rect.left,
          findMax: false,
          isHorizontal: isHorizontal,
          dx: dx,
          dy: dy,
          mapConfig: mapConfig,
          isSource: false,
        );
      } else {
        sourceExtreme = _findClearExtremeRoad(
          roads: sourceRoads,
          buildings: buildings,
          getVal: (r) => r.rect.left,
          findMax: false,
          isHorizontal: isHorizontal,
          dx: dx,
          dy: dy,
          mapConfig: mapConfig,
          isSource: true,
        );
        targetExtreme = _findClearExtremeRoad(
          roads: targetRoads,
          buildings: buildings,
          getVal: (r) => r.rect.right,
          findMax: true,
          isHorizontal: isHorizontal,
          dx: dx,
          dy: dy,
          mapConfig: mapConfig,
          isSource: false,
        );
      }
    } else {
      if (dy > 0) {
        sourceExtreme = _findClearExtremeRoad(
          roads: sourceRoads,
          buildings: buildings,
          getVal: (r) => r.rect.bottom,
          findMax: true,
          isHorizontal: isHorizontal,
          dx: dx,
          dy: dy,
          mapConfig: mapConfig,
          isSource: true,
        );
        targetExtreme = _findClearExtremeRoad(
          roads: targetRoads,
          buildings: buildings,
          getVal: (r) => r.rect.top,
          findMax: false,
          isHorizontal: isHorizontal,
          dx: dx,
          dy: dy,
          mapConfig: mapConfig,
          isSource: false,
        );
      } else {
        sourceExtreme = _findClearExtremeRoad(
          roads: sourceRoads,
          buildings: buildings,
          getVal: (r) => r.rect.top,
          findMax: false,
          isHorizontal: isHorizontal,
          dx: dx,
          dy: dy,
          mapConfig: mapConfig,
          isSource: true,
        );
        targetExtreme = _findClearExtremeRoad(
          roads: targetRoads,
          buildings: buildings,
          getVal: (r) => r.rect.bottom,
          findMax: true,
          isHorizontal: isHorizontal,
          dx: dx,
          dy: dy,
          mapConfig: mapConfig,
          isSource: false,
        );
      }
    }

    double sx = source.x;
    double sy = source.y;
    double tx = target.x;
    double ty = target.y;
    double rWidth = mapConfig.layout.interVillageRoadWidth;
    RoadMaterial rMaterial = RoadMaterial.dirt;

    if (sourceExtreme != null) {
      sx = sourceExtreme.rect.center.dx;
      sy = sourceExtreme.rect.center.dy;
      rWidth = isHorizontal
          ? sourceExtreme.rect.height
          : sourceExtreme.rect.width;
      rMaterial = sourceExtreme.material;
    }
    if (targetExtreme != null) {
      tx = targetExtreme.rect.center.dx;
      ty = targetExtreme.rect.center.dy;
    }

    if (isHorizontal) {
      final totalDist = tx - sx;

      // Source draws 80% horizontal segment from sx towards tx
      final length = totalDist * 0.8;
      final rx1 = min(sx, sx + length);
      final rx2 = max(sx, sx + length);
      highways.add(
        LayoutHighway(
          rect: Rect.fromLTRB(rx1, sy - rWidth / 2, rx2, sy + rWidth / 2),
          material: rMaterial,
        ),
      );

      // Target draws remaining 20% horizontal segment
      final length20 = totalDist * 0.2;
      final rx1_20 = min(tx - length20, tx);
      final rx2_20 = max(tx - length20, tx);
      highways.add(
        LayoutHighway(
          rect: Rect.fromLTRB(rx1_20, sy - rWidth / 2, rx2_20, sy + rWidth / 2),
          material: rMaterial,
        ),
      );

      // Target draws vertical segment from sy to ty at tx to align
      final ry1 = min(sy, ty);
      final ry2 = max(sy, ty);
      highways.add(
        LayoutHighway(
          rect: Rect.fromLTRB(tx - rWidth / 2, ry1, tx + rWidth / 2, ry2),
          material: rMaterial,
        ),
      );
    } else {
      final totalDist = ty - sy;

      // Source draws 80% vertical segment from sy towards ty
      final length = totalDist * 0.8;
      final ry1 = min(sy, sy + length);
      final ry2 = max(sy, sy + length);
      highways.add(
        LayoutHighway(
          rect: Rect.fromLTRB(sx - rWidth / 2, ry1, sx + rWidth / 2, ry2),
          material: rMaterial,
        ),
      );

      // Target draws remaining 20% vertical segment
      final length20 = totalDist * 0.2;
      final ry1_20 = min(ty - length20, ty);
      final ry2_20 = max(ty - length20, ty);
      highways.add(
        LayoutHighway(
          rect: Rect.fromLTRB(sx - rWidth / 2, ry1_20, sx + rWidth / 2, ry2_20),
          material: rMaterial,
        ),
      );

      // Target draws horizontal segment from sx to tx at ty to align
      final rx1 = min(sx, tx);
      final rx2 = max(sx, tx);
      highways.add(
        LayoutHighway(
          rect: Rect.fromLTRB(rx1, ty - rWidth / 2, rx2, ty + rWidth / 2),
          material: rMaterial,
        ),
      );
    }

    return highways;
  }

  List<LayoutHighway> generateHighwaysForVillage({
    required GeneratedVillage village,
    required GeneratedWorldRun run,
    required WorldMapConfig mapConfig,
    required List<LayoutRoad> roads,
    required bool isStartingVillage,
  }) {
    final highways = <LayoutHighway>[];
    final connections = _getRngConnections(village, run.villages);

    for (final other in connections) {
      // Determine drawing priority: starting village draws 80%, other draws 20% + vertical
      final draw80Percent =
          isStartingVillage ||
          (other.id != run.startingVillage.id &&
              _compareIds(village.id, other.id));

      final dx = other.x - village.x;
      final dy = other.y - village.y;
      final isHorizontal = dx.abs() > dy.abs();

      // Find the starting road tile in the village based on cardinal direction
      LayoutRoad? startRoad;
      if (isHorizontal) {
        if (dx > 0) {
          startRoad = _findExtremeRoad(roads, (r) => r.rect.right, true);
        } else {
          startRoad = _findExtremeRoad(roads, (r) => r.rect.left, false);
        }
      } else {
        if (dy > 0) {
          startRoad = _findExtremeRoad(roads, (r) => r.rect.bottom, true);
        } else {
          startRoad = _findExtremeRoad(roads, (r) => r.rect.top, false);
        }
      }

      double sx = village.x;
      double sy = village.y;
      double rWidth = mapConfig.layout.interVillageRoadWidth;
      RoadMaterial rMaterial = RoadMaterial.dirt;

      if (startRoad != null) {
        sx = startRoad.rect.center.dx;
        sy = startRoad.rect.center.dy;
        rWidth = isHorizontal ? startRoad.rect.height : startRoad.rect.width;
        rMaterial = startRoad.material;
      }

      if (isHorizontal) {
        final totalDist = other.x - sx;
        if (draw80Percent) {
          // Draw 80% horizontal road from sx towards other.x
          final length = totalDist * 0.8;
          final rx1 = min(sx, sx + length);
          final rx2 = max(sx, sx + length);
          highways.add(
            LayoutHighway(
              rect: Rect.fromLTRB(rx1, sy - rWidth / 2, rx2, sy + rWidth / 2),
              material: rMaterial,
            ),
          );
        } else {
          // Draw remaining 20% horizontal road from other's X towards sx
          final length = totalDist * 0.2;
          final rx1 = min(sx + totalDist - length, sx + totalDist);
          final rx2 = max(sx + totalDist - length, sx + totalDist);
          highways.add(
            LayoutHighway(
              rect: Rect.fromLTRB(rx1, sy - rWidth / 2, rx2, sy + rWidth / 2),
              material: rMaterial,
            ),
          );

          // Draw vertical segment from sy to other.y to connect Y alignment
          final ry1 = min(sy, other.y);
          final ry2 = max(sy, other.y);
          highways.add(
            LayoutHighway(
              rect: Rect.fromLTRB(
                other.x - rWidth / 2,
                ry1,
                other.x + rWidth / 2,
                ry2,
              ),
              material: rMaterial,
            ),
          );
        }
      } else {
        // Vertical dominant connection
        final totalDist = other.y - sy;
        if (draw80Percent) {
          // Draw 80% vertical road from sy towards other.y
          final length = totalDist * 0.8;
          final ry1 = min(sy, sy + length);
          final ry2 = max(sy, sy + length);
          highways.add(
            LayoutHighway(
              rect: Rect.fromLTRB(sx - rWidth / 2, ry1, sx + rWidth / 2, ry2),
              material: rMaterial,
            ),
          );
        } else {
          // Draw remaining 20% vertical road
          final length = totalDist * 0.2;
          final ry1 = min(sy + totalDist - length, sy + totalDist);
          final ry2 = max(sy + totalDist - length, sy + totalDist);
          highways.add(
            LayoutHighway(
              rect: Rect.fromLTRB(sx - rWidth / 2, ry1, sx + rWidth / 2, ry2),
              material: rMaterial,
            ),
          );

          // Draw horizontal segment from sx to other.x to connect X alignment
          final rx1 = min(sx, other.x);
          final rx2 = max(sx, other.x);
          highways.add(
            LayoutHighway(
              rect: Rect.fromLTRB(
                rx1,
                other.y - rWidth / 2,
                rx2,
                other.y + rWidth / 2,
              ),
              material: rMaterial,
            ),
          );
        }
      }
    }

    return highways;
  }

  List<GeneratedVillage> _getRngConnections(
    GeneratedVillage village,
    List<GeneratedVillage> allVillages,
  ) {
    final connections = <GeneratedVillage>[];
    for (final other in allVillages) {
      if (other.id == village.id || other.id == 'none') continue;
      final distSq = _distSq(village.x, village.y, other.x, other.y);
      var isEdge = true;
      for (final c in allVillages) {
        if (c.id == village.id || c.id == other.id || c.id == 'none') continue;
        final dAC = _distSq(village.x, village.y, c.x, c.y);
        final dBC = _distSq(other.x, other.y, c.x, c.y);
        if (dAC < distSq && dBC < distSq) {
          isEdge = false;
          break;
        }
      }
      if (isEdge) connections.add(other);
    }
    return connections;
  }

  bool _compareIds(String idA, String idB) {
    if (idA == 'v_start') return true;
    if (idB == 'v_start') return false;
    return idA.compareTo(idB) < 0;
  }

  LayoutRoad? _findExtremeRoad(
    List<LayoutRoad> roads,
    double Function(LayoutRoad) getVal,
    bool findMax,
  ) {
    if (roads.isEmpty) return null;
    LayoutRoad extreme = roads.first;
    double extremeVal = getVal(extreme);
    for (final r in roads) {
      final val = getVal(r);
      if (findMax ? val > extremeVal : val < extremeVal) {
        extreme = r;
        extremeVal = val;
      }
    }
    return extreme;
  }

  double _distSq(double x1, double y1, double x2, double y2) {
    final dx = x1 - x2;
    final dy = y1 - y2;
    return dx * dx + dy * dy;
  }

  LayoutRoad? _findClearExtremeRoad({
    required List<LayoutRoad> roads,
    required List<LayoutBuilding> buildings,
    required double Function(LayoutRoad) getVal,
    required bool findMax,
    required bool isHorizontal,
    required double dx,
    required double dy,
    required WorldMapConfig mapConfig,
    required bool isSource,
  }) {
    if (roads.isEmpty) return null;

    final sortedRoads = List<LayoutRoad>.from(roads);
    sortedRoads.sort((a, b) {
      final valA = getVal(a);
      final valB = getVal(b);
      return findMax ? valB.compareTo(valA) : valA.compareTo(valB);
    });

    final rWidth = mapConfig.layout.interVillageRoadWidth;

    for (final r in sortedRoads) {
      final sx = r.rect.center.dx;
      final sy = r.rect.center.dy;

      const checkLength = 2000.0;
      final directionSign = isSource
          ? (isHorizontal ? dx.sign : dy.sign)
          : (isHorizontal ? -dx.sign : -dy.sign);

      Rect pathRect;
      if (isHorizontal) {
        if (directionSign > 0) {
          pathRect = Rect.fromLTRB(
            sx,
            sy - rWidth / 2,
            sx + checkLength,
            sy + rWidth / 2,
          );
        } else {
          pathRect = Rect.fromLTRB(
            sx - checkLength,
            sy - rWidth / 2,
            sx,
            sy + rWidth / 2,
          );
        }
      } else {
        if (directionSign > 0) {
          pathRect = Rect.fromLTRB(
            sx - rWidth / 2,
            sy,
            sx + rWidth / 2,
            sy + checkLength,
          );
        } else {
          pathRect = Rect.fromLTRB(
            sx - rWidth / 2,
            sy - checkLength,
            sx + rWidth / 2,
            sy,
          );
        }
      }

      var overlaps = false;
      for (final b in buildings) {
        if (pathRect.overlaps(b.rect)) {
          overlaps = true;
          break;
        }
      }

      if (!overlaps) {
        return r;
      }
    }

    return sortedRoads.first;
  }
}
