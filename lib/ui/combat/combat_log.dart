import 'package:flutter/material.dart';

class CombatLog extends StatelessWidget {
  const CombatLog({super.key, required this.logs});

  final List<String> logs;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 88,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: ListView(reverse: true, children: logs.map(Text.new).toList()),
        ),
      ),
    );
  }
}
