import 'package:flutter/material.dart';
import 'package:yaml/yaml.dart';

double readDouble(YamlMap yaml, String key) => (yaml[key] as num).toDouble();

int readInt(YamlMap yaml, String key) => (yaml[key] as num).toInt();

String readString(YamlMap yaml, String key) => yaml[key] as String;

List<String> readStringList(YamlMap yaml, String key) {
  return (yaml[key] as YamlList).cast<String>();
}

Map<String, int> readIntMap(YamlMap yaml, String key) {
  final source = yaml[key] as YamlMap;
  return {
    for (final entry in source.entries)
      entry.key as String: (entry.value as num).toInt(),
  };
}

Color readHexColor(YamlMap yaml, String key) {
  final value = readString(yaml, key).replaceFirst('#', '');
  return Color(int.parse('FF$value', radix: 16));
}
