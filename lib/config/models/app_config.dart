import 'package:flutter/material.dart';
import 'package:yaml/yaml.dart';

import 'yaml_readers.dart';

class AppConfig {
  const AppConfig({required this.brand, required this.menu});

  factory AppConfig.fromYaml(YamlMap yaml) {
    return AppConfig(
      brand: BrandConfig.fromYaml(yaml['brand'] as YamlMap),
      menu: MainMenuConfig.fromYaml(yaml['menu'] as YamlMap),
    );
  }

  final BrandConfig brand;
  final MainMenuConfig menu;
}

class BrandConfig {
  const BrandConfig({
    required this.appTitle,
    required this.companyName,
    required this.logoAsset,
    required this.splashDuration,
    required this.themeSeedColor,
  });

  factory BrandConfig.fromYaml(YamlMap yaml) {
    return BrandConfig(
      appTitle: readString(yaml, 'app_title'),
      companyName: readString(yaml, 'company_name'),
      logoAsset: readString(yaml, 'logo_asset'),
      splashDuration: readDouble(yaml, 'splash_duration_seconds'),
      themeSeedColor: readHexColor(yaml, 'theme_seed_color'),
    );
  }

  final String appTitle;
  final String companyName;
  final String logoAsset;
  final double splashDuration;
  final Color themeSeedColor;
}

class MainMenuConfig {
  const MainMenuConfig({
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.settingsMessage,
    required this.exitMessage,
  });

  factory MainMenuConfig.fromYaml(YamlMap yaml) {
    final actions = yaml['actions'] as YamlMap;
    return MainMenuConfig(
      title: readString(yaml, 'title'),
      subtitle: readString(yaml, 'subtitle'),
      actions: {
        for (final entry in actions.entries)
          entry.key as String: entry.value as String,
      },
      settingsMessage: readString(yaml, 'settings_message'),
      exitMessage: readString(yaml, 'exit_message'),
    );
  }

  final String title;
  final String subtitle;
  final Map<String, String> actions;
  final String settingsMessage;
  final String exitMessage;
}
