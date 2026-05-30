import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../character/player_profile.dart';
import '../config/game_config.dart';
import '../data/shinobi_database.dart';
import '../game/world_layout/world_layout_data.dart';
import '../game/world_layout/world_layout_generator.dart';
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
  WorldLayoutData? _layoutData;
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
        style: widget.config.app.mainMenuStyle,
        onPlay: () => setState(() => _stage = _FirstDemoStage.character),
        onSettings: _showSettingsMessage,
        onExit: _exitGame,
      ),
      _FirstDemoStage.character => CharacterCreationScreen(
        creation: widget.config.character,
        clothing: widget.config.clothing,
        statsScaling: widget.config.statsScaling,
        style: widget.config.app.characterMenuStyle,
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
        layoutData: _layoutData!,
        onRegenerateWorld: (seed) => _startRun(_profile!, customSeed: seed),
      ),
    };
  }

  Future<void> _startRun(PlayerProfile profile, {int? customSeed}) async {
    setState(() {
      _stage = _FirstDemoStage.loading;
      _loadingMessage = 'Creating Village Data';
      _loadingProgress = 0.1;
    });

    final generator = WorldRunGenerator(
      runConfig: widget.config.worldRun,
      populationConfig: widget.config.villagePopulation,
      mapConfig: widget.config.world.map,
    );

    final run = generator.generateStartingVillageOnly(customSeed: customSeed);

    // Phase 2: prepare database tables.
    await _database.prepareDemoData();

    // Phase 3: store starting village + its ninjas only.
    await _database.storeFirstDemoRun(profile: profile, run: run);

    final random = Random(run.seed);
    var currentRun = run;

    final otherVillages = generator.allPreCalculatedVillages
        .where((v) => v.id != run.startingVillage.id)
        .toList();
    final totalVillages = otherVillages.length;
    int generatedCount = 0;

    for (final village in otherVillages) {
      generatedCount++;
      // Progress goes from 10% (0.1) to 90% (0.9)
      final progress = 0.1 + (0.8 * (generatedCount / totalVillages));
      _updateLoading('Generating village: ${village.name}', progress);

      // Yield to the Flutter engine to draw the updated loading bar
      await Future.delayed(const Duration(milliseconds: 50));

      // Generate ninjas for this specific village
      final villageNinjas = generator.generateNinjasForVillage(random, village);

      // Store this village and its ninjas in the database
      await _database.storeRemainingNinjas(
        seed: run.seed,
        villages: [village],
        ninjas: villageNinjas,
        startingVillageId: run.startingVillage.id,
      );

      // Update in-memory run state progressively
      final updatedVillages = List<GeneratedVillage>.from(currentRun.villages)
        ..add(village);
      final updatedNinjas = List<GeneratedNinja>.from(currentRun.ninjas)
        ..addAll(villageNinjas);

      currentRun = GeneratedWorldRun(
        seed: run.seed,
        villages: updatedVillages,
        ninjas: updatedNinjas,
        startingVillage: run.startingVillage,
        rogueCount: currentRun.rogueCount,
        mapWidthTiles: run.mapWidthTiles,
        mapHeightTiles: run.mapHeightTiles,
        allVillages: run.allVillages,
      );
    }

    // Generate rogue ninjas
    _updateLoading('Generating rogue ninjas...', 0.9);
    await Future.delayed(const Duration(milliseconds: 50));

    final rogueNinjas = generator.generateRogueNinjas(
      random,
      generator.allPreCalculatedVillages.length,
    );
    await _database.storeRemainingNinjas(
      seed: run.seed,
      villages: [],
      ninjas: rogueNinjas,
      startingVillageId: run.startingVillage.id,
    );

    final finalRun = GeneratedWorldRun(
      seed: run.seed,
      villages: currentRun.villages,
      ninjas: List<GeneratedNinja>.from(currentRun.ninjas)..addAll(rogueNinjas),
      startingVillage: run.startingVillage,
      rogueCount: rogueNinjas.length,
      mapWidthTiles: run.mapWidthTiles,
      mapHeightTiles: run.mapHeightTiles,
      allVillages: run.allVillages,
    );

    // Finalize world layout generation
    final layoutData = await const WorldLayoutGenerator().generateWorldLayout(
      run: finalRun,
      mapConfig: widget.config.world.map,
      onProgress: (villageName, index, total) {
        final progress = 0.90 + (0.08 * (index / total));
        _updateLoading('Structuring layout: $villageName', progress);
      },
    );

    _updateLoading('Entering the world...', 1.0);
    await Future.delayed(const Duration(milliseconds: 50));

    if (mounted) {
      setState(() {
        _profile = profile;
        _run = finalRun;
        _layoutData = layoutData;
        _stage = _FirstDemoStage.game;
      });
    }
  }

  void _updateLoading(String message, double progress) {
    if (mounted) {
      setState(() {
        _loadingMessage = message;
        _loadingProgress = progress;
      });
    }
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
