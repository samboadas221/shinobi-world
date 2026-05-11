import 'package:flutter/material.dart';

import '../config/models/app_config.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({
    super.key,
    required this.menu,
    required this.onPlay,
    required this.onSettings,
    required this.onExit,
  });

  final MainMenuConfig menu;
  final VoidCallback onPlay;
  final VoidCallback onSettings;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                menu.title,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(menu.subtitle),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: onPlay,
                child: Text(menu.actions['play']!),
              ),
              OutlinedButton(
                onPressed: onSettings,
                child: Text(menu.actions['settings']!),
              ),
              TextButton(onPressed: onExit, child: Text(menu.actions['exit']!)),
            ],
          ),
        ),
      ),
    );
  }
}
