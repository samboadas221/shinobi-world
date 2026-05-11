import 'package:flutter/material.dart';

import '../combat/battle_controller.dart';
import '../combat/battle_request.dart';
import '../combat/battle_result.dart';
import '../config/models/combat_config.dart';
import '../ui/combat/combat_action_bar.dart';
import '../ui/combat/combat_log.dart';
import '../ui/combat/combat_participant_panel.dart';

class CombatScreen extends StatefulWidget {
  const CombatScreen({
    super.key,
    required this.request,
    required this.config,
    required this.onCombatEnd,
  });

  final BattleRequest request;
  final CombatConfig config;
  final void Function(BattleResult result) onCombatEnd;

  @override
  State<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends State<CombatScreen> {
  late final BattleController _controller = BattleController(
    request: widget.request,
    config: widget.config,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finishCombat(BattleOutcome outcome) {
    widget.onCombatEnd(
      BattleResult(
        outcome: outcome,
        playerHealth: _controller.player.currentHealth,
        playerChakra: _controller.player.currentChakra,
        enemyHealth: _controller.enemy.currentHealth,
        enemyChakra: _controller.enemy.currentChakra,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.config.ui.screenTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text('Current turn: ${_controller.currentActor.name}'),
                  Text(
                    'Turn order: ${_controller.turnOrder.map((p) => p.name).join(' -> ')}',
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: CombatParticipantPanel(
                            participant: _controller.player,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CombatParticipantPanel(
                            participant: _controller.enemy,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  CombatLog(logs: _controller.logs),
                  const SizedBox(height: 12),
                  if (_controller.isBattleOver)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          final outcome = _controller.player.isDefeated
                              ? BattleOutcome.defeat
                              : BattleOutcome.victory;
                          _finishCombat(outcome);
                        },
                        child: const Text('Continue'),
                      ),
                    )
                  else
                    CombatActionBar(
                      actions: widget.config.ui.actions,
                      controller: _controller,
                      onFlee: () => _finishCombat(BattleOutcome.fled),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
