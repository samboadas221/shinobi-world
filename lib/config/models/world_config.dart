import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:yaml/yaml.dart';

import 'yaml_readers.dart';

class WorldConfig {
  const WorldConfig({
    required this.time,
    required this.villages,
    required this.map,
    required this.encounters,
  });

  final WorldTimeConfig time;
  final List<VillageConfig> villages;
  final WorldMapConfig map;
  final EncounterConfig encounters;
}

class WorldTimeConfig {
  const WorldTimeConfig({
    required this.dayDuration,
    required this.nightDuration,
    required this.startingPhase,
    required this.nightOverlayOpacity,
  });

  factory WorldTimeConfig.fromYaml(YamlMap yaml) {
    final cycle = yaml['cycle'] as YamlMap;
    return WorldTimeConfig(
      dayDuration: readDouble(cycle, 'day_duration_seconds'),
      nightDuration: readDouble(cycle, 'night_duration_seconds'),
      startingPhase: readString(cycle, 'starting_phase'),
      nightOverlayOpacity: readDouble(cycle, 'night_overlay_opacity'),
    );
  }

  final double dayDuration;
  final double nightDuration;
  final String startingPhase;
  final double nightOverlayOpacity;
}

class VillageConfig {
  const VillageConfig({
    required this.id,
    required this.displayName,
    required this.spawnPosition,
  });

  static List<VillageConfig> listFromYaml(YamlMap yaml) {
    final villages = yaml['starting_villages'] as YamlList;
    return villages.cast<YamlMap>().map(VillageConfig.fromYaml).toList();
  }

  factory VillageConfig.fromYaml(YamlMap yaml) {
    final spawn = yaml['spawn_position'] as YamlMap;
    return VillageConfig(
      id: readString(yaml, 'id'),
      displayName: readString(yaml, 'display_name'),
      spawnPosition: Vector2(readDouble(spawn, 'x'), readDouble(spawn, 'y')),
    );
  }

  final String id;
  final String displayName;
  final Vector2 spawnPosition;
}

class WorldMapConfig {
  const WorldMapConfig({
    required this.tileSize,
    required this.cameraZoom,
    required this.bounds,
    required this.visuals,
    required this.layout,
  });

  factory WorldMapConfig.fromYaml(YamlMap yaml) {
    final map = yaml['map'] as YamlMap;
    final bounds = map['bounds'] as YamlMap;
    return WorldMapConfig(
      tileSize: readDouble(map, 'tile_size'),
      cameraZoom: readDouble(map, 'camera_zoom'),
      bounds: Vector2(
        readDouble(bounds, 'width'),
        readDouble(bounds, 'height'),
      ),
      visuals: WorldMapVisualConfig.fromYaml(map['visuals'] as YamlMap),
      layout: WorldMapLayoutConfig.fromYaml(map['layout'] as YamlMap),
    );
  }

  final double tileSize;
  final double cameraZoom;
  final Vector2 bounds;
  final WorldMapVisualConfig visuals;
  final WorldMapLayoutConfig layout;
}

class WorldMapVisualConfig {
  const WorldMapVisualConfig({
    required this.grassColor,
    required this.roadColor,
    required this.buildingColor,
  });

  factory WorldMapVisualConfig.fromYaml(YamlMap yaml) {
    return WorldMapVisualConfig(
      grassColor: readHexColor(yaml, 'grass_color'),
      roadColor: readHexColor(yaml, 'road_color'),
      buildingColor: readHexColor(yaml, 'building_color'),
    );
  }

  final Color grassColor;
  final Color roadColor;
  final Color buildingColor;
}

class WorldMapLayoutConfig {
  const WorldMapLayoutConfig({
    required this.roadLength,
    required this.roadWidth,
    required this.buildingsPerVillage,
    required this.buildingSize,
    required this.buildingScatterRadius,
  });

  factory WorldMapLayoutConfig.fromYaml(YamlMap yaml) {
    return WorldMapLayoutConfig(
      roadLength: readDouble(yaml, 'road_length'),
      roadWidth: readDouble(yaml, 'road_width'),
      buildingsPerVillage: readInt(yaml, 'buildings_per_village'),
      buildingSize: readDouble(yaml, 'building_size'),
      buildingScatterRadius: readDouble(yaml, 'building_scatter_radius'),
    );
  }

  final double roadLength;
  final double roadWidth;
  final int buildingsPerVillage;
  final double buildingSize;
  final double buildingScatterRadius;
}

class EncounterConfig {
  const EncounterConfig({
    required this.collisionStartsCombat,
    required this.collisionPadding,
    required this.retriggerCooldown,
  });

  factory EncounterConfig.fromYaml(YamlMap yaml) {
    final encounters = yaml['encounters'] as YamlMap;
    return EncounterConfig(
      collisionStartsCombat: encounters['collision_starts_combat'] as bool,
      collisionPadding: readDouble(encounters, 'collision_padding'),
      retriggerCooldown: readDouble(encounters, 'retrigger_cooldown_seconds'),
    );
  }

  final bool collisionStartsCombat;
  final double collisionPadding;
  final double retriggerCooldown;
}
