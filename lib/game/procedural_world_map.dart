import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../config/models/world_config.dart';
import '../world/generated_world_run.dart';

class ProceduralWorldMap extends PositionComponent {
  ProceduralWorldMap({required this.config, required this.run})
    : super(size: config.bounds);

  final WorldMapConfig config;
  final GeneratedWorldRun run;
  late final Paint _grassPaint = Paint()..color = config.visuals.grassColor;
  late final Paint _roadPaint = Paint()..color = config.visuals.roadColor;
  late final Paint _buildingPaint = Paint()
    ..color = config.visuals.buildingColor;

  final List<Rect> _buildings = [];
  final List<Rect> _roads = [];

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _generateLayout();
  }

  void _generateLayout() {
    final random = Random(run.seed);

    for (final village in run.villages) {
      final cx = village.x;
      final cy = village.y;

      // Generate a main road
      _roads.add(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: config.layout.roadLength,
          height: config.layout.roadWidth,
        ),
      );
      _roads.add(
        Rect.fromCenter(
          center: Offset(cx, cy),
          width: config.layout.roadWidth,
          height: config.layout.roadLength,
        ),
      );

      for (var i = 0; i < config.layout.buildingsPerVillage; i++) {
        final scatter = config.layout.buildingScatterRadius;
        final bx = cx + (random.nextDouble() * scatter * 2 - scatter);
        final by = cy + (random.nextDouble() * scatter * 2 - scatter);
        _buildings.add(
          Rect.fromLTWH(
            bx,
            by,
            config.layout.buildingSize,
            config.layout.buildingSize,
          ),
        );
      }
    }
  }

  @override
  void render(Canvas canvas) {
    // Draw base grass
    canvas.drawRect(size.toRect(), _grassPaint);

    // Draw roads
    for (final road in _roads) {
      canvas.drawRect(road, _roadPaint);
    }

    // Draw buildings
    for (final building in _buildings) {
      canvas.drawRect(building, _buildingPaint);
    }
  }
}
