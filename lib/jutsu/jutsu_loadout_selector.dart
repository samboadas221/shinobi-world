import 'dart:math';

import '../config/models/count_range.dart';
import '../config/models/enemy_config.dart';
import '../config/models/jutsu_config.dart';
import '../config/models/player_config.dart';

class JutsuLoadoutSelector {
  const JutsuLoadoutSelector(this._random);

  final Random _random;

  String choosePlayerNature(PlayerConfig config) {
    return config.chakraNaturePool[_random.nextInt(
      config.chakraNaturePool.length,
    )];
  }

  List<JutsuConfig> choosePlayerJutsu({
    required PlayerConfig config,
    required List<JutsuConfig> allJutsu,
    required String chakraNature,
    String? secondaryNature,
  }) {
    final pool = _jutsuByIds(allJutsu, config.starterJutsuPool)
        .where(
          (jutsu) =>
              jutsu.chakraNature == chakraNature ||
              jutsu.chakraNature == secondaryNature,
        )
        .toList();
    return _choose(pool, config.startingJutsuCount);
  }

  List<JutsuConfig> chooseEnemyJutsu({
    required EnemyConfig config,
    required List<JutsuConfig> allJutsu,
  }) {
    return _choose(
      _jutsuByIds(allJutsu, config.usableJutsuPool),
      config.jutsuCount,
    );
  }

  List<JutsuConfig> _jutsuByIds(List<JutsuConfig> allJutsu, List<String> ids) {
    final byId = {for (final jutsu in allJutsu) jutsu.id: jutsu};
    return ids.map((id) => byId[id]).whereType<JutsuConfig>().toList();
  }

  List<JutsuConfig> _choose(List<JutsuConfig> pool, CountRange range) {
    final options = [...pool]..shuffle(_random);
    final minCount = min(range.min, options.length);
    final maxCount = min(max(range.max, minCount), options.length);
    final count = minCount + _random.nextInt(maxCount - minCount + 1);
    return options.take(count).toList();
  }
}
