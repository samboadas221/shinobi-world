import 'dart:math';

import '../character/player_profile.dart';
import '../config/models/jutsu_config.dart';
import '../config/models/player_config.dart';
import '../config/models/world_rules_config.dart';
import '../game/demo_state.dart';

class OverworldPracticeController {
  OverworldPracticeController({
    required this.player,
    required this.training,
    required this.profile,
    required this.jutsu,
  }) : currentChakra = player.maxChakra;

  final PlayerConfig player;
  final TrainingConfig training;
  final PlayerProfile profile;
  final List<JutsuConfig> jutsu;
  final Map<String, int> _jutsuExp = {};

  int currentChakra;
  double _regenElapsed = 0;
  String practiceLog = '';

  String? practiceJutsu(String jutsuId) {
    final selected = jutsu.firstWhere((item) => item.id == jutsuId);
    final cost = practiceCost(selected);
    if (currentChakra < cost) {
      return null;
    }
    currentChakra -= cost;
    _jutsuExp[selected.id] =
        (_jutsuExp[selected.id] ?? 0) + training.jutsuExpPerCast;
    practiceLog = '${selected.displayName} practiced';
    return selected.displayName;
  }

  void regen(double dt) {
    if (currentChakra >= player.maxChakra) {
      return;
    }
    _regenElapsed += dt;
    if (_regenElapsed < training.chakraRegenIntervalSeconds) {
      return;
    }
    _regenElapsed = 0;
    currentChakra = (currentChakra + training.chakraRegenPerTick).clamp(
      0,
      player.maxChakra,
    );
  }

  List<JutsuPracticeState> practiceStates() {
    return jutsu.map((selected) {
      final exp = _jutsuExp[selected.id] ?? 0;
      final level = 1 + exp ~/ training.sealReductionLevelInterval;
      final seals = selected.handSeals.length - (level - 1);
      return JutsuPracticeState(
        id: selected.id,
        name: selected.displayName,
        cost: practiceCost(selected),
        level: level,
        requiredSeals: max(training.minimumRequiredSeals, seals),
      );
    }).toList();
  }

  int practiceCost(JutsuConfig selected) {
    var cost = selected.chakraCost * training.chakraPracticeCostMultiplier;
    if (selected.chakraNature == profile.secondaryNature) {
      cost *= profile.secondaryChakraCostMultiplier;
    }
    return cost.ceil();
  }
}
