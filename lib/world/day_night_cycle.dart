import '../config/models/world_config.dart';

class DayNightCycle {
  DayNightCycle(this.config) : _phase = config.startingPhase;

  final WorldTimeConfig config;
  String _phase;
  double _elapsed = 0;

  String get phase => _phase;

  double get progress {
    final duration = _currentDuration;
    if (duration <= 0) {
      return 0;
    }
    return (_elapsed / duration).clamp(0, 1);
  }

  void update(double dt) {
    _elapsed += dt;
    if (_elapsed < _currentDuration) {
      return;
    }
    _elapsed = 0;
    _phase = _phase == 'day' ? 'night' : 'day';
  }

  double get _currentDuration {
    return _phase == 'day' ? config.dayDuration : config.nightDuration;
  }
}
