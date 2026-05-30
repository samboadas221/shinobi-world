import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../character/ninja_stats.dart';

/// A live NPC ninja rendered on the overworld.
///
/// Wanders randomly within [wanderRadius] pixels of its [spawnPoint].
/// The game loop (NinjaSpawnerComponent) decides when to despawn this actor.
class ActiveNinjaComponent extends PositionComponent {
  ActiveNinjaComponent({
    required this.ninjaId,
    required this.ninjaName,
    required this.villageId,
    required this.alignment,
    required Vector2 spawnPoint,
    required this.walkSpeed,
    required this.wanderRadius,
    required this.stats,
    required this.role,
  }) : super(
         position: spawnPoint.clone(),
         size: Vector2(10, 10),
         anchor: Anchor.center,
       );

  final String ninjaId;
  final String ninjaName;
  final String villageId;

  /// 'friendly', 'neutral', or 'hostile'
  final String alignment;
  final double walkSpeed;
  final double wanderRadius;
  final NinjaStats stats;
  final String role;

  static final _random = Random();

  // ── Wander state ──────────────────────────────────────────────────────────
  Vector2 _target = Vector2.zero();
  double _wanderTimer = 0;
  static const _wanderInterval = 2.5;

  // ── Visuals ───────────────────────────────────────────────────────────────
  late final Paint _bodyPaint;
  late final Paint _headbandPaint;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _bodyPaint = Paint()..color = _bodyColorFor(alignment);
    _headbandPaint = Paint()..color = _headbandColorFor(alignment);
    _pickNewTarget();
  }

  @override
  void update(double dt) {
    super.update(dt);

    // Wander: pick a new direction every few seconds.
    _wanderTimer -= dt;
    if (_wanderTimer <= 0) {
      _pickNewTarget();
    }

    // Move towards current target.
    final delta = _target - position;
    if (delta.length > 2.0) {
      position += delta.normalized() * walkSpeed * dt;
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(2)),
      _bodyPaint,
    );
    // Headband strip
    canvas.drawRect(Rect.fromLTWH(1, 1.5, size.x - 2, 2), _headbandPaint);
  }

  void _pickNewTarget() {
    _wanderTimer = _wanderInterval + _random.nextDouble() * 1.5;
    final angle = _random.nextDouble() * 2 * pi;
    final dist = _random.nextDouble() * wanderRadius;
    _target = position + Vector2(cos(angle) * dist, sin(angle) * dist);
  }

  static Color _bodyColorFor(String alignment) {
    switch (alignment) {
      case 'hostile':
        return const Color(0xFFB03030);
      case 'friendly':
        return const Color(0xFF3080B0);
      default:
        return const Color(0xFF606060);
    }
  }

  static Color _headbandColorFor(String alignment) {
    switch (alignment) {
      case 'hostile':
        return const Color(0xFF600000);
      case 'friendly':
        return const Color(0xFF104060);
      default:
        return const Color(0xFF303030);
    }
  }
}
