import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../game/demo_state.dart';

class DemoHud extends StatefulWidget {
  const DemoHud({
    super.key,
    required this.stateListenable,
    required this.onPracticeJutsu,
  });

  final ValueListenable<DemoState> stateListenable;
  final ValueChanged<String> onPracticeJutsu;

  @override
  State<DemoHud> createState() => _DemoHudState();
}

class _DemoHudState extends State<DemoHud> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topLeft,
        child: ValueListenableBuilder<DemoState>(
          valueListenable: widget.stateListenable,
          builder: (context, state, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: FloatingActionButton.small(
                    onPressed: () => setState(() => _isExpanded = !_isExpanded),
                    child: Icon(_isExpanded ? Icons.close : Icons.bug_report),
                  ),
                ),
                if (_isExpanded)
                  _HudPanel(
                    state: state,
                    onPracticeJutsu: widget.onPracticeJutsu,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HudPanel extends StatelessWidget {
  const _HudPanel({required this.state, required this.onPracticeJutsu});

  final DemoState state;
  final ValueChanged<String> onPracticeJutsu;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height - 32,
        ),
        child: SingleChildScrollView(
          child: DefaultTextStyle(
            style: Theme.of(context).textTheme.bodyMedium!,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shinobi World Demo',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text('Player: ${state.playerName}'),
                Text('Run seed: ${state.runSeed}'),
                Text('Villages generated: ${state.villageCount}'),
                Text('Stored ninja: ${state.ninjaCount}'),
                Text('Start village: ${state.villageName}'),
                Text('Training field boost: ${state.trainingBoost}%'),
                Text('Chakra nature: ${state.playerChakraNature}'),
                Text('Secondary nature: ${state.playerSecondaryNature}'),
                Text('Player jutsu: ${state.playerJutsuNames.join(', ')}'),
                Text('Chakra: ${state.currentChakra}/${state.maxChakra}'),
                _PracticeButtons(
                  state: state,
                  onPracticeJutsu: onPracticeJutsu,
                ),
                Text(state.practiceLog),
                Text('World phase: ${state.phase}'),
                LinearProgressIndicator(value: state.cycleProgress),
                const SizedBox(height: 8),
                Text('${state.enemyName} jutsu:'),
                Text(state.enemyJutsuNames.join(', ')),
                const SizedBox(height: 8),
                Text('Database: ${state.databaseStatus}'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PracticeButtons extends StatelessWidget {
  const _PracticeButtons({required this.state, required this.onPracticeJutsu});

  final DemoState state;
  final ValueChanged<String> onPracticeJutsu;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: state.practiceJutsus.map((jutsu) {
        return OutlinedButton(
          onPressed: state.currentChakra >= jutsu.cost
              ? () => onPracticeJutsu(jutsu.id)
              : null,
          child: Text(
            '${jutsu.name} ${jutsu.cost}c L${jutsu.level}/${jutsu.requiredSeals}',
          ),
        );
      }).toList(),
    );
  }
}
