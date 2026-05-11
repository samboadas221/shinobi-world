import '../config/models/combat_config.dart';

class TurnPreview {
  const TurnPreview(this.config);

  final TurnConfig config;

  List<String> orderedNames() {
    final participants = [...config.previewParticipants];
    participants.sort((a, b) => b.speed.compareTo(a.speed));
    return participants.map((participant) => participant.displayName).toList();
  }
}
