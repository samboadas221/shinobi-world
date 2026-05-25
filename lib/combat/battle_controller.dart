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
       _damage = DamageResolver(config.damage) {
    final setup = BattleSetup(request);
    player = setup.player();
    enemy = setup.enemy();
    turnOrder = [player, enemy]..sort((a, b) => b.speed.compareTo(a.speed));
    _logs.add(config.ui.initialLog);
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

  List<String> get logs => List.unmodifiable(_logs.reversed.take(5));
  BattleParticipant get currentActor => turnOrder[_turnIndex];
  bool get isPlayerTurn => currentActor.name == player.name && !isBattleOver;
  bool get isBattleOver => player.isDefeated || enemy.isDefeated;

  void playerAttack() {
    if (!isPlayerTurn) {
      return;
    }
    _attack(player, enemy);
    _finishPlayerTurn();
  }

  void playerUseJutsu(JutsuConfig jutsu) {
    final cost = playerJutsuCost(jutsu);
    if (!isPlayerTurn || player.currentChakra < cost) {
      return;
    }
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
    if (!isBattleOver) {
      _enemyAct();
    }
    notifyListeners();
  }

  void _enemyAct() {
    if (currentActor.name != enemy.name) {
      return;
    }
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
        .where((jutsu) => jutsu.chakraCost <= enemy.currentChakra)
        .toList();
    if (affordable.isEmpty) {
      return null;
    }
    final shouldUseJutsu =
        _random.nextDouble() <= _request.enemy.ai.jutsuPreference;
    if (!shouldUseJutsu) {
      return null;
    }
    return affordable[_random.nextInt(affordable.length)];
  }

  void _attack(BattleParticipant attacker, BattleParticipant defender) {
    final damage = _damage.basicAttackDamage(attacker, defender);
    defender.receiveDamage(damage);
    _logs.add('${attacker.name} attacks ${defender.name} for $damage damage.');
    _logBattleEnd();
  }

  void _useJutsu(
    BattleParticipant attacker,
    BattleParticipant defender,
    JutsuConfig jutsu, {
    required int chakraCost,
  }) {
    attacker.spendChakra(chakraCost);
    final damage = _damage.jutsuDamage(jutsu);
    defender.receiveDamage(damage);
    _logs.add('${attacker.name} uses ${jutsu.displayName} for $damage damage.');
    _logBattleEnd();
  }

  void _advanceTurn() {
    _turnIndex = (_turnIndex + 1) % turnOrder.length;
  }

  void _logBattleEnd() {
    if (enemy.isDefeated) {
      _logs.add('${enemy.name} is defeated.');
    }
    if (player.isDefeated) {
      _logs.add('${player.name} is defeated.');
    }
  }
}
