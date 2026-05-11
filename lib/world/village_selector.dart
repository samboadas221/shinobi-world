import 'dart:math';

import '../config/models/world_config.dart';

class VillageSelector {
  const VillageSelector(this._random);

  final Random _random;

  VillageConfig choose(List<VillageConfig> villages) {
    return villages[_random.nextInt(villages.length)];
  }
}
