import 'package:flutter/material.dart';
import 'package:yaml/yaml.dart';

import 'yaml_readers.dart';

class VisualConfig {
  const VisualConfig({required this.bodyColor, required this.headbandColor});

  factory VisualConfig.fromYaml(YamlMap yaml) {
    return VisualConfig(
      bodyColor: readHexColor(yaml, 'body_color'),
      headbandColor: readHexColor(yaml, 'headband_color'),
    );
  }

  final Color bodyColor;
  final Color headbandColor;
}
