import 'dart:math';
import '../../config/models/world_run_config.dart';
import '../generated_world_run.dart';

class VillagePositionSolver {
  const VillagePositionSolver();

  Point<double> findValidPosition({
    required Random random,
    required double tileSize,
    required WorldRunConfig runConfig,
    required List<GeneratedVillage> existingVillages,
    required int mapWidthTiles,
    required int mapHeightTiles,
  }) {
    final margin = runConfig.mapMarginTiles * tileSize;
    final minDistance = runConfig.minVillageDistanceTiles * tileSize;

    final minX = margin;
    final maxX = mapWidthTiles * tileSize - margin;
    final minY = margin;
    final maxY = mapHeightTiles * tileSize - margin;

    Point<double> bestCandidate = const Point(0, 0);

    for (var attempt = 0; attempt < 100; attempt++) {
      var rx = minX + random.nextDouble() * (maxX - minX);
      var ry = minY + random.nextDouble() * (maxY - minY);

      // Snap to grid
      rx = (rx / tileSize).floor() * tileSize;
      ry = (ry / tileSize).floor() * tileSize;

      bestCandidate = Point(rx, ry);

      var tooClose = false;
      for (final village in existingVillages) {
        final dx = rx - village.x;
        final dy = ry - village.y;
        final distanceSq = dx * dx + dy * dy;
        if (distanceSq < minDistance * minDistance) {
          tooClose = true;
          break;
        }
      }

      if (!tooClose) {
        return bestCandidate;
      }
    }

    return bestCandidate;
  }
}
