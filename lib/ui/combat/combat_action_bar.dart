import 'package:flutter/material.dart';

import '../../combat/battle_controller.dart';
import '../../config/models/jutsu_config.dart';
import 'jutsu_selection_panel.dart';

/// Bottom action toolbar with Attack, Jutsu (expandable), and Flee buttons.
class CombatActionBar extends StatefulWidget {
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
  State<CombatActionBar> createState() => _CombatActionBarState();
}

class _CombatActionBarState extends State<CombatActionBar>
    with SingleTickerProviderStateMixin {
  bool _jutsuPanelOpen = false;
  late final AnimationController _animController;
  late final Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _slideAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleJutsuPanel() {
    setState(() => _jutsuPanelOpen = !_jutsuPanelOpen);
    if (_jutsuPanelOpen) {
      _animController.forward();
    } else {
      _animController.reverse();
    }
  }

  void _useJutsu(JutsuConfig jutsu) {
    widget.controller.playerUseJutsu(jutsu);
    setState(() => _jutsuPanelOpen = false);
    _animController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isPlayerTurn = widget.controller.isPlayerTurn;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Jutsu panel slide-up
        SizeTransition(
          sizeFactor: _slideAnim,
          axisAlignment: 1,
          child: JutsuSelectionPanel(
            controller: widget.controller,
            onSelect: _useJutsu,
            onClose: _toggleJutsuPanel,
          ),
        ),

        // Main action buttons
        Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: const BoxDecoration(
            color: Color(0xFF080E1A),
            border: Border(top: BorderSide(color: Color(0xFF1A2438), width: 1)),
          ),
          child: Row(
            children: [
              // Attack
              Expanded(
                child: _ActionButton(
                  label: widget.actions['attack'] ?? 'Attack',
                  icon: Icons.flash_on,
                  color: const Color(0xFFFF4F4F),
                  enabled: isPlayerTurn,
                  onTap: widget.controller.playerAttack,
                ),
              ),
              const SizedBox(width: 8),
              // Jutsu
              Expanded(
                child: _ActionButton(
                  label: _jutsuPanelOpen
                      ? 'Close'
                      : (widget.actions['jutsu'] ?? 'Jutsu'),
                  icon: _jutsuPanelOpen ? Icons.close : Icons.auto_awesome,
                  color: const Color(0xFF8040FF),
                  enabled: isPlayerTurn,
                  highlighted: _jutsuPanelOpen,
                  onTap: isPlayerTurn ? _toggleJutsuPanel : null,
                ),
              ),
              const SizedBox(width: 8),
              // Flee
              Expanded(
                child: _ActionButton(
                  label: widget.actions['flee'] ?? 'Flee',
                  icon: Icons.directions_run,
                  color: const Color(0xFF3A6EFF),
                  enabled: isPlayerTurn,
                  onTap: isPlayerTurn ? widget.onFlee : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onTap,
    this.highlighted = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.35,
        duration: const Duration(milliseconds: 150),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: highlighted ? color.withAlpha(60) : const Color(0xFF0E1828),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: highlighted ? color : color.withAlpha(60),
              width: highlighted ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
