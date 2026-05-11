import 'package:flutter/material.dart';

import '../../combat/battle_participant.dart';

class CombatParticipantPanel extends StatelessWidget {
  const CombatParticipantPanel({super.key, required this.participant});

  final BattleParticipant participant;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              participant.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text('${participant.currentHealth}/${participant.maxHealth} HP'),
            Text(
              '${participant.currentChakra}/${participant.maxChakra} chakra',
            ),
            Text('Speed: ${participant.speed}'),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  participant.jutsu
                      .map((jutsu) => jutsu.displayName)
                      .join(', '),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
