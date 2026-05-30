import 'package:flame/components.dart';

import '../config/models/enemy_config.dart';
import 'shinobi_world_game.dart';

/// Deprecated. Replaced by NinjaSpawnerComponent.
///
/// Kept to avoid breaking any existing references in save-game logic or tests.
/// All enemy spawning on the overworld is now managed by NinjaSpawnerComponent.
class NpcManagerComponent extends Component
    with HasGameReference<ShinobiWorldGame> {
  NpcManagerComponent({required this.configs});

  final List<EnemyConfig> configs;

  @override
  void onLoad() {
    // No-op. Use NinjaSpawnerComponent for active NPC management.
  }

  @override
  void update(double dt) {
    // No-op.
  }
}
