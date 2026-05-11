import 'package:flutter/material.dart';
import 'package:yaml/yaml.dart';

import 'yaml_readers.dart';

class ClothingConfig {
  const ClothingConfig({required this.slots, required this.colors});

  factory ClothingConfig.fromYaml(YamlMap yaml) {
    final clothing = yaml['clothing'] as YamlMap;
    final slots = clothing['slots'] as YamlMap;
    final colors = clothing['colors'] as YamlList;
    return ClothingConfig(
      slots: {
        for (final entry in slots.entries)
          entry.key as String: ClothingSlotConfig.fromYaml(
            entry.value as YamlMap,
          ),
      },
      colors: colors.cast<YamlMap>().map(ClothingColorConfig.fromYaml).toList(),
    );
  }

  final Map<String, ClothingSlotConfig> slots;
  final List<ClothingColorConfig> colors;
}

class ClothingSlotConfig {
  const ClothingSlotConfig({required this.label, required this.options});

  factory ClothingSlotConfig.fromYaml(YamlMap yaml) {
    return ClothingSlotConfig(
      label: readString(yaml, 'label'),
      options: readStringList(yaml, 'options'),
    );
  }

  final String label;
  final List<String> options;
}

class ClothingColorConfig {
  const ClothingColorConfig({required this.label, required this.value});

  factory ClothingColorConfig.fromYaml(YamlMap yaml) {
    return ClothingColorConfig(
      label: readString(yaml, 'label'),
      value: readHexColor(yaml, 'value'),
    );
  }

  final String label;
  final Color value;
}
