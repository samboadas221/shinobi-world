import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../config/models/enemy_config.dart';
import '../config/models/jutsu_config.dart';

class EnemyComponent extends PositionComponent {
  EnemyComponent({
    required this.config,
    required this.knownJutsu,
    required Vector2 spawnPosition,
  }) : super(position: spawnPosition, size: config.size, anchor: Anchor.center);

  final EnemyConfig config;
  final List<JutsuConfig> knownJutsu;
  late final Paint _bodyPaint = Paint()..color = config.visual.bodyColor;
  late final Paint _headbandPaint = Paint()
    ..color = config.visual.headbandColor;

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(3)),
      _bodyPaint,
    );
    canvas.drawRect(Rect.fromLTWH(1, 2, size.x - 2, 3), _headbandPaint);
  }
}
