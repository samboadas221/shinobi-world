import 'dart:ui';
import 'world_layout_data.dart';

class RenderChunk {
  RenderChunk({
    required this.cx,
    required this.cy,
    required this.rect,
  });

  final int cx;
  final int cy;
  final Rect rect;

  final List<LayoutRoad> roads = [];
  final List<LayoutHighway> highways = [];
  final List<LayoutBuilding> buildings = [];
  final List<LayoutTrainingField> trainingFields = [];
}
