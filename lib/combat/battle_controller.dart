import 'dart:math';

import 'package:flutter/foundation.dart';

import '../config/models/combat_config.dart';
import '../config/models/jutsu_config.dart';
import 'battle_participant.dart';
import 'battle_request.dart';
import 'battle_setup.dart';
import 'damage_resolver.dart';

class BattleController extends ChangeNotifier {
  BattleController({
    required BattleRequest request,
    required CombatConfig config,
  }) : _request = request,
       _damage = DamageResolver(config.damage, request.jutsuAffinities) {
    final setup = BattleSetup(request);
    player = setup.player();
    enemy = setup.enemy();
    turnOrder = [player, enemy]..sort((a, b) => b.speed.compareTo(a.speed));
    _logs.add(config.ui.initialLog);
    // If the enemy is faster they act first. Resolve their turn immediately
    // so the player always opens the screen on THEIR own turn.
    if (currentActor.name == enemy.name) {
      _enemyAct();
    }
  }

  final BattleRequest _request;
  final DamageResolver _damage;
  final Random _random = Random();
  final List<String> _logs = [];
  var _turnIndex = 0;
  final List<String> castedJutsuIds = [];

  late final BattleParticipant player;
  late final BattleParticipant enemy;
  late final List<BattleParticipant> turnOrder;

  List<String> get logs => List.unmodifiable(_logs.reversed.take(6));
  BattleParticipant get currentActor => turnOrder[_turnIndex];
  bool get isPlayerTurn => currentActor.name == player.name && !isBattleOver;
  bool get isBattleOver => player.isDefeated || enemy.isDefeated;

  void playerAttack() {
    if (!isPlayerTurn) return;
    _attack(player, enemy);
    _finishPlayerTurn();
  }

  void playerUseJutsu(JutsuConfig jutsu) {
    final cost = playerJutsuCost(jutsu);
    if (!isPlayerTurn || player.currentChakra < cost) return;
    castedJutsuIds.add(jutsu.id);
    _useJutsu(player, enemy, jutsu, chakraCost: cost);
    _finishPlayerTurn();
  }

  int playerJutsuCost(JutsuConfig jutsu) {
    if (jutsu.chakraNature != _request.playerSecondaryNature) {
      return jutsu.chakraCost;
    }
    return (jutsu.chakraCost * _request.secondaryCostMultiplier).ceil();
  }

  void _finishPlayerTurn() {
    _advanceTurn();
    if (!isBattleOver) _enemyAct();
    notifyListeners();
  }

  void _enemyAct() {
    if (currentActor.name != enemy.name) return;
    // Tick effects at the start of the enemy's turn.
    enemy.tickEffects();
    player.tickEffects();
    final jutsu = _chooseEnemyJutsu();
    if (jutsu == null) {
      _attack(enemy, player);
    } else {
      _useJutsu(enemy, player, jutsu, chakraCost: jutsu.chakraCost);
    }
    _advanceTurn();
  }

  JutsuConfig? _chooseEnemyJutsu() {
    final affordable = enemy.jutsu
        .where((j) => j.chakraCost <= enemy.currentChakra)
        .toList();
    if (affordable.isEmpty) return null;
    final shouldUse = _random.nextDouble() <= _request.enemy.ai.jutsuPreference;
    if (!shouldUse) return null;
    return affordable[_random.nextInt(affordable.length)];
  }

  void _attack(BattleParticipant attacker, BattleParticipant defender) {
    final damage = _damage.basicAttackDamage(attacker, defender);
    defender.receiveDamage(damage);
    _logs.add('${attacker.name} attacks for $damage damage.');
    _logBattleEnd();
  }

  void _useJutsu(
    BattleParticipant attacker,
    BattleParticipant defender,
    JutsuConfig jutsu, {
    required int chakraCost,
  }) {
    attacker.spendChakra(chakraCost);

    // Damage (may be 0 for support jutsus).
    final isPlayerCasting = attacker.name == player.name;
    final primary = isPlayerCasting
        ? _request.playerChakraNature
        : _request.enemy.id; // enemies use neutral
    final secondary = isPlayerCasting ? _request.playerSecondaryNature : '';

    if (jutsu.damage > 0) {
      final damage = _damage.jutsuDamage(
        jutsu,
        casterPrimary: primary,
        casterSecondary: secondary,
        defender: defender,
      );
      defender.receiveDamage(damage);
      _logs.add(
        '${attacker.name} uses ${jutsu.displayName} for $damage damage.',
      );
    } else {
      _logs.add('${attacker.name} uses ${jutsu.displayName}.');
    }

    // Apply effects.
    for (final effect in jutsu.effects) {
      if (effect.targetsSelf) {
        attacker.applyEffect(effect);
        _logs.add(_describeEffect(attacker.name, effect));
      } else {
        defender.applyEffect(effect);
        _logs.add(_describeEffect(defender.name, effect));
      }
    }

    _logBattleEnd();
  }

  String _describeEffect(String targetName, JutsuEffect effect) {
    switch (effect.type) {
      case JutsuEffectType.armorBuff:
        return '$targetName gained +${effect.value.round()} armor.';
      case JutsuEffectType.speedBuff:
        return '$targetName gained +${effect.value.round()} speed.';
      case JutsuEffectType.healHp:
        return '$targetName recovered ${effect.value.round()} HP.';
      case JutsuEffectType.healChakra:
        return '$targetName recovered ${effect.value.round()} chakra.';
      case JutsuEffectType.enemyArmorDebuff:
        return '$targetName lost ${effect.value.abs().round()} armor.';
      case JutsuEffectType.enemySpeedDebuff:
        return '$targetName lost ${effect.value.abs().round()} speed.';
    }
  }

  void _advanceTurn() {
    _turnIndex = (_turnIndex + 1) % turnOrder.length;
  }

  void _logBattleEnd() {
    if (enemy.isDefeated) _logs.add('${enemy.name} is defeated!');
    if (player.isDefeated) _logs.add('${player.name} is defeated!');
  }
}
