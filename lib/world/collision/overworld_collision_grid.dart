import 'aabb_rect.dart';

/// Spatial grid for fast AABB collision queries.
///
/// The map is divided into equal-sized cells. Static rects (buildings,
/// structures) are registered once. Dynamic rects (player, NPCs) are
/// updated each frame. Only cells near the queried rect are checked,
/// keeping per-frame cost O(1) regardless of map size.
///
/// Thread-safety: single-threaded Flame game loop only.
class OverworldCollisionGrid {
  OverworldCollisionGrid({required this.cellSize});

  /// Size of each grid cell in world pixels (e.g. 256).
  final double cellSize;

  /// Static rects that never move (buildings, walls).
  final Map<String, AabbRect> _statics = {};

  /// Lookup: cell key -> list of static IDs whose AABB overlaps that cell.
  final Map<String, List<String>> _staticGrid = {};

  // ── Registration ──────────────────────────────────────────────────────────

  /// Registers a static (immovable) obstacle. Call once per building.
  void registerStatic(String id, AabbRect rect) {
    _statics[id] = rect;
    for (final cell in _cellsFor(rect)) {
      _staticGrid.putIfAbsent(cell, () => []).add(id);
    }
  }

  // ── Query ──────────────────────────────────────────────────────────────────

  /// Returns true if [mover] would collide with any registered static rect.
  /// [excludeId] can skip a specific static (e.g. when testing the entity's
  /// own registered area).
  bool wouldCollide(AabbRect mover, {String? excludeId}) {
    for (final cell in _cellsFor(mover)) {
      final ids = _staticGrid[cell];
      if (ids == null) continue;
      for (final id in ids) {
        if (id == excludeId) continue;
        final rect = _statics[id]!;
        if (mover.overlaps(rect)) return true;
      }
    }
    return false;
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  Iterable<String> _cellsFor(AabbRect rect) {
    final minCol = (rect.left / cellSize).floor();
    final minRow = (rect.top / cellSize).floor();
    final maxCol = (rect.right / cellSize).floor();
    final maxRow = (rect.bottom / cellSize).floor();

    final cells = <String>[];
    for (var r = minRow; r <= maxRow; r++) {
      for (var c = minCol; c <= maxCol; c++) {
        cells.add('${c}_$r');
      }
    }
    return cells;
  }
}
