import 'package:flutter/material.dart';
import '../config/models/app_config.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({
    super.key,
    required this.menu,
    required this.style,
    required this.onPlay,
    required this.onSettings,
    required this.onExit,
  });

  final MainMenuConfig menu;
  final MenuStyleConfig style;
  final VoidCallback onPlay;
  final VoidCallback onSettings;
  final VoidCallback onExit;

  OutlinedBorder _getButtonShape() {
    switch (style.buttonShape) {
      case 'stadium':
        return const StadiumBorder();
      case 'rectangular':
        return const RoundedRectangleBorder(borderRadius: BorderRadius.zero);
      case 'rounded':
      default:
        return RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(style.borderRadius),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final shape = _getButtonShape();

    Widget buildButton(String label, VoidCallback onPressed, {bool primary = true}) {
      return SizedBox(
        width: style.buttonWidth,
        height: style.buttonHeight,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: primary ? style.buttonColor : style.buttonColor.withOpacity(0.7),
            foregroundColor: style.buttonTextColor,
            shape: shape,
            textStyle: TextStyle(
              fontSize: style.fontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: Text(label),
        ),
      );
    }

    return Scaffold(
      backgroundColor: style.backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              style.backgroundColor,
              Color.alphaBlend(style.buttonColor.withOpacity(0.15), style.backgroundColor),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                menu.title,
                style: TextStyle(
                  color: style.titleColor,
                  fontSize: style.titleSize,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  shadows: [
                    Shadow(
                      color: style.buttonColor.withOpacity(0.5),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                menu.subtitle.toUpperCase(),
                style: TextStyle(
                  color: style.titleColor.withOpacity(0.6),
                  fontSize: style.fontSize * 0.9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4.0,
                ),
              ),
              const SizedBox(height: 48),
              buildButton(menu.actions['play'] ?? 'Play', onPlay),
              SizedBox(height: style.spacing),
              buildButton(menu.actions['settings'] ?? 'Settings', onSettings, primary: false),
              SizedBox(height: style.spacing),
              buildButton(menu.actions['exit'] ?? 'Exit', onExit, primary: false),
            ],
          ),
        ),
      ),
    );
  }
}
