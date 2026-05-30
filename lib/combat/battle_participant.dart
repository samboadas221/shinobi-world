import '../config/models/jutsu_config.dart';

/// A single active effect applied to a participant during combat.
class ActiveEffect {
  ActiveEffect({required this.effect, required this.turnsRemaining});

  final JutsuEffect effect;
  int turnsRemaining;
}

/// Represents one side of a combat (player or enemy) with mutable state.
class BattleParticipant {
  BattleParticipant({
    required this.name,
    required this.maxHealth,
    required this.currentHealth,
    required this.maxChakra,
    required this.currentChakra,
    required int baseSpeed,
    required int baseAttack,
    required int baseDefense,
    required this.jutsu,
  }) : speed = baseSpeed,
       attack = baseAttack,
       defense = baseDefense;

  final String name;
  final int maxHealth;
  int currentHealth;
  final int maxChakra;
  int currentChakra;
  final List<JutsuConfig> jutsu;

  // Effective (post-buff) stats — mutated by effects.
  int speed;
  int attack;
  int defense;

  final List<ActiveEffect> _activeEffects = [];
  List<ActiveEffect> get activeEffects => List.unmodifiable(_activeEffects);

  bool get isDefeated => currentHealth <= 0;

  void receiveDamage(int amount) {
    currentHealth = (currentHealth - amount).clamp(0, maxHealth);
  }

  void spendChakra(int amount) {
    currentChakra = (currentChakra - amount).clamp(0, maxChakra);
  }

  void restoreHealth(int amount) {
    currentHealth = (currentHealth + amount).clamp(0, maxHealth);
  }

  void restoreChakra(int amount) {
    currentChakra = (currentChakra + amount).clamp(0, maxChakra);
  }

  /// Applies a jutsu effect to this participant.
  void applyEffect(JutsuEffect effect) {
    if (effect.isInstant) {
      _applyInstant(effect);
    } else {
      _applyBuff(effect);
    }
  }

  /// Called at the start of each turn: ticks down durations,
  /// removes expired effects and reverts their stat changes.
  void tickEffects() {
    final expired = <ActiveEffect>[];
    for (final active in _activeEffects) {
      active.turnsRemaining--;
      if (active.turnsRemaining <= 0) expired.add(active);
    }
    for (final e in expired) {
      _revertBuff(e.effect);
      _activeEffects.remove(e);
    }
  }

  void _applyInstant(JutsuEffect effect) {
    switch (effect.type) {
      case JutsuEffectType.healHp:
        restoreHealth(effect.value.round());
      case JutsuEffectType.healChakra:
        restoreChakra(effect.value.round());
      default:
        break;
    }
  }

  void _applyBuff(JutsuEffect effect) {
    _activeEffects.add(
      ActiveEffect(effect: effect, turnsRemaining: effect.durationTurns),
    );
    switch (effect.type) {
      case JutsuEffectType.armorBuff:
        defense += effect.value.round();
      case JutsuEffectType.speedBuff:
        speed += effect.value.round();
      case JutsuEffectType.enemyArmorDebuff:
        defense = (defense + effect.value).round().clamp(0, 99999);
      case JutsuEffectType.enemySpeedDebuff:
        speed = (speed + effect.value).round().clamp(1, 99999);
      default:
        break;
    }
  }

  void _revertBuff(JutsuEffect effect) {
    switch (effect.type) {
      case JutsuEffectType.armorBuff:
        defense = (defense - effect.value.round()).clamp(0, 99999);
      case JutsuEffectType.speedBuff:
        speed = (speed - effect.value.round()).clamp(1, 99999);
      case JutsuEffectType.enemyArmorDebuff:
        defense = (defense - effect.value).round().clamp(0, 99999);
      case JutsuEffectType.enemySpeedDebuff:
        speed = (speed - effect.value).round().clamp(1, 99999);
      default:
        break;
    }
  }
}
