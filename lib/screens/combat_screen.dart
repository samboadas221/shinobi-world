import 'package:flutter/material.dart';

import '../combat/battle_controller.dart';
import '../combat/battle_request.dart';
import '../combat/battle_result.dart';
import '../config/models/combat_config.dart';
import '../ui/combat/combat_action_bar.dart';
import '../ui/combat/combat_log.dart';
import '../ui/combat/combat_participant_panel.dart';

/// Full-screen RPG-style combat screen.
///
/// Layout (top → bottom):
///   1. VS header — turn indicator, participant names
///   2. Participant panels — player (left) vs enemy (right) with bars & stats
///   3. Combat log — last few messages in a dark monospaced panel
///   4. Action bar — Attack / Jutsu / Flee (jutsu panel slides up from here)
///
/// Adapts to both wide (PC) and narrow (Android) viewports.
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
        castedJutsuIds: _controller.castedJutsuIds,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Material(
          color: const Color(0xFF050A14),
          child: SafeArea(
            child: Column(
              children: [
                // ── VS header ─────────────────────────────────────────────
                _VsHeader(
                  controller: _controller,
                  title: widget.config.ui.screenTitle,
                ),

                // ── Participant panels ────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: CombatParticipantPanel(
                            participant: _controller.player,
                            isPlayer: true,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'VS',
                                style: TextStyle(
                                  color: Color(0xFF3A4A6A),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: CombatParticipantPanel(
                            participant: _controller.enemy,
                            isPlayer: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Combat log ────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: CombatLog(logs: _controller.logs),
                ),

                const SizedBox(height: 8),

                // ── Actions or Continue ───────────────────────────────────
                if (_controller.isBattleOver)
                  _ContinueButton(
                    controller: _controller,
                    onContinue: _finishCombat,
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
        );
      },
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _VsHeader extends StatelessWidget {
  const _VsHeader({required this.controller, required this.title});

  final BattleController controller;
  final String title;

  @override
  Widget build(BuildContext context) {
    final isPlayerTurn = controller.isPlayerTurn;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: const BoxDecoration(
        color: Color(0xFF080E1C),
        border: Border(bottom: BorderSide(color: Color(0xFF1A2438), width: 1)),
      ),
      child: Row(
        children: [
          // Player name
          Expanded(
            child: Text(
              controller.player.name,
              style: const TextStyle(
                color: Color(0xFF3A6EFF),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Turn indicator pill
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isPlayerTurn
                  ? const Color(0xFF1A2C5A)
                  : const Color(0xFF3A1010),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isPlayerTurn
                    ? const Color(0xFF3A6EFF)
                    : const Color(0xFFFF3A3A),
                width: 1,
              ),
            ),
            child: Text(
              isPlayerTurn ? 'YOUR TURN' : 'ENEMY TURN',
              style: TextStyle(
                color: isPlayerTurn
                    ? const Color(0xFF6A9EFF)
                    : const Color(0xFFFF6A6A),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),

          // Enemy name
          Expanded(
            child: Text(
              controller.enemy.name,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Color(0xFFFF3A3A),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.controller, required this.onContinue});

  final BattleController controller;
  final void Function(BattleOutcome) onContinue;

  @override
  Widget build(BuildContext context) {
    final victory = !controller.player.isDefeated;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => onContinue(
            victory ? BattleOutcome.victory : BattleOutcome.defeat,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: victory
                ? const Color(0xFF1A3A1A)
                : const Color(0xFF3A1A1A),
            foregroundColor: victory
                ? const Color(0xFF48E05A)
                : const Color(0xFFFF5A5A),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: victory
                    ? const Color(0xFF48E05A)
                    : const Color(0xFFFF5A5A),
                width: 1,
              ),
            ),
          ),
          child: Text(
            victory ? '✦ VICTORY — Continue' : '✗ DEFEAT — Continue',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
