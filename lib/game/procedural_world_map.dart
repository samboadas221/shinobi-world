import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../config/models/world_config.dart';
import '../world/generated_world_run.dart';
import 'world_layout/world_layout_data.dart';
import 'world_layout/render_chunk.dart';
import 'shinobi_world_game.dart';

class _ChunkIndexBounds {
  const _ChunkIndexBounds(this.minCx, this.maxCx, this.minCy, this.maxCy);
  final int minCx;
  final int maxCx;
  final int minCy;
  final int maxCy;
}

class ProceduralWorldMap extends PositionComponent with HasGameReference<ShinobiWorldGame> {
  ProceduralWorldMap({
    required this.config,
    required this.run,
    required WorldLayoutData layoutData,
  })  : _layoutData = layoutData,
        super(
          size: Vector2(
            run.mapWidthTiles * config.tileSize,
            run.mapHeightTiles * config.tileSize,
          ),
        );

  final WorldMapConfig config;
  final GeneratedWorldRun run;
  final WorldLayoutData _layoutData;

  late final double _chunkSize;
  late final int _cols;
  late final int _rows;
  late final List<List<RenderChunk>> _chunks;

  // Visual Paints
  late final Paint _grassPaint = Paint()..color = config.visuals.grassColor;
  late final Paint _dirtRoadPaint =
      Paint()..color = config.visuals.dirtRoadColor;
  late final Paint _stoneRoadPaint =
      Paint()..color = config.visuals.stoneRoadColor;
  late final Paint _trainingFieldPaint =
      Paint()..color = config.visuals.trainingFieldColor;

  // Building Type Paints
  late final Paint _housePaint = Paint()..color = const Color(0xFF8B5A2B); // Wooden brown
  late final Paint _kageOfficePaint =
      Paint()..color = const Color(0xFFB22222); // Fire red
  late final Paint _academyPaint = Paint()..color = const Color(0xFF4682B4); // Steel blue
  late final Paint _libraryPaint = Paint()..color = const Color(0xFF4B0082); // Mystical indigo
  late final Paint _centralMarketPaint = Paint()..color = const Color(0xFFD27D2D); // Plaza canvas
  late final Paint _hairStorePaint = Paint()..color = const Color(0xFFDA70D6); // Orchid pink
  late final Paint _clothStorePaint = Paint()..color = const Color(0xFF20B2AA); // Light sea green
  late final Paint _supplyStorePaint = Paint()..color = const Color(0xFFCD853F); // Peru tan
  late final Paint _armorStorePaint = Paint()..color = const Color(0xFF708090); // Slate gray
  late final Paint _weaponStorePaint = Paint()..color = const Color(0xFFC0C0C0); // Silver
  late final Paint _libraryStorePaint = Paint()..color = const Color(0xFF2E8B57); // Sea green

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    _chunkSize = 16.0 * config.tileSize;
    _cols = (size.x / _chunkSize).ceil();
    _rows = (size.y / _chunkSize).ceil();

    // 1. Initialize the grid of RenderChunks
    _chunks = List.generate(
      _rows,
      (y) => List.generate(
        _cols,
        (x) => RenderChunk(
          cx: x,
          cy: y,
          rect: Rect.fromLTWH(
            x * _chunkSize,
            y * _chunkSize,
            _chunkSize,
            _chunkSize,
          ),
        ),
      ),
    );

    // 2. Partition all layout elements into chunks they overlap
    for (final field in _layoutData.trainingFields) {
      final bounds = _getChunkBounds(field.rect);
      for (int y = bounds.minCy; y <= bounds.maxCy; y++) {
        for (int x = bounds.minCx; x <= bounds.maxCx; x++) {
          if (field.rect.overlaps(_chunks[y][x].rect)) {
            _chunks[y][x].trainingFields.add(field);
          }
        }
      }
    }

    for (final hw in _layoutData.highways) {
      final bounds = _getChunkBounds(hw.rect);
      for (int y = bounds.minCy; y <= bounds.maxCy; y++) {
        for (int x = bounds.minCx; x <= bounds.maxCx; x++) {
          if (hw.rect.overlaps(_chunks[y][x].rect)) {
            _chunks[y][x].highways.add(hw);
          }
        }
      }
    }

    for (final road in _layoutData.roads) {
      final bounds = _getChunkBounds(road.rect);
      for (int y = bounds.minCy; y <= bounds.maxCy; y++) {
        for (int x = bounds.minCx; x <= bounds.maxCx; x++) {
          if (road.rect.overlaps(_chunks[y][x].rect)) {
            _chunks[y][x].roads.add(road);
          }
        }
      }
    }

    for (final building in _layoutData.buildings) {
      final bounds = _getChunkBounds(building.rect);
      for (int y = bounds.minCy; y <= bounds.maxCy; y++) {
        for (int x = bounds.minCx; x <= bounds.maxCx; x++) {
          if (building.rect.overlaps(_chunks[y][x].rect)) {
            _chunks[y][x].buildings.add(building);
          }
        }
      }
    }
  }

  _ChunkIndexBounds _getChunkBounds(Rect rect) {
    int minCx = (rect.left / _chunkSize).floor().clamp(0, _cols - 1);
    int maxCx = (rect.right / _chunkSize).floor().clamp(0, _cols - 1);
    int minCy = (rect.top / _chunkSize).floor().clamp(0, _rows - 1);
    int maxCy = (rect.bottom / _chunkSize).floor().clamp(0, _rows - 1);
    return _ChunkIndexBounds(minCx, maxCx, minCy, maxCy);
  }

  bool isTileOccupied(int tx, int ty) {
    final px = tx * config.tileSize + config.tileSize / 2;
    final py = ty * config.tileSize + config.tileSize / 2;
    final pt = Offset(px, py);
    for (final b in _layoutData.buildings) {
      if (b.rect.contains(pt)) return true;
    }
    return false;
  }

  @override
  void render(Canvas canvas) {
    // 1. Draw the global grass backdrop
    canvas.drawRect(size.toRect(), _grassPaint);

    // Get the visible rectangle in world coordinates
    final visibleRect = game.camera.visibleWorldRect;

    // Calculate which chunks are visible
    int minCx = (visibleRect.left / _chunkSize).floor().clamp(0, _cols - 1);
    int maxCx = (visibleRect.right / _chunkSize).floor().clamp(0, _cols - 1);
    int minCy = (visibleRect.top / _chunkSize).floor().clamp(0, _rows - 1);
    int maxCy = (visibleRect.bottom / _chunkSize).floor().clamp(0, _rows - 1);

    final visibleFields = <LayoutTrainingField>{};
    final visibleHighways = <LayoutHighway>{};
    final visibleRoads = <LayoutRoad>{};
    final visibleBuildings = <LayoutBuilding>{};

    for (int y = minCy; y <= maxCy; y++) {
      for (int x = minCx; x <= maxCx; x++) {
        final chunk = _chunks[y][x];
        visibleFields.addAll(chunk.trainingFields);
        visibleHighways.addAll(chunk.highways);
        visibleRoads.addAll(chunk.roads);
        visibleBuildings.addAll(chunk.buildings);
      }
    }

    // 2. Draw Training Fields
    for (final field in visibleFields) {
      canvas.drawRect(field.rect, _trainingFieldPaint);
    }

    // 3. Draw Highways (dirt and stone)
    for (final hw in visibleHighways) {
      final paint =
          hw.material == RoadMaterial.stone ? _stoneRoadPaint : _dirtRoadPaint;
      canvas.drawRect(hw.rect, paint);
    }

    // 4. Draw Local Village Roads
    for (final road in visibleRoads) {
      final paint =
          road.material == RoadMaterial.stone
              ? _stoneRoadPaint
              : _dirtRoadPaint;
      canvas.drawRect(road.rect, paint);
    }

    // 5. Draw Buildings with unique types/colors and labels
    for (final building in visibleBuildings) {
      final paint = _paintForBuilding(building.type);
      canvas.drawRect(building.rect, paint);

      // Draw elegant roof/trim shadow detailing for premium visuals
      final borderPaint =
          Paint()
            ..color = Colors.black45
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5;
      canvas.drawRect(building.rect, borderPaint);

      // Draw Debug Label
      _drawLabel(canvas, building.rect, _labelForBuilding(building.type));
    }
  }

  void _drawLabel(Canvas canvas, Rect rect, String text) {
    final textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(color: Colors.black, blurRadius: 2, offset: Offset(1, 1)),
      ],
    );
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(minWidth: 0, maxWidth: rect.width);
    
    // Scale text if it doesn't fit
    if (textPainter.width > rect.width * 0.9) {
      final scale = (rect.width * 0.9) / textPainter.width;
      canvas.save();
      canvas.translate(
        rect.center.dx - (textPainter.width * scale) / 2,
        rect.center.dy - (textPainter.height * scale) / 2,
      );
      canvas.scale(scale, scale);
      textPainter.paint(canvas, Offset.zero);
      canvas.restore();
    } else {
      textPainter.paint(
        canvas,
        Offset(
          rect.center.dx - textPainter.width / 2,
          rect.center.dy - textPainter.height / 2,
        ),
      );
    }
  }

  Paint _paintForBuilding(BuildingType type) {
    switch (type) {
      case BuildingType.kageOffice:
        return _kageOfficePaint;
      case BuildingType.ninjaAcademy:
        return _academyPaint;
      case BuildingType.forbiddenLibrary:
        return _libraryPaint;
      case BuildingType.centralMarket:
        return _centralMarketPaint;
      case BuildingType.hairStore:
        return _hairStorePaint;
      case BuildingType.clothStore:
        return _clothStorePaint;
      case BuildingType.supplyStore:
        return _supplyStorePaint;
      case BuildingType.armorStore:
        return _armorStorePaint;
      case BuildingType.weaponStore:
        return _weaponStorePaint;
      case BuildingType.libraryStore:
        return _libraryStorePaint;
      case BuildingType.house:
        return _housePaint;
    }
  }

  String _labelForBuilding(BuildingType type) {
    switch (type) {
      case BuildingType.kageOffice: return 'K';
      case BuildingType.ninjaAcademy: return 'A';
      case BuildingType.forbiddenLibrary: return 'L';
      case BuildingType.centralMarket: return 'CM';
      case BuildingType.hairStore: return 'Sh';
      case BuildingType.clothStore: return 'Sc';
      case BuildingType.supplyStore: return 'Ssu';
      case BuildingType.armorStore: return 'Sa';
      case BuildingType.weaponStore: return 'Sw';
      case BuildingType.libraryStore: return 'Sl';
      case BuildingType.house: return 'H';
    }
  }
}
