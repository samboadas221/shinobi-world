import 'dart:ui';

import 'package:flame/components.dart';

import '../config/models/world_config.dart';

class EncounterDetector {
  const EncounterDetector(this.config);

  final EncounterConfig config;

  bool overlaps(PositionComponent a, PositionComponent b) {
    if (!config.collisionStartsCombat) {
      return false;
    }
    return _boundsFor(a).overlaps(_boundsFor(b));
  }

  Rect _boundsFor(PositionComponent component) {
    final padding = config.collisionPadding;
    return Rect.fromCenter(
      center: Offset(component.position.x, component.position.y),
      width: component.size.x + padding,
      height: component.size.y + padding,
    );
  }
}
