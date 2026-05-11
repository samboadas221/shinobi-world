import 'package:flutter/material.dart';

import '../../config/models/clothing_config.dart';

class ClothingPanel extends StatelessWidget {
  const ClothingPanel({
    super.key,
    required this.title,
    required this.colorTitle,
    required this.config,
    required this.selections,
    required this.selectedColorLabel,
    required this.onSlotChanged,
    required this.onColorChanged,
  });

  final String title;
  final String colorTitle;
  final ClothingConfig config;
  final Map<String, String> selections;
  final String selectedColorLabel;
  final void Function(String slot, String option) onSlotChanged;
  final ValueChanged<String> onColorChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        for (final entry in config.slots.entries)
          DropdownButtonFormField<String>(
            initialValue: selections[entry.key],
            decoration: InputDecoration(labelText: entry.value.label),
            items: entry.value.options
                .map(
                  (option) =>
                      DropdownMenuItem(value: option, child: Text(option)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                onSlotChanged(entry.key, value);
              }
            },
          ),
        const SizedBox(height: 8),
        Text(colorTitle),
        Wrap(
          spacing: 8,
          children: config.colors.map((color) {
            return ChoiceChip(
              selected: selectedColorLabel == color.label,
              label: Text(color.label),
              avatar: CircleAvatar(backgroundColor: color.value),
              onSelected: (_) => onColorChanged(color.label),
            );
          }).toList(),
        ),
      ],
    );
  }
}
