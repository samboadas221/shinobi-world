import '../config/models/jutsu_config.dart';

class BattleParticipant {
  BattleParticipant({
    required this.name,
    required this.maxHealth,
    required this.currentHealth,
    required this.maxChakra,
    required this.currentChakra,
    required this.speed,
    required this.attack,
    required this.defense,
    required this.jutsu,
  });

  final String name;
  final int maxHealth;
  int currentHealth;
  final int maxChakra;
  int currentChakra;
  final int speed;
  final int attack;
  final int defense;
  final List<JutsuConfig> jutsu;

  bool get isDefeated => currentHealth <= 0;

  void receiveDamage(int amount) {
    currentHealth = (currentHealth - amount).clamp(0, maxHealth);
  }

  void spendChakra(int amount) {
    currentChakra = (currentChakra - amount).clamp(0, maxChakra);
  }
}
