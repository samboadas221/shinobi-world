import 'dart:math';

import '../config/models/character_config.dart';
import '../config/models/clothing_config.dart';
import 'character_roll.dart';

class CharacterGenerator {
  CharacterGenerator({
    required this.creation,
    required this.clothing,
    Random? random,
  }) : _random = random ?? Random();

  final CharacterCreationConfig creation;
  final ClothingConfig clothing;
  final Random _random;

  CharacterRoll roll() {
    final natures = [...creation.naturalNatures]..shuffle(_random);
    return CharacterRoll(
      name: _pick(creation.namePool),
      gender: _pick(creation.genderOptions),
      naturalNature: natures.first,
      secondaryNature: natures[1],
      totalPoints: _rollRange(creation.pointRoll.min, creation.pointRoll.max),
      spentPoints: {
        for (final ability in creation.ability.labels.keys) ability: 0,
      },
      clothing: {
        for (final entry in clothing.slots.entries)
          entry.key: _pick(entry.value.options),
      },
      clothingColorLabel: clothing.colors.first.label,
    );
  }

  String _pick(List<String> values) {
    return values[_random.nextInt(values.length)];
  }

  int _rollRange(int min, int max) {
    return min + _random.nextInt(max - min + 1);
  }
}
