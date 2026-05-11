import 'package:flutter/material.dart';

import '../character/character_generator.dart';
import '../character/character_roll.dart';
import '../character/player_profile.dart';
import '../config/models/character_config.dart';
import '../config/models/clothing_config.dart';
import '../ui/character/ability_points_panel.dart';
import '../ui/character/clothing_panel.dart';

class CharacterCreationScreen extends StatefulWidget {
  const CharacterCreationScreen({
    super.key,
    required this.creation,
    required this.clothing,
    required this.onCreated,
  });

  final CharacterCreationConfig creation;
  final ClothingConfig clothing;
  final ValueChanged<PlayerProfile> onCreated;

  @override
  State<CharacterCreationScreen> createState() =>
      _CharacterCreationScreenState();
}

class _CharacterCreationScreenState extends State<CharacterCreationScreen> {
  late final CharacterGenerator _generator = CharacterGenerator(
    creation: widget.creation,
    clothing: widget.clothing,
  );
  late CharacterRoll _roll = _generator.roll();
  late final TextEditingController _nameController = TextEditingController(
    text: _roll.name,
  );

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.creation.labels;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  Text(
                    widget.creation.screenTitle,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: labels.name),
                    onChanged: (value) =>
                        _updateRoll(_roll.copyWith(name: value)),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: widget.creation.genderOptions
                        .map(
                          (gender) =>
                              ButtonSegment(value: gender, label: Text(gender)),
                        )
                        .toList(),
                    selected: {_roll.gender},
                    onSelectionChanged: (values) {
                      _updateRoll(_roll.copyWith(gender: values.first));
                    },
                  ),
                  const SizedBox(height: 12),
                  Text('${labels.naturalNature}: ${_roll.naturalNature}'),
                  Text(
                    '${labels.secondaryAffinity}: ${_roll.secondaryNature} '
                    'x${widget.creation.secondaryCostMultiplier}',
                  ),
                  Text(
                    '${labels.unspentPoints}: ${_roll.totalPoints - _spentPoints}',
                  ),
                  const SizedBox(height: 12),
                  AbilityPointsPanel(
                    title: labels.abilityPoints,
                    config: widget.creation.ability,
                    values: _roll.spentPoints,
                    unspentPoints: _roll.totalPoints - _spentPoints,
                    onChanged: _changeAbility,
                  ),
                  const SizedBox(height: 12),
                  ClothingPanel(
                    title: labels.clothing,
                    colorTitle: labels.clothingColor,
                    config: widget.clothing,
                    selections: _roll.clothing,
                    selectedColorLabel: _roll.clothingColorLabel,
                    onSlotChanged: _changeClothing,
                    onColorChanged: _changeColor,
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _reroll,
                        icon: const Icon(Icons.casino),
                        label: Text(widget.creation.rerollLabel),
                      ),
                      FilledButton(
                        onPressed: _roll.totalPoints == _spentPoints
                            ? _submit
                            : null,
                        child: Text(widget.creation.submitLabel),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  int get _spentPoints {
    return _roll.spentPoints.values.fold(0, (sum, value) => sum + value);
  }

  void _changeAbility(String id, int value) {
    final spent = {..._roll.spentPoints};
    final previous = spent[id]!;
    final nextSpent = _spentPoints - previous + value;
    if (nextSpent > _roll.totalPoints) {
      return;
    }
    spent[id] = value;
    _updateRoll(_roll.copyWith(spentPoints: spent));
  }

  void _changeClothing(String slot, String option) {
    _updateRoll(_roll.copyWith(clothing: {..._roll.clothing, slot: option}));
  }

  void _changeColor(String label) {
    _updateRoll(_roll.copyWith(clothingColorLabel: label));
  }

  void _reroll() {
    _updateRoll(_generator.roll());
    _nameController.text = _roll.name;
  }

  void _submit() {
    widget.onCreated(_roll.toProfile(widget.creation.secondaryCostMultiplier));
  }

  void _updateRoll(CharacterRoll roll) {
    setState(() => _roll = roll);
  }
}
