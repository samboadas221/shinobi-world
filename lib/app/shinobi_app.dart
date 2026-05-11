import 'package:flutter/material.dart';

import '../config/game_config.dart';
import '../config/game_config_loader.dart';
import '../screens/first_demo_flow_screen.dart';

class ShinobiApp extends StatelessWidget {
  const ShinobiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GameConfig>(
      future: GameConfigLoader.load(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const MaterialApp(home: _AppLoadingView());
        }
        final config = snapshot.requireData;
        return MaterialApp(
          title: config.app.brand.appTitle,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: config.app.brand.themeSeedColor,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          home: FirstDemoFlowScreen(config: config),
        );
      },
    );
  }
}

class _AppLoadingView extends StatelessWidget {
  const _AppLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
