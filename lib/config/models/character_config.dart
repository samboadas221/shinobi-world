import 'package:yaml/yaml.dart';

import 'count_range.dart';
import 'yaml_readers.dart';

class CharacterCreationConfig {
  const CharacterCreationConfig({
    required this.defaultName,
    required this.screenTitle,
    required this.namePool,
    required this.genderOptions,
    required this.pointRoll,
    required this.naturalNatures,
    required this.secondaryCostMultiplier,
    required this.ability,
    required this.rerollLabel,
    required this.rerollIconName,
    required this.submitLabel,
    required this.labels,
  });

  factory CharacterCreationConfig.fromYaml(YamlMap yaml) {
    final creation = yaml['creation'] as YamlMap;
    final secondary = creation['secondary_affinity'] as YamlMap;
    final reroll = creation['reroll'] as YamlMap;
    return CharacterCreationConfig(
      defaultName: readString(creation, 'default_name'),
      screenTitle: readString(creation, 'screen_title'),
      namePool: readStringList(creation, 'name_pool'),
      genderOptions: readStringList(creation, 'gender_options'),
      pointRoll: CountRange.fromYaml(creation['point_roll'] as YamlMap),
      naturalNatures: readStringList(creation, 'natural_natures'),
      secondaryCostMultiplier: readDouble(secondary, 'chakra_cost_multiplier'),
      ability: AbilityPointConfig.fromYaml(
        creation['ability_points'] as YamlMap,
      ),
      rerollLabel: readString(reroll, 'label'),
      rerollIconName: readString(reroll, 'icon_name'),
      submitLabel: readString(creation, 'submit_label'),
      labels: CharacterUiLabels.fromYaml(creation['ui_labels'] as YamlMap),
    );
  }

  final String defaultName;
  final String screenTitle;
  final List<String> namePool;
  final List<String> genderOptions;
  final CountRange pointRoll;
  final List<String> naturalNatures;
  final double secondaryCostMultiplier;
  final AbilityPointConfig ability;
  final String rerollLabel;
  final String rerollIconName;
  final String submitLabel;
  final CharacterUiLabels labels;
}

class CharacterUiLabels {
  const CharacterUiLabels({
    required this.name,
    required this.gender,
    required this.naturalNature,
    required this.secondaryAffinity,
    required this.unspentPoints,
    required this.abilityPoints,
    required this.clothing,
    required this.clothingColor,
  });

  factory CharacterUiLabels.fromYaml(YamlMap yaml) {
    return CharacterUiLabels(
      name: readString(yaml, 'name'),
      gender: readString(yaml, 'gender'),
      naturalNature: readString(yaml, 'natural_nature'),
      secondaryAffinity: readString(yaml, 'secondary_affinity'),
      unspentPoints: readString(yaml, 'unspent_points'),
      abilityPoints: readString(yaml, 'ability_points'),
      clothing: readString(yaml, 'clothing'),
      clothingColor: readString(yaml, 'clothing_color'),
    );
  }

  final String name;
  final String gender;
  final String naturalNature;
  final String secondaryAffinity;
  final String unspentPoints;
  final String abilityPoints;
  final String clothing;
  final String clothingColor;
}

class AbilityPointConfig {
  const AbilityPointConfig({
    required this.minValue,
    required this.maxValue,
    required this.labels,
  });

  factory AbilityPointConfig.fromYaml(YamlMap yaml) {
    final abilities = yaml['abilities'] as YamlMap;
    return AbilityPointConfig(
      minValue: readInt(yaml, 'min_value'),
      maxValue: readInt(yaml, 'max_value'),
      labels: {
        for (final entry in abilities.entries)
          entry.key as String: readString(entry.value as YamlMap, 'label'),
      },
    );
  }

  final int minValue;
  final int maxValue;
  final Map<String, String> labels;
}
