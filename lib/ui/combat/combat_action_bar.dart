import 'package:flutter/material.dart';

import '../../combat/battle_controller.dart';
import '../../config/models/jutsu_config.dart';

class CombatActionBar extends StatelessWidget {
  const CombatActionBar({
    super.key,
    required this.actions,
    required this.controller,
    required this.onFlee,
  });

  final Map<String, String> actions;
  final BattleController controller;
  final VoidCallback onFlee;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton(
              onPressed: controller.isPlayerTurn
                  ? controller.playerAttack
                  : null,
              child: Text(actions['attack']!),
            ),
            FilledButton(onPressed: null, child: Text(actions['item']!)),
            FilledButton(onPressed: onFlee, child: Text(actions['flee']!)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: controller.player.jutsu.map((jutsu) {
            return _JutsuButton(controller: controller, jutsu: jutsu);
          }).toList(),
        ),
      ],
    );
  }
}

class _JutsuButton extends StatelessWidget {
  const _JutsuButton({required this.controller, required this.jutsu});

  final BattleController controller;
  final JutsuConfig jutsu;

  @override
  Widget build(BuildContext context) {
    final canUse =
        controller.isPlayerTurn &&
        controller.player.currentChakra >= controller.playerJutsuCost(jutsu);
    return OutlinedButton(
      onPressed: canUse ? () => controller.playerUseJutsu(jutsu) : null,
      child: Text(
        '${jutsu.displayName} (${controller.playerJutsuCost(jutsu)})',
      ),
    );
  }
}
