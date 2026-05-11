import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../character/player_profile.dart';
import '../config/game_config.dart';
import '../data/shinobi_database.dart';
import '../world/generated_world_run.dart';
import '../world/world_run_generator.dart';
import 'character_creation_screen.dart';
import 'demo_game_screen.dart';
import 'main_menu_screen.dart';
import 'splash_screen.dart';

enum _FirstDemoStage { splash, menu, character, loading, game }

class FirstDemoFlowScreen extends StatefulWidget {
  const FirstDemoFlowScreen({super.key, required this.config});

  final GameConfig config;

  @override
  State<FirstDemoFlowScreen> createState() => _FirstDemoFlowScreenState();
}

class _FirstDemoFlowScreenState extends State<FirstDemoFlowScreen> {
  final ShinobiDatabase _database = ShinobiDatabase.open();
  var _stage = _FirstDemoStage.splash;
  PlayerProfile? _profile;
  GeneratedWorldRun? _run;
  String _loadingMessage = '';
  double _loadingProgress = 0;

  @override
  Widget build(BuildContext context) {
    return switch (_stage) {
      _FirstDemoStage.splash => SplashScreen(
        brand: widget.config.app.brand,
        onFinished: () => setState(() => _stage = _FirstDemoStage.menu),
      ),
      _FirstDemoStage.menu => MainMenuScreen(
        menu: widget.config.app.menu,
        onPlay: () => setState(() => _stage = _FirstDemoStage.character),
        onSettings: _showSettingsMessage,
        onExit: _exitGame,
      ),
      _FirstDemoStage.character => CharacterCreationScreen(
        creation: widget.config.character,
        clothing: widget.config.clothing,
        onCreated: _startRun,
      ),
      _FirstDemoStage.loading => _LoadingScreen(
        message: _loadingMessage,
        progress: _loadingProgress,
      ),
      _FirstDemoStage.game => DemoGameScreen(
        config: widget.config,
        database: _database,
        profile: _profile!,
        run: _run!,
      ),
    };
  }

  Future<void> _startRun(PlayerProfile profile) async {
    setState(() {
      _stage = _FirstDemoStage.loading;
      _loadingMessage = 'Generating world seed...';
      _loadingProgress = 0;
    });

    final generator = WorldRunGenerator(
      runConfig: widget.config.worldRun,
      populationConfig: widget.config.villagePopulation,
    );

    // Phase 1: generate only the starting village and its ninjas.
    _updateLoading('Generating starting village...', 0.1);
    await Future<void>.delayed(Duration.zero); // yield to render
    final run = generator.generateStartingVillageOnly();

    // Phase 2: prepare database tables.
    _updateLoading('Preparing database...', 0.3);
    await _database.prepareDemoData();

    // Phase 3: store starting village + its ninjas only.
    _updateLoading('Storing starting village...', 0.5);
    await _database.storeFirstDemoRun(profile: profile, run: run);

    // Phase 4: enter the game immediately.
    _updateLoading('Entering the world...', 0.9);
    setState(() {
      _profile = profile;
      _run = run;
      _stage = _FirstDemoStage.game;
    });

    // Phase 5: generate remaining villages & ninjas in the background.
    _generateRemainingInBackground(generator, run, profile);
  }

  Future<void> _generateRemainingInBackground(
    WorldRunGenerator generator,
    GeneratedWorldRun partialRun,
    PlayerProfile profile,
  ) async {
    final fullRun = generator.generateRemaining(partialRun);
    await _database.storeRemainingNinjas(
      seed: fullRun.seed,
      villages: fullRun.villages,
      ninjas: fullRun.ninjas,
      startingVillageId: partialRun.startingVillage.id,
    );
    // Update the run reference so the HUD shows the full count.
    setState(() => _run = fullRun);
  }

  void _updateLoading(String message, double progress) {
    setState(() {
      _loadingMessage = message;
      _loadingProgress = progress;
    });
  }

  void _showSettingsMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(widget.config.app.menu.settingsMessage)),
    );
  }

  void _exitGame() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(widget.config.app.menu.exitMessage)));
    SystemNavigator.pop();
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen({required this.message, required this.progress});

  final String message;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white24,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
