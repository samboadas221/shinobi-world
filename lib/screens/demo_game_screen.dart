import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../character/player_profile.dart';
import '../config/game_config.dart';
import '../data/shinobi_database.dart';
import '../game/shinobi_world_game.dart';
import '../ui/demo_hud.dart';
import '../ui/overworld/practice_effect_overlay.dart';
import '../world/generated_world_run.dart';
import 'combat_screen.dart';

class DemoGameScreen extends StatefulWidget {
  const DemoGameScreen({
    super.key,
    required this.config,
    required this.database,
    required this.profile,
    required this.run,
  });

  final GameConfig config;
  final ShinobiDatabase database;
  final PlayerProfile profile;
  final GeneratedWorldRun run;

  @override
  State<DemoGameScreen> createState() => _DemoGameScreenState();
}

class _DemoGameScreenState extends State<DemoGameScreen> {
  late final ShinobiWorldGame _game = ShinobiWorldGame(
    config: widget.config,
    database: widget.database,
    profile: widget.profile,
    run: widget.run,
  );
  String? _practiceEffectJutsu;

  @override
  void didUpdateWidget(DemoGameScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.run != oldWidget.run) {
      _game.updateRun(widget.run);
    }
  }

  void _onPracticeJutsu(String jutsuId) {
    final name = _game.practiceJutsu(jutsuId);
    if (name != null) {
      setState(() => _practiceEffectJutsu = name);
    }
  }

  void _dismissPracticeEffect() {
    setState(() => _practiceEffectJutsu = null);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: _game.encounterRequest,
      builder: (context, encounter, _) {
        if (encounter != null) {
          return CombatScreen(
            request: encounter,
            config: widget.config.combat,
            onCombatEnd: _game.finishEncounter,
          );
        }
        return Scaffold(
          body: Stack(
            children: [
              GameWidget(game: _game),
              DemoHud(
                stateListenable: _game.demoState,
                onPracticeJutsu: _onPracticeJutsu,
              ),
              if (_practiceEffectJutsu != null)
                Positioned(
                  bottom: 120,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: PracticeEffectOverlay(
                      key: ValueKey(_practiceEffectJutsu),
                      jutsuName: _practiceEffectJutsu!,
                      onDismissed: _dismissPracticeEffect,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
