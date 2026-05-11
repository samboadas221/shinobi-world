import 'package:yaml/yaml.dart';

import 'yaml_readers.dart';

class CountRange {
  const CountRange({required this.min, required this.max});

  factory CountRange.fromYaml(YamlMap yaml) {
    return CountRange(min: readInt(yaml, 'min'), max: readInt(yaml, 'max'));
  }

  final int min;
  final int max;
}
