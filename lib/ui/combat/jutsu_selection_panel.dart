import 'package:flutter/material.dart';

import '../../combat/battle_controller.dart';
import '../../config/models/jutsu_config.dart';

/// Expandable jutsu selection panel that slides up from the bottom.
/// Used inside the action bar when the player taps "Jutsu".
class JutsuSelectionPanel extends StatelessWidget {
  const JutsuSelectionPanel({
    super.key,
    required this.controller,
    required this.onSelect,
    required this.onClose,
  });

  final BattleController controller;
  final void Function(JutsuConfig) onSelect;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final jutsuList = controller.player.jutsu;
    return Container(
      constraints: const BoxConstraints(maxHeight: 280),
      decoration: const BoxDecoration(
        color: Color(0xFF0B1020),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: Color(0xFF2A3A5A), width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Panel handle + title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
            child: Row(
              children: [
                const Text(
                  'SELECT JUTSU',
                  style: TextStyle(
                    color: Color(0xFF8090B0),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xFF4A5A78),
                    size: 18,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 170,
                mainAxisExtent: 80,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: jutsuList.length,
              itemBuilder: (context, i) {
                return _JutsuCard(
                  jutsu: jutsuList[i],
                  controller: controller,
                  onTap: () => onSelect(jutsuList[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _JutsuCard extends StatelessWidget {
  const _JutsuCard({
    required this.jutsu,
    required this.controller,
    required this.onTap,
  });

  final JutsuConfig jutsu;
  final BattleController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cost = controller.playerJutsuCost(jutsu);
    final canUse =
        controller.isPlayerTurn && controller.player.currentChakra >= cost;

    return GestureDetector(
      onTap: canUse ? onTap : null,
      child: AnimatedOpacity(
        opacity: canUse ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: canUse ? const Color(0xFF101828) : const Color(0xFF0A1020),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: canUse
                  ? _elementColor(jutsu.chakraNature).withAlpha(100)
                  : const Color(0xFF1E2535),
              width: 1,
            ),
            boxShadow: canUse
                ? [
                    BoxShadow(
                      color: _elementColor(jutsu.chakraNature).withAlpha(30),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: _elementColor(jutsu.chakraNature).withAlpha(40),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      jutsu.chakraNature.toUpperCase(),
                      style: TextStyle(
                        color: _elementColor(jutsu.chakraNature),
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$cost CK',
                    style: const TextStyle(
                      color: Color(0xFF4CA4FF),
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                jutsu.displayName,
                style: const TextStyle(
                  color: Color(0xFFD0D8EC),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (jutsu.damage > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '${jutsu.damage} dmg',
                    style: const TextStyle(
                      color: Color(0xFF8090A8),
                      fontSize: 9,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _elementColor(String nature) {
    switch (nature) {
      case 'fire':
        return const Color(0xFFFF6B3A);
      case 'water':
        return const Color(0xFF3AB0FF);
      case 'wind':
        return const Color(0xFF8AE86B);
      case 'earth':
        return const Color(0xFFB8922A);
      case 'lightning':
        return const Color(0xFFFFD83A);
      default:
        return const Color(0xFF8090B0);
    }
  }
}
