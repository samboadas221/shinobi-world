import 'package:flutter/material.dart';

/// Scrollable dark-themed combat log widget.
class CombatLog extends StatefulWidget {
  const CombatLog({super.key, required this.logs});

  final List<String> logs;

  @override
  State<CombatLog> createState() => _CombatLogState();
}

class _CombatLogState extends State<CombatLog> {
  final _scrollController = ScrollController();

  @override
  void didUpdateWidget(CombatLog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.logs != oldWidget.logs) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF070B14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1E2535), width: 1),
      ),
      child: ListView.builder(
        controller: _scrollController,
        reverse: true,
        itemCount: widget.logs.length,
        itemBuilder: (context, i) {
          // First entry (i=0 in reversed list) is the most recent
          final opacity = i == 0 ? 1.0 : (1.0 - i * 0.18).clamp(0.3, 1.0);
          return Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              '▸ ${widget.logs[i]}',
              style: TextStyle(
                color: Color.fromRGBO(176, 196, 222, opacity),
                fontSize: 11,
                fontFamily: 'monospace',
                height: 1.4,
              ),
            ),
          );
        },
      ),
    );
  }
}
