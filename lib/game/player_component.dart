import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/models/player_config.dart';
import 'shinobi_world_game.dart';

class PlayerComponent extends PositionComponent
    with KeyboardHandler, HasGameReference<ShinobiWorldGame> {
  PlayerComponent({
    required PlayerConfig config,
    required Vector2 spawnPosition,
  }) : _config = config,
       super(position: spawnPosition, size: config.size, anchor: Anchor.center);

  final PlayerConfig _config;
  final _pressedKeys = <LogicalKeyboardKey>{};
  late final Paint _bodyPaint = Paint()..color = _config.visual.bodyColor;
  late final Paint _headbandPaint = Paint()
    ..color = _config.visual.headbandColor;

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    _pressedKeys
      ..clear()
      ..addAll(keysPressed);
    return true;
  }

  void resetMovement() {
    _pressedKeys.clear();
  }

  @override
  void update(double dt) {
    super.update(dt);
    final direction = _movementDirection();
    if (direction.isZero()) {
      return;
    }
    position += direction.normalized() * _config.movementSpeed * dt;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(3)),
      _bodyPaint,
    );
    canvas.drawRect(Rect.fromLTWH(1, 2, size.x - 2, 3), _headbandPaint);
  }

  Vector2 _movementDirection() {
    var direction = Vector2.zero();
    if (_pressedKeys.contains(LogicalKeyboardKey.keyA) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowLeft)) {
      direction.x -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyD) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowRight)) {
      direction.x += 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyW) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowUp)) {
      direction.y -= 1;
    }
    if (_pressedKeys.contains(LogicalKeyboardKey.keyS) ||
        _pressedKeys.contains(LogicalKeyboardKey.arrowDown)) {
      direction.y += 1;
    }

    // Include joystick movement if keyboard is not active
    if (direction.isZero() &&
        game.joystick.direction != JoystickDirection.idle) {
      direction = game.joystick.relativeDelta;
    }

    return direction;
  }
}
