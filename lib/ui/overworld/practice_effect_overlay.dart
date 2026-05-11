import 'package:flutter/material.dart';

/// A brief animated overlay that appears when the player
/// practices a jutsu in the overworld.
class PracticeEffectOverlay extends StatefulWidget {
  const PracticeEffectOverlay({
    super.key,
    required this.jutsuName,
    required this.onDismissed,
  });

  final String jutsuName;
  final VoidCallback onDismissed;

  @override
  State<PracticeEffectOverlay> createState() => _PracticeEffectOverlayState();
}

class _PracticeEffectOverlayState extends State<PracticeEffectOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.3, curve: Curves.easeIn),
    reverseCurve: const Interval(0.6, 1, curve: Curves.easeOut),
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(0, -0.3),
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void initState() {
    super.initState();
    _controller.forward().then((_) => widget.onDismissed());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _opacity,
        child: IgnorePointer(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.deepPurpleAccent.withValues(alpha: 0.85),
                  Colors.blueAccent.withValues(alpha: 0.85),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurpleAccent.withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Text(
              '⚡ ${widget.jutsuName} practiced!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
