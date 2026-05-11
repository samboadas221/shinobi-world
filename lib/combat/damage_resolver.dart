import 'dart:math';

import '../config/models/combat_config.dart';
import '../config/models/jutsu_config.dart';
import 'battle_participant.dart';

class DamageResolver {
  const DamageResolver(this.config);

  final DamageConfig config;

  int basicAttackDamage(
    BattleParticipant attacker,
    BattleParticipant defender,
  ) {
    final rawDamage = attacker.attack * config.basicAttackMultiplier;
    final reduction = defender.defense * config.defenseReductionMultiplier;
    return max(config.minimumDamage, (rawDamage - reduction).round());
  }

  int jutsuDamage(JutsuConfig jutsu) {
    return max(config.minimumDamage, jutsu.damage);
  }
}
