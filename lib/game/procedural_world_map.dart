import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../config/models/world_config.dart';
import '../world/generated_world_run.dart';

class ProceduralWorldMap extends PositionComponent {
  ProceduralWorldMap({
    required this.config,
    required this.run,
  }) : super(size: config.bounds);

  final WorldMapConfig config;
  final GeneratedWorldRun run;
  final Paint _grassPaint = Paint()..color = const Color(0xFF4C8F4C);
  final Paint _roadPaint = Paint()..color = const Color(0xFF8B6C44);
  final Paint _buildingPaint = Paint()..color = const Color(0xFF555555);

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
      _roads.add(Rect.fromCenter(
        center: Offset(cx, cy),
        width: 600,
        height: 60,
      ));
      _roads.add(Rect.fromCenter(
        center: Offset(cx, cy),
        width: 60,
        height: 600,
      ));

      // Generate some buildings
      for (var i = 0; i < 10; i++) {
        final bx = cx + (random.nextDouble() * 800 - 400);
        final by = cy + (random.nextDouble() * 800 - 400);
        _buildings.add(Rect.fromLTWH(bx, by, 80, 80));
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
