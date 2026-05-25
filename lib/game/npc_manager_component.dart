import 'dart:math';
import 'package:flame/components.dart';
import '../config/models/enemy_config.dart';
import '../jutsu/jutsu_loadout_selector.dart';
import 'enemy_component.dart';
import 'procedural_world_map.dart';
import 'shinobi_world_game.dart';

class NpcManagerComponent extends Component
    with HasGameReference<ShinobiWorldGame> {
  NpcManagerComponent({required this.configs});

  final List<EnemyConfig> configs;

  @override
  void onLoad() {
    // Deprecated overworld enemy spawning.
    // Overworld stays empty, while all generated village ninjas are registered in SQLite.
  }

  @override
  void update(double dt) {
    // Deprecated overworld enemy spawning updates.
  }
}
