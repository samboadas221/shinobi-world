import 'package:flutter/material.dart';

import '../../config/models/character_config.dart';

class AbilityPointsPanel extends StatelessWidget {
  const AbilityPointsPanel({
    super.key,
    required this.title,
    required this.config,
    required this.values,
    required this.unspentPoints,
    required this.onChanged,
  });

  final String title;
  final AbilityPointConfig config;
  final Map<String, int> values;
  final int unspentPoints;
  final void Function(String id, int value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        for (final entry in config.labels.entries)
          _AbilityStepper(
            id: entry.key,
            label: entry.value,
            value: values[entry.key]!,
            minValue: config.minValue,
            maxValue: config.maxValue,
            canIncrease: unspentPoints > 0,
            onChanged: onChanged,
          ),
      ],
    );
  }
}

class _AbilityStepper extends StatelessWidget {
  const _AbilityStepper({
    required this.id,
    required this.label,
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.canIncrease,
    required this.onChanged,
  });

  final String id;
  final String label;
  final int value;
  final int minValue;
  final int maxValue;
  final bool canIncrease;
  final void Function(String id, int value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        IconButton(
          onPressed: value > minValue ? () => onChanged(id, value - 1) : null,
          icon: const Icon(Icons.remove),
        ),
        SizedBox(width: 32, child: Center(child: Text('$value'))),
        IconButton(
          onPressed: value < maxValue && canIncrease
              ? () => onChanged(id, value + 1)
              : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
