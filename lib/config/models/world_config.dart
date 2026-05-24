import 'dart:math';

import 'package:flutter/material.dart';
import 'package:yaml/yaml.dart';

import 'yaml_readers.dart';

// ── WorldConfig ───────────────────────────────────────────────────────────────

class WorldConfig {
  const WorldConfig({
    required this.time,
    required this.map,
  });

  final WorldTimeConfig time;
  final WorldMapConfig map;
}

// ── WorldTimeConfig ───────────────────────────────────────────────────────────

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

// ── WorldMapConfig ────────────────────────────────────────────────────────────

class WorldMapConfig {
  const WorldMapConfig({
    required this.tileSize,
    required this.cameraZoom,
    required this.mapSizeTiles,
    required this.visuals,
    required this.layout,
    required this.encounters,
  });

  factory WorldMapConfig.fromYaml(YamlMap yaml) {
    final map = yaml['map'] as YamlMap;
    final sizeTiles = map['map_size'] as YamlMap;
    return WorldMapConfig(
      tileSize: readDouble(map, 'tile_size'),
      cameraZoom: readDouble(map, 'camera_zoom'),
      mapSizeTiles: MapSizeRangeConfig.fromYaml(sizeTiles),
      visuals: WorldMapVisualConfig.fromYaml(map['visuals'] as YamlMap),
      layout: WorldMapLayoutConfig.fromYaml(map['layout'] as YamlMap),
      encounters: EncounterConfig.fromYaml(map['gameplay'] as YamlMap),
    );
  }

  final double tileSize;
  final double cameraZoom;

  /// Size range in TILES (the actual size per run is rolled from this range).
  final MapSizeRangeConfig mapSizeTiles;

  final WorldMapVisualConfig visuals;
  final WorldMapLayoutConfig layout;
  final EncounterConfig encounters;
}

// ── MapSizeRangeConfig ────────────────────────────────────────────────────────

class MapSizeRangeConfig {
  const MapSizeRangeConfig({required this.width, required this.height});

  factory MapSizeRangeConfig.fromYaml(YamlMap yaml) => MapSizeRangeConfig(
        width: IntRangeConfig.fromYaml(yaml['width'] as YamlMap),
        height: IntRangeConfig.fromYaml(yaml['height'] as YamlMap),
      );

  final IntRangeConfig width;
  final IntRangeConfig height;

  int rollWidth(Random r) => width.roll(r);
  int rollHeight(Random r) => height.roll(r);
}

// ── EncounterConfig ───────────────────────────────────────────────────────────
// Parsed from map.yaml → gameplay section.

class EncounterConfig {
  const EncounterConfig({
    required this.collisionStartsCombat,
    required this.collisionPadding,
    required this.retriggerCooldown,
  });

  factory EncounterConfig.fromYaml(YamlMap yaml) {
    return EncounterConfig(
      collisionStartsCombat: yaml['collision_starts_combat'] as bool,
      collisionPadding: readDouble(yaml, 'collision_padding'),
      retriggerCooldown: readDouble(yaml, 'retrigger_cooldown_seconds'),
    );
  }

  final bool collisionStartsCombat;
  final double collisionPadding;
  final double retriggerCooldown;
}

// ── WorldMapVisualConfig ──────────────────────────────────────────────────────

class WorldMapVisualConfig {
  const WorldMapVisualConfig({
    required this.grassColor,
    required this.roadColor,
    required this.buildingColor,
    required this.dirtRoadColor,
    required this.stoneRoadColor,
    required this.trainingFieldColor,
  });

  factory WorldMapVisualConfig.fromYaml(YamlMap yaml) {
    return WorldMapVisualConfig(
      grassColor: readHexColor(yaml, 'grass_color'),
      roadColor: readHexColor(yaml, 'road_color'),
      buildingColor: readHexColor(yaml, 'building_color'),
      dirtRoadColor: readHexColor(yaml, 'dirt_road_color'),
      stoneRoadColor: readHexColor(yaml, 'stone_road_color'),
      trainingFieldColor: readHexColor(yaml, 'training_field_color'),
    );
  }

  final Color grassColor;
  final Color roadColor;
  final Color buildingColor;
  final Color dirtRoadColor;
  final Color stoneRoadColor;
  final Color trainingFieldColor;
}

// ── WorldMapLayoutConfig ──────────────────────────────────────────────────────

class WorldMapLayoutConfig {
  const WorldMapLayoutConfig({
    required this.militaryZoneRatio,
    required this.commercialZoneRatio,
    required this.residentialZoneRatio,
    required this.stoneHighwayThreshold,
    required this.interVillageRoadWidth,
    required this.generator,
  });

  factory WorldMapLayoutConfig.fromYaml(YamlMap yaml) {
    return WorldMapLayoutConfig(
      militaryZoneRatio: readDouble(yaml, 'military_zone_ratio'),
      commercialZoneRatio: readDouble(yaml, 'commercial_zone_ratio'),
      residentialZoneRatio: readDouble(yaml, 'residential_zone_ratio'),
      stoneHighwayThreshold: readDouble(yaml, 'stone_highway_threshold'),
      interVillageRoadWidth: readDouble(yaml, 'inter_village_road_width'),
      generator: VillageGeneratorConfig.fromYaml(
        yaml['generator'] as YamlMap,
      ),
    );
  }

  final double militaryZoneRatio;
  final double commercialZoneRatio;
  final double residentialZoneRatio;
  final double stoneHighwayThreshold;
  final double interVillageRoadWidth;
  final VillageGeneratorConfig generator;
}

// ── Range helpers ─────────────────────────────────────────────────────────────

class IntRangeConfig {
  const IntRangeConfig({required this.min, required this.max});

  factory IntRangeConfig.fromYaml(YamlMap yaml) => IntRangeConfig(
        min: (yaml['min'] as num).toInt(),
        max: (yaml['max'] as num).toInt(),
      );

  final int min;
  final int max;

  int roll(Random random) {
    if (max <= min) return min;
    return min + random.nextInt(max - min + 1);
  }
}

class DoubleRangeConfig {
  const DoubleRangeConfig({required this.min, required this.max});

  factory DoubleRangeConfig.fromYaml(YamlMap yaml) => DoubleRangeConfig(
        min: (yaml['min'] as num).toDouble(),
        max: (yaml['max'] as num).toDouble(),
      );

  final double min;
  final double max;

  double roll(Random random) {
    if (max <= min) return min;
    return min + random.nextDouble() * (max - min);
  }
}

// ── TileSizeRangeConfig ───────────────────────────────────────────────────────
// Both axes are IntRangeConfig. A fresh random footprint is rolled per placement.

class TileSizeRangeConfig {
  const TileSizeRangeConfig({required this.width, required this.height});

  factory TileSizeRangeConfig.fromYaml(YamlMap yaml) => TileSizeRangeConfig(
        width: IntRangeConfig.fromYaml(yaml['width'] as YamlMap),
        height: IntRangeConfig.fromYaml(yaml['height'] as YamlMap),
      );

  final IntRangeConfig width;
  final IntRangeConfig height;

  int rollWidth(Random r) => width.roll(r);
  int rollHeight(Random r) => height.roll(r);
}

// ── Zone building lists ───────────────────────────────────────────────────────

class ZoneBuildingEntry {
  const ZoneBuildingEntry({
    required this.type,
    required this.count,
    required this.tiles,
  });

  factory ZoneBuildingEntry.fromYaml(YamlMap yaml) => ZoneBuildingEntry(
        type: yaml['type'] as String,
        count: (yaml['count'] as num?)?.toInt() ?? 1,
        tiles: TileSizeRangeConfig.fromYaml(yaml['tiles'] as YamlMap),
      );

  final String type;
  final int count;
  final TileSizeRangeConfig tiles;
}

class ZoneConfig {
  const ZoneConfig({required this.mandatory, required this.optional});

  factory ZoneConfig.fromYaml(YamlMap yaml) {
    List<ZoneBuildingEntry> parse(String key) {
      final raw = yaml[key];
      if (raw == null) return [];
      final list = raw as YamlList;
      if (list.isEmpty) return [];
      return list.cast<YamlMap>().map(ZoneBuildingEntry.fromYaml).toList();
    }

    return ZoneConfig(mandatory: parse('mandatory'), optional: parse('optional'));
  }

  final List<ZoneBuildingEntry> mandatory;
  final List<ZoneBuildingEntry> optional;
}

class ResidentialZoneConfig {
  const ResidentialZoneConfig({
    required this.houseTiles,
    required this.targetHouses,
  });

  factory ResidentialZoneConfig.fromYaml(YamlMap yaml) => ResidentialZoneConfig(
        houseTiles: TileSizeRangeConfig.fromYaml(yaml['house_tiles'] as YamlMap),
        targetHouses: IntRangeConfig.fromYaml(yaml['target_houses'] as YamlMap),
      );

  final TileSizeRangeConfig houseTiles;

  /// Exact house count is rolled once per village at generation start.
  final IntRangeConfig targetHouses;
}

// ── VillageGeneratorGlobalConfig ──────────────────────────────────────────────

class VillageGeneratorGlobalConfig {
  const VillageGeneratorGlobalConfig({
    required this.numSpines,
    required this.spineLengthFraction,
    required this.straightRunTiles,
    required this.spineWidthTiles,
    required this.branchWidthTiles,
    required this.numBranchesBase,
    required this.numBranchesPerSize,
    required this.branchLengthTiles,
    required this.minRoadSpacingTiles,
    required this.exitRoadWidthTiles,
  });

  factory VillageGeneratorGlobalConfig.fromYaml(YamlMap yaml) {
    return VillageGeneratorGlobalConfig(
      numSpines: IntRangeConfig.fromYaml(yaml['num_spines'] as YamlMap),
      spineLengthFraction:
          DoubleRangeConfig.fromYaml(yaml['spine_length_fraction'] as YamlMap),
      straightRunTiles:
          IntRangeConfig.fromYaml(yaml['straight_run_tiles'] as YamlMap),
      spineWidthTiles: (yaml['spine_width_tiles'] as num).toInt(),
      branchWidthTiles: (yaml['branch_width_tiles'] as num).toInt(),
      numBranchesBase: (yaml['num_branches_base'] as num).toInt(),
      numBranchesPerSize: (yaml['num_branches_per_size'] as num).toInt(),
      branchLengthTiles:
          IntRangeConfig.fromYaml(yaml['branch_length_tiles'] as YamlMap),
      minRoadSpacingTiles: (yaml['min_road_spacing_tiles'] as num).toInt(),
      exitRoadWidthTiles: (yaml['exit_road_width_tiles'] as num).toInt(),
    );
  }

  final IntRangeConfig numSpines;
  final DoubleRangeConfig spineLengthFraction;
  final IntRangeConfig straightRunTiles;
  final int spineWidthTiles;
  final int branchWidthTiles;
  final int numBranchesBase;
  final int numBranchesPerSize;
  final IntRangeConfig branchLengthTiles;
  final int minRoadSpacingTiles;
  final int exitRoadWidthTiles;
}

// ── VillageTierConfig ─────────────────────────────────────────────────────────

class VillageTierConfig {
  const VillageTierConfig({
    required this.gridCols,
    required this.gridRows,
    required this.gridExpandPerAttemptTiles,
    required this.militaryZone,
    required this.commercialZone,
    required this.residentialZone,
  });

  factory VillageTierConfig.fromYaml(YamlMap yaml) {
    return VillageTierConfig(
      gridCols: IntRangeConfig.fromYaml(yaml['grid_cols'] as YamlMap),
      gridRows: IntRangeConfig.fromYaml(yaml['grid_rows'] as YamlMap),
      gridExpandPerAttemptTiles:
          (yaml['grid_expand_per_attempt_tiles'] as num).toInt(),
      militaryZone: ZoneConfig.fromYaml(yaml['military_zone'] as YamlMap),
      commercialZone: ZoneConfig.fromYaml(yaml['commercial_zone'] as YamlMap),
      residentialZone:
          ResidentialZoneConfig.fromYaml(yaml['residential_zone'] as YamlMap),
    );
  }

  /// Working grid width range in TILES.
  final IntRangeConfig gridCols;

  /// Working grid height range in TILES.
  final IntRangeConfig gridRows;

  final int gridExpandPerAttemptTiles;
  final ZoneConfig militaryZone;
  final ZoneConfig commercialZone;
  final ResidentialZoneConfig residentialZone;
}

// ── VillageGeneratorConfig ────────────────────────────────────────────────────

class VillageGeneratorConfig {
  const VillageGeneratorConfig({
    required this.smallMaxSize,
    required this.mediumMaxSize,
    required this.global,
    required this.small,
    required this.medium,
    required this.large,
  });

  factory VillageGeneratorConfig.fromYaml(YamlMap yaml) {
    return VillageGeneratorConfig(
      smallMaxSize: (yaml['small_max_size'] as num).toInt(),
      mediumMaxSize: (yaml['medium_max_size'] as num).toInt(),
      global: VillageGeneratorGlobalConfig.fromYaml(
        yaml['global'] as YamlMap,
      ),
      small: VillageTierConfig.fromYaml(yaml['small'] as YamlMap),
      medium: VillageTierConfig.fromYaml(yaml['medium'] as YamlMap),
      large: VillageTierConfig.fromYaml(yaml['large'] as YamlMap),
    );
  }

  final int smallMaxSize;
  final int mediumMaxSize;
  final VillageGeneratorGlobalConfig global;
  final VillageTierConfig small;
  final VillageTierConfig medium;
  final VillageTierConfig large;

  VillageTierConfig tierFor(int villageSize) {
    if (villageSize <= smallMaxSize) return small;
    if (villageSize <= mediumMaxSize) return medium;
    return large;
  }
}
