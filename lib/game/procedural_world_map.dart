import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../config/models/world_config.dart';
import '../world/generated_world_run.dart';
import 'world_layout/world_layout_data.dart';

class ProceduralWorldMap extends PositionComponent {
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

    // 2. Draw Training Fields
    for (final field in _layoutData.trainingFields) {
      canvas.drawRect(field.rect, _trainingFieldPaint);
    }

    // 3. Draw Highways (dirt and stone)
    for (final hw in _layoutData.highways) {
      final paint =
          hw.material == RoadMaterial.stone ? _stoneRoadPaint : _dirtRoadPaint;
      canvas.drawRect(hw.rect, paint);
    }

    // 4. Draw Local Village Roads
    for (final road in _layoutData.roads) {
      final paint =
          road.material == RoadMaterial.stone
              ? _stoneRoadPaint
              : _dirtRoadPaint;
      canvas.drawRect(road.rect, paint);
    }

    // 5. Draw Buildings with unique types/colors and labels
    for (final building in _layoutData.buildings) {
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
      case BuildingType.ninjaAcademy: return 'A'; // Using A for Academy, though user only mentioned T for Training fields.
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
