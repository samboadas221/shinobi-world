import 'dart:math';

import '../config/models/combat_config.dart';
import '../config/models/jutsu_config.dart';
import '../config/models/jutsu_affinity_config.dart';
import 'battle_participant.dart';

class DamageResolver {
  const DamageResolver(this.config, this.affinities);

  final DamageConfig config;
  final JutsuAffinityConfig affinities;

  int basicAttackDamage(
    BattleParticipant attacker,
    BattleParticipant defender,
  ) {
    final rawDamage = attacker.attack * config.basicAttackMultiplier;
    final reduction = defender.defense * config.defenseReductionMultiplier;
    return max(config.minimumDamage, (rawDamage - reduction).round());
  }

  int jutsuDamage(
    JutsuConfig jutsu, {
    required String casterPrimary,
    required String casterSecondary,
    BattleParticipant? defender,
  }) {
    final affinityMult = affinities.multiplierFor(
      jutsuNature: jutsu.chakraNature,
      casterPrimary: casterPrimary,
      casterSecondary: casterSecondary,
    );
    final baseDamage = (jutsu.damage * affinityMult).round();
    if (defender != null) {
      final reduction = defender.defense * config.defenseReductionMultiplier;
      return max(config.minimumDamage, (baseDamage - reduction).round());
    }
    return max(config.minimumDamage, baseDamage);
  }
}
