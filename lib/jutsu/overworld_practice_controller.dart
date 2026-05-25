import 'dart:math';

import '../character/player_profile.dart';
import '../config/models/jutsu_config.dart';
import '../config/models/world_rules_config.dart';
import '../config/models/stats_scaling_config.dart';
import '../config/models/jutsu_progression_config.dart';
import '../data/shinobi_database.dart';
import '../game/demo_state.dart';

class OverworldPracticeController {
  OverworldPracticeController({
    required this.training,
    required this.profile,
    required this.jutsu,
    required this.statsScaling,
    required this.jutsuProgression,
  }) {
    maxChakra = profile.stats.calculate('CP', statsScaling);
    currentChakra = maxChakra;
  }

  final TrainingConfig training;
  final PlayerProfile profile;
  final List<JutsuConfig> jutsu;
  final StatsScalingConfig statsScaling;
  final JutsuProgressionConfig jutsuProgression;

  late int maxChakra;
  int currentChakra = 0;
  double _regenElapsed = 0;
  String practiceLog = '';

  final Map<String, int> _jutsuLevels = {};
  final Map<String, int> _jutsuExp = {};

  void initJutsuProgress(List<Map<String, dynamic>> progressList) {
    for (final progress in progressList) {
      final id = progress['jutsu_id'] as String;
      final lvl = progress['level'] as int;
      final xp = progress['exp'] as int;
      _jutsuLevels[id] = lvl;
      _jutsuExp[id] = xp;
    }
  }

  int getJutsuLevel(String jutsuId) => _jutsuLevels[jutsuId] ?? 1;
  int getJutsuExp(String jutsuId) => _jutsuExp[jutsuId] ?? 0;

  String? practiceJutsu(String jutsuId, {required int seed, required ShinobiDatabase database}) {
    final selected = jutsu.firstWhere((item) => item.id == jutsuId);
    final cost = practiceCost(selected);

    // Buffer check: player cannot execute if cost > player buffer
    final buffer = profile.stats.calculate('ChakraBuffer', statsScaling);
    if (cost > buffer) {
      practiceLog = 'Cast failed: chakra cost ($cost) exceeds Chakra Buffer ($buffer)';
      return null;
    }

    if (currentChakra < cost) {
      practiceLog = 'Cast failed: insufficient chakra';
      return null;
    }

    currentChakra -= cost;

    final currentLvl = getJutsuLevel(selected.id);
    final currentExp = getJutsuExp(selected.id);
    final maxLvl = jutsuProgression.maxLevels[selected.id] ?? 5;

    if (currentLvl >= maxLvl) {
      practiceLog = '${selected.displayName} practiced (Max Level)';
    } else {
      final newExp = currentExp + jutsuProgression.expPerUse;
      if (newExp >= jutsuProgression.expToNextLevel) {
        final nextLvl = currentLvl + 1;
        _jutsuLevels[selected.id] = nextLvl;
        _jutsuExp[selected.id] = newExp - jutsuProgression.expToNextLevel;
        practiceLog = '${selected.displayName} LEVELED UP to Level $nextLvl!';
        database.savePlayerJutsu(
          seed: seed,
          jutsuId: selected.id,
          level: nextLvl,
          exp: _jutsuExp[selected.id]!,
        );
      } else {
        _jutsuExp[selected.id] = newExp;
        practiceLog = '${selected.displayName} practiced (+${jutsuProgression.expPerUse} EXP)';
        database.savePlayerJutsu(
          seed: seed,
          jutsuId: selected.id,
          level: currentLvl,
          exp: newExp,
        );
      }
    }
    return selected.displayName;
  }

  void awardJutsuBattleExp(String jutsuId, {required int seed, required ShinobiDatabase database}) {
    final selectedList = jutsu.where((item) => item.id == jutsuId);
    if (selectedList.isEmpty) return;
    final selected = selectedList.first;

    final currentLvl = getJutsuLevel(selected.id);
    final currentExp = getJutsuExp(selected.id);
    final maxLvl = jutsuProgression.maxLevels[selected.id] ?? 5;

    if (currentLvl >= maxLvl) return;

    final newExp = currentExp + jutsuProgression.expPerUse;
    if (newExp >= jutsuProgression.expToNextLevel) {
      final nextLvl = currentLvl + 1;
      _jutsuLevels[selected.id] = nextLvl;
      _jutsuExp[selected.id] = newExp - jutsuProgression.expToNextLevel;
      database.savePlayerJutsu(
        seed: seed,
        jutsuId: selected.id,
        level: nextLvl,
        exp: _jutsuExp[selected.id]!,
      );
    } else {
      _jutsuExp[selected.id] = newExp;
      database.savePlayerJutsu(
        seed: seed,
        jutsuId: selected.id,
        level: currentLvl,
        exp: newExp,
      );
    }
  }

  void regen(double dt) {
    if (currentChakra >= maxChakra) {
      return;
    }
    _regenElapsed += dt;
    if (_regenElapsed < training.chakraRegenIntervalSeconds) {
      return;
    }
    _regenElapsed = 0;
    currentChakra = (currentChakra + training.chakraRegenPerTick).clamp(
      0,
      maxChakra,
    );
  }

  List<JutsuPracticeState> practiceStates() {
    return jutsu.map((selected) {
      final lvl = getJutsuLevel(selected.id);
      final reductionSeals = (lvl - 1) * jutsuProgression.handSealsReduction;
      final seals = selected.handSeals.length - reductionSeals;
      return JutsuPracticeState(
        id: selected.id,
        name: selected.displayName,
        cost: practiceCost(selected),
        level: lvl,
        requiredSeals: max(training.minimumRequiredSeals, seals),
      );
    }).toList();
  }

  int practiceCost(JutsuConfig selected) {
    final lvl = getJutsuLevel(selected.id);
    final discount = (lvl - 1) * jutsuProgression.chakraReductionPercent;
    final baseCost = max(0.0, selected.chakraCost * (1.0 - discount));

    var cost = baseCost * training.chakraPracticeCostMultiplier;
    if (selected.chakraNature == profile.secondaryNature) {
      cost *= profile.secondaryChakraCostMultiplier;
    }
    return cost.ceil();
  }
}
