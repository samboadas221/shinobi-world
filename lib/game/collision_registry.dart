import '../game/world_layout/world_layout_data.dart';
import '../world/collision/aabb_rect.dart';
import '../world/collision/overworld_collision_grid.dart';

/// Builds and owns the overworld collision grid from static world layout data.
///
/// Created once per game session in ShinobiWorldGame._loadWorld().
/// The player and any other dynamic entities query this registry to
/// check for structure collisions before finalising movement.
class CollisionRegistry {
  CollisionRegistry({required double cellSize, required double structureMargin})
    : _grid = OverworldCollisionGrid(cellSize: cellSize),
      _margin = structureMargin;

  final OverworldCollisionGrid _grid;
  final double _margin;

  /// Populates the grid from all buildings in [layoutData].
  /// Call once after the world layout is ready.
  void registerLayout(WorldLayoutData layoutData) {
    for (var i = 0; i < layoutData.buildings.length; i++) {
      final b = layoutData.buildings[i];
      // Convert dart:ui.Rect to AabbRect, shrinking inward by margin.
      final rect = AabbRect(
        left: b.rect.left + _margin,
        top: b.rect.top + _margin,
        right: b.rect.right - _margin,
        bottom: b.rect.bottom - _margin,
      );
      _grid.registerStatic('building_$i', rect);
    }
  }

  /// Returns true if [mover] overlaps any registered building.
  bool collides(AabbRect mover) => _grid.wouldCollide(mover);
}
