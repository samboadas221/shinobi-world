import '../config/models/combat_config.dart';

class ReactionSequence {
  const ReactionSequence(this.config);

  final ReactionConfig config;

  List<String> buildPreviewSequence() {
    return config.buttonPool.take(config.buttonCount).toList();
  }
}
