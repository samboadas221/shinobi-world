import 'package:flutter/material.dart';

import '../../combat/battle_participant.dart';

/// Displays one participant's stats (HP/chakra bars, effects, jutsu list).
/// Used for both player and enemy panels.
class CombatParticipantPanel extends StatelessWidget {
  const CombatParticipantPanel({
    super.key,
    required this.participant,
    required this.isPlayer,
  });

  final BattleParticipant participant;
  final bool isPlayer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E1420),
        border: Border.all(
          color: isPlayer
              ? const Color(0xFF3A6EFF).withAlpha(120)
              : const Color(0xFFFF3A3A).withAlpha(120),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _nameRow(),
          const SizedBox(height: 10),
          _statBar(
            label: 'HP',
            current: participant.currentHealth,
            max: participant.maxHealth,
            color: const Color(0xFF48E05A),
          ),
          const SizedBox(height: 6),
          _statBar(
            label: 'CK',
            current: participant.currentChakra,
            max: participant.maxChakra,
            color: const Color(0xFF4CA4FF),
          ),
          const SizedBox(height: 8),
          _statsRow(),
          if (participant.activeEffects.isNotEmpty) ...[
            const SizedBox(height: 8),
            _effectsList(),
          ],
          const SizedBox(height: 8),
          Expanded(child: _jutsuList()),
        ],
      ),
    );
  }

  Widget _nameRow() {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isPlayer ? const Color(0xFF3A6EFF) : const Color(0xFFFF3A3A),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            participant.name,
            style: const TextStyle(
              color: Color(0xFFE8ECF4),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _statBar({
    required String label,
    required int current,
    required int max,
    required Color color,
  }) {
    final ratio = max == 0 ? 0.0 : (current / max).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color.withAlpha(180),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              '$current / $max',
              style: const TextStyle(color: Color(0xFFB0B8CC), fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 3),
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Container(
                  height: 6,
                  width: constraints.maxWidth,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2535),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 6,
                  width: constraints.maxWidth * ratio,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(color: color.withAlpha(100), blurRadius: 4),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        _miniStat('SPD', participant.speed),
        const SizedBox(width: 10),
        _miniStat('ATK', participant.attack),
        const SizedBox(width: 10),
        _miniStat('DEF', participant.defense),
      ],
    );
  }

  Widget _miniStat(String label, int value) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: const TextStyle(
              color: Color(0xFF6B7590),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: '$value',
            style: const TextStyle(
              color: Color(0xFFCDD3E2),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _effectsList() {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: participant.activeEffects.map((e) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF1E2C40),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF2D4060), width: 0.5),
          ),
          child: Text(
            '${_effectLabel(e.effect.type)} ${e.turnsRemaining}t',
            style: const TextStyle(color: Color(0xFF90A8CC), fontSize: 9),
          ),
        );
      }).toList(),
    );
  }

  String _effectLabel(dynamic type) {
    switch (type.toString().split('.').last) {
      case 'armorBuff':
        return '⬆ARM';
      case 'speedBuff':
        return '⬆SPD';
      case 'enemyArmorDebuff':
        return '⬇ARM';
      case 'enemySpeedDebuff':
        return '⬇SPD';
      default:
        return '✨';
    }
  }

  Widget _jutsuList() {
    if (participant.jutsu.isEmpty) {
      return const Text(
        'No jutsu',
        style: TextStyle(color: Color(0xFF4A5170), fontSize: 10),
      );
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: participant.jutsu
            .map(
              (j) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  j.displayName,
                  style: const TextStyle(
                    color: Color(0xFF7080A0),
                    fontSize: 10,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
