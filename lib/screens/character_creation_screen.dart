import 'dart:math';
import 'package:flutter/material.dart';

import '../character/character_generator.dart';
import '../character/character_roll.dart';
import '../character/ninja_stats.dart';
import '../character/player_profile.dart';
import '../config/models/app_config.dart';
import '../config/models/character_config.dart';
import '../config/models/clothing_config.dart';
import '../config/models/stats_scaling_config.dart';
import '../ui/character/clothing_panel.dart';

class CharacterCreationScreen extends StatefulWidget {
  const CharacterCreationScreen({
    super.key,
    required this.creation,
    required this.clothing,
    required this.statsScaling,
    required this.style,
    required this.onCreated,
  });

  final CharacterCreationConfig creation;
  final ClothingConfig clothing;
  final StatsScalingConfig statsScaling;
  final MenuStyleConfig style;
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

  OutlinedBorder _getButtonShape() {
    switch (widget.style.buttonShape) {
      case 'stadium':
        return const StadiumBorder();
      case 'rectangular':
        return const RoundedRectangleBorder(borderRadius: BorderRadius.zero);
      case 'rounded':
      default:
        return RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(widget.style.borderRadius),
        );
    }
  }

  Color _getTierColor(String tier) {
    switch (tier) {
      case 'S':
        return Colors.amber;
      case 'A':
        return Colors.purpleAccent;
      case 'B':
        return Colors.blueAccent;
      case 'C':
        return Colors.greenAccent;
      case 'D':
        return Colors.orangeAccent;
      case 'E':
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style;
    final shape = _getButtonShape();
    final totalPoints = (_roll.stats.level - 1) * 20;
    final spentSum = _roll.stats.spentPoints.values.fold(0, (sum, val) => sum + val);
    final unspent = totalPoints - spentSum;

    const spendableStats = [
      'HP',
      'CP',
      'SP',
      'Speed',
      'SpeedReaction',
      'SpeedSeal',
      'ChakraControl',
      'ChakraBuffer',
      'Taijutsu'
    ];

    final statNames = {
      'HP': 'Health Points (HP)',
      'CP': 'Chakra Points (CP)',
      'SP': 'Senjutsu (SP)',
      'Speed': 'Speed',
      'SpeedReaction': 'Speed Reaction',
      'SpeedSeal': 'Speed Seal',
      'ChakraControl': 'Chakra Control',
      'ChakraBuffer': 'Chakra Buffer',
      'Taijutsu': 'Taijutsu (Attack)',
    };

    return Scaffold(
      backgroundColor: style.backgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color.alphaBlend(Colors.white.withOpacity(0.02), style.backgroundColor),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: style.buttonColor.withOpacity(0.2)),
              ),
              child: ListView(
                children: [
                  Text(
                    widget.creation.screenTitle,
                    style: TextStyle(
                      color: style.titleColor,
                      fontSize: style.titleSize,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Basic info card
                  Card(
                    color: Colors.black26,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: widget.creation.labels.name,
                              labelStyle: TextStyle(color: style.buttonColor),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: style.buttonColor.withOpacity(0.5)),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: style.buttonColor),
                              ),
                            ),
                            onChanged: (value) =>
                                _updateRoll(_roll.copyWith(name: value)),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                '${widget.creation.labels.gender}: ',
                                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SegmentedButton<String>(
                                  segments: widget.creation.genderOptions
                                      .map(
                                        (gender) => ButtonSegment(
                                          value: gender,
                                          label: Text(gender, style: const TextStyle(fontSize: 12)),
                                        ),
                                      )
                                      .toList(),
                                  selected: {_roll.gender},
                                  onSelectionChanged: (values) {
                                    _updateRoll(_roll.copyWith(gender: values.first));
                                  },
                                  style: SegmentedButton.styleFrom(
                                    selectedBackgroundColor: style.buttonColor,
                                    selectedForegroundColor: style.buttonTextColor,
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    side: BorderSide(color: style.buttonColor.withOpacity(0.5)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Starting Level: ${_roll.stats.level}',
                                style: TextStyle(
                                  color: style.buttonColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Unspent Points: $unspent / $totalPoints',
                                style: TextStyle(
                                  color: unspent > 0 ? Colors.greenAccent : Colors.white60,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stats Panel
                  Text(
                    'Ninja Stats & Scaling Tiers',
                    style: TextStyle(
                      color: style.titleColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final stat in spendableStats) ...[
                    Builder(
                      builder: (context) {
                        final tier = _roll.stats.scalingTiers[stat] ?? 'B';
                        final spent = _roll.stats.spentPoints[stat] ?? 0;
                        final calculated = _roll.stats.calculate(stat, widget.statsScaling);
                        final base = widget.statsScaling.bases[stat] ?? 0.0;
                        final tierColor = _getTierColor(tier);

                        return Card(
                          color: Colors.black38,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                // Stat details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            statNames[stat] ?? stat,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: tierColor.withOpacity(0.2),
                                              border: Border.all(color: tierColor),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              tier,
                                              style: TextStyle(
                                                color: tierColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Value: $calculated (Base: ${base.toInt()} + $spent pts)',
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Stepper
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: spent > 0
                                          ? () => _changeStat(stat, spent - 1)
                                          : null,
                                      icon: const Icon(Icons.remove, color: Colors.redAccent),
                                    ),
                                    SizedBox(
                                      width: 32,
                                      child: Center(
                                        child: Text(
                                          '$spent',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: unspent > 0
                                          ? () => _changeStat(stat, spent + 1)
                                          : null,
                                      icon: const Icon(Icons.add, color: Colors.greenAccent),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Clothing Panel
                  ClothingPanel(
                    title: widget.creation.labels.clothing,
                    colorTitle: widget.creation.labels.clothingColor,
                    config: widget.clothing,
                    selections: _roll.clothing,
                    selectedColorLabel: _roll.clothingColorLabel,
                    onSlotChanged: _changeClothing,
                    onColorChanged: _changeColor,
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SizedBox(
                        width: style.buttonWidth,
                        height: style.buttonHeight,
                        child: OutlinedButton.icon(
                          onPressed: _reroll,
                          icon: const Icon(Icons.casino),
                          label: Text(widget.creation.rerollLabel),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: style.buttonColor),
                            shape: shape,
                            textStyle: TextStyle(
                              fontSize: style.fontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: style.buttonWidth,
                        height: style.buttonHeight,
                        child: FilledButton(
                          onPressed: unspent == 0 ? _submit : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: style.buttonColor,
                            foregroundColor: style.buttonTextColor,
                            shape: shape,
                            textStyle: TextStyle(
                              fontSize: style.fontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          child: Text(widget.creation.submitLabel),
                        ),
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

  void _changeStat(String stat, int value) {
    final newSpent = Map<String, int>.from(_roll.stats.spentPoints);
    newSpent[stat] = value;

    final newStats = NinjaStats(
      level: _roll.stats.level,
      scalingTiers: _roll.stats.scalingTiers,
      spentPoints: newSpent,
    );

    _updateRoll(_roll.copyWith(stats: newStats));
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
