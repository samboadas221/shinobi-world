/// Axis-aligned bounding box used for collision detection.
///
/// All coordinates are in world pixels. This type has zero dependency on Flame
/// or Flutter \u2014 it is pure Dart and can be tested in isolation.
class AabbRect {
  const AabbRect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  /// Creates an AabbRect from top-left position and size.
  const AabbRect.fromLTWH(double l, double t, double w, double h)
    : left = l,
      top = t,
      right = l + w,
      bottom = t + h;

  final double left;
  final double top;
  final double right;
  final double bottom;

  double get width => right - left;
  double get height => bottom - top;

  /// Returns true if this rect overlaps [other]. Touching edges do not count.
  bool overlaps(AabbRect other) {
    return left < other.right &&
        right > other.left &&
        top < other.bottom &&
        bottom > other.top;
  }

  /// Returns a copy expanded outward on all sides by [amount].
  AabbRect expanded(double amount) {
    return AabbRect(
      left: left - amount,
      top: top - amount,
      right: right + amount,
      bottom: bottom + amount,
    );
  }

  @override
  String toString() => 'AabbRect(L:$left T:$top R:$right B:$bottom)';
}
