import 'dart:math';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/models/player_config.dart';
import '../world/collision/aabb_rect.dart';
import 'collision_registry.dart';
import 'shinobi_world_game.dart';

class PlayerComponent extends PositionComponent
    with
        KeyboardHandler,
        HasGameReference<ShinobiWorldGame>,
        CollisionCallbacks {
  PlayerComponent({
    required PlayerConfig config,
    required Vector2 spawnPosition,
    required CollisionRegistry collisionRegistry,
  }) : _config = config,
       _collisionRegistry = collisionRegistry,
       super(position: spawnPosition, size: config.size, anchor: Anchor.center);

  final PlayerConfig _config;
  final CollisionRegistry _collisionRegistry;
  final _pressedKeys = <LogicalKeyboardKey>{};
  late final Paint _bodyPaint = Paint()..color = _config.visual.bodyColor;
  late final Paint _headbandPaint = Paint()
    ..color = _config.visual.headbandColor;

  final Vector2 _previousPosition = Vector2.zero();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(RectangleHitbox());
  }

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

  double _chakraDrainAccumulator = 0.0;

  @override
  void update(double dt) {
    super.update(dt);
    _previousPosition.setFrom(position);

    final direction = _movementDirection();
    if (direction.isZero()) {
      _chakraDrainAccumulator = 0.0;
      return;
    }

    final isShiftPressed =
        _pressedKeys.contains(LogicalKeyboardKey.shiftLeft) ||
        _pressedKeys.contains(LogicalKeyboardKey.shiftRight);
    final hasChakra = game.practice.currentChakra > 0;
    final isRunning = isShiftPressed && hasChakra;

    var speed = _config.movementSpeed;
    if (isRunning) {
      speed *= 2.0;
      _chakraDrainAccumulator += 0.1 * dt;
      if (_chakraDrainAccumulator >= 1.0) {
        final drain = _chakraDrainAccumulator.floor();
        _chakraDrainAccumulator -= drain;
        game.practice.currentChakra = max(
          0,
          game.practice.currentChakra - drain,
        );
      }
    } else {
      _chakraDrainAccumulator = 0.0;
    }

    position += direction.normalized() * speed * dt;

    // ── Structure collision ────────────────────────────────────────────────
    // Test the player's new AABB. If it overlaps a building, revert position.
    final halfW = size.x / 2;
    final halfH = size.y / 2;
    final moverRect = AabbRect(
      left: position.x - halfW,
      top: position.y - halfH,
      right: position.x + halfW,
      bottom: position.y + halfH,
    );

    if (_collisionRegistry.collides(moverRect)) {
      // Try axis-separated sliding so the player can still move along walls.
      final xOnlyPos = Vector2(_previousPosition.x, position.y);
      final yOnlyPos = Vector2(position.x, _previousPosition.y);

      final xAabb = AabbRect(
        left: xOnlyPos.x - halfW,
        top: xOnlyPos.y - halfH,
        right: xOnlyPos.x + halfW,
        bottom: xOnlyPos.y + halfH,
      );
      final yAabb = AabbRect(
        left: yOnlyPos.x - halfW,
        top: yOnlyPos.y - halfH,
        right: yOnlyPos.x + halfW,
        bottom: yOnlyPos.y + halfH,
      );

      if (!_collisionRegistry.collides(xAabb)) {
        position.setFrom(xOnlyPos);
      } else if (!_collisionRegistry.collides(yAabb)) {
        position.setFrom(yOnlyPos);
      } else {
        position.setFrom(_previousPosition);
      }
    }
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

    // Include joystick movement if keyboard is not active.
    if (direction.isZero() &&
        game.joystick != null &&
        game.joystick!.direction != JoystickDirection.idle) {
      direction = game.joystick!.relativeDelta;
    }

    return direction;
  }
}
