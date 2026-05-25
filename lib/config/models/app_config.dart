import 'package:flutter/material.dart';
import 'package:yaml/yaml.dart';

import 'yaml_readers.dart';

class AppConfig {
  const AppConfig({
    required this.brand,
    required this.menu,
    required this.mainMenuStyle,
    required this.characterMenuStyle,
  });

  factory AppConfig.fromYaml(YamlMap yaml) {
    return AppConfig(
      brand: BrandConfig.fromYaml(yaml['brand'] as YamlMap),
      menu: MainMenuConfig.fromYaml(yaml['menu'] as YamlMap),
      mainMenuStyle: MenuStyleConfig.fromYaml(yaml['main_menu_style'] as YamlMap),
      characterMenuStyle: MenuStyleConfig.fromYaml(yaml['character_menu_style'] as YamlMap),
    );
  }

  final BrandConfig brand;
  final MainMenuConfig menu;
  final MenuStyleConfig mainMenuStyle;
  final MenuStyleConfig characterMenuStyle;
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

class MenuStyleConfig {
  const MenuStyleConfig({
    required this.buttonColor,
    required this.buttonTextColor,
    required this.buttonWidth,
    required this.buttonHeight,
    required this.spacing,
    required this.borderRadius,
    required this.fontSize,
    required this.buttonShape,
    required this.backgroundColor,
    required this.titleColor,
    required this.titleSize,
  });

  factory MenuStyleConfig.fromYaml(YamlMap yaml) {
    return MenuStyleConfig(
      buttonColor: readHexColor(yaml, 'button_color'),
      buttonTextColor: readHexColor(yaml, 'button_text_color'),
      buttonWidth: readDouble(yaml, 'button_width'),
      buttonHeight: readDouble(yaml, 'button_height'),
      spacing: readDouble(yaml, 'spacing'),
      borderRadius: readDouble(yaml, 'border_radius'),
      fontSize: readDouble(yaml, 'font_size'),
      buttonShape: readString(yaml, 'button_shape'),
      backgroundColor: readHexColor(yaml, 'background_color'),
      titleColor: readHexColor(yaml, 'title_color'),
      titleSize: readDouble(yaml, 'title_size'),
    );
  }

  final Color buttonColor;
  final Color buttonTextColor;
  final double buttonWidth;
  final double buttonHeight;
  final double spacing;
  final double borderRadius;
  final double fontSize;
  final String buttonShape;
  final Color backgroundColor;
  final Color titleColor;
  final double titleSize;
}
