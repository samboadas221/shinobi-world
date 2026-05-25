import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../character/player_profile.dart';
import '../character/ninja_stats.dart';
import '../config/models/stats_scaling_config.dart';
import '../config/models/jutsu_progression_config.dart';
import '../game/demo_state.dart';
import '../game/shinobi_world_game.dart';

class DemoHud extends StatefulWidget {
  const DemoHud({
    super.key,
    required this.stateListenable,
    required this.onPracticeJutsu,
    required this.onRegenerateWorld,
    required this.profile,
    required this.statsScaling,
    required this.jutsuProgression,
    required this.game,
  });

  final ValueListenable<DemoState> stateListenable;
  final ValueChanged<String> onPracticeJutsu;
  final void Function(int? seed) onRegenerateWorld;
  final PlayerProfile profile;
  final StatsScalingConfig statsScaling;
  final JutsuProgressionConfig jutsuProgression;
  final ShinobiWorldGame game;

  @override
  State<DemoHud> createState() => _DemoHudState();
}

class _DemoHudState extends State<DemoHud> {
  bool _isDebugExpanded = false;

  void _openPlayerMenu() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: _PlayerMenuDialog(
            profile: widget.profile,
            statsScaling: widget.statsScaling,
            jutsuProgression: widget.jutsuProgression,
            game: widget.game,
            onPracticeJutsu: widget.onPracticeJutsu,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          // Left control buttons (Debug and Player Menu)
          Align(
            alignment: Alignment.topLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: FloatingActionButton.small(
                        heroTag: 'debug_fab',
                        onPressed: () => setState(() => _isDebugExpanded = !_isDebugExpanded),
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.greenAccent,
                        child: Icon(_isDebugExpanded ? Icons.close : Icons.bug_report),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: FloatingActionButton.extended(
                        heroTag: 'player_menu_fab',
                        onPressed: _openPlayerMenu,
                        backgroundColor: const Color(0xFF2F6F4E),
                        foregroundColor: Colors.white,
                        icon: const Icon(Icons.person),
                        label: const Text('Player Menu', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                if (_isDebugExpanded)
                  ValueListenableBuilder<DemoState>(
                    valueListenable: widget.stateListenable,
                    builder: (context, state, _) {
                      return _HudPanel(
                        state: state,
                        onRegenerateWorld: widget.onRegenerateWorld,
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HudPanel extends StatefulWidget {
  const _HudPanel({required this.state, required this.onRegenerateWorld});

  final DemoState state;
  final void Function(int? seed) onRegenerateWorld;

  @override
  State<_HudPanel> createState() => _HudPanelState();
}

class _HudPanelState extends State<_HudPanel> {
  final TextEditingController _seedController = TextEditingController();

  @override
  void dispose() {
    _seedController.dispose();
    super.dispose();
  }

  void _triggerRegenerate() {
    final text = _seedController.text;
    final seed = int.tryParse(text);
    if (seed != null && seed >= 100000 && seed <= 999999) {
      widget.onRegenerateWorld(seed);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid seed between 100,000 and 999,999.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height - 120,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Debug Panel',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const _FpsCounter(),
                ],
              ),
              const Divider(color: Colors.white24, height: 16),
              Text('Run Seed: ${widget.state.runSeed}', style: const TextStyle(color: Colors.white70)),
              Text('Villages: ${widget.state.villageCount}', style: const TextStyle(color: Colors.white70)),
              Text('Stored Ninjas: ${widget.state.ninjaCount}', style: const TextStyle(color: Colors.white70)),
              Text(
                'Coordinates: X: ${widget.state.playerTileX.toStringAsFixed(1)}, Y: ${widget.state.playerTileY.toStringAsFixed(1)}',
                style: const TextStyle(color: Colors.white70),
              ),
              Text('World Phase: ${widget.state.phase}', style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: widget.state.cycleProgress,
                backgroundColor: Colors.white12,
                color: Colors.orangeAccent,
              ),
              const SizedBox(height: 8),
              Text('Database: ${widget.state.databaseStatus}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
              const Divider(color: Colors.white24, height: 20),
              const Text(
                'Generate Seed-driven World',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: TextField(
                        controller: _seedController,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        decoration: InputDecoration(
                          hintText: '100000 - 999999',
                          hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          fillColor: Colors.white10,
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 36,
                    child: FilledButton(
                      onPressed: _triggerRegenerate,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2F6F4E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text('Generate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlayerMenuDialog extends StatefulWidget {
  const _PlayerMenuDialog({
    required this.profile,
    required this.statsScaling,
    required this.jutsuProgression,
    required this.game,
    required this.onPracticeJutsu,
  });

  final PlayerProfile profile;
  final StatsScalingConfig statsScaling;
  final JutsuProgressionConfig jutsuProgression;
  final ShinobiWorldGame game;
  final ValueChanged<String> onPracticeJutsu;

  @override
  State<_PlayerMenuDialog> createState() => _PlayerMenuDialogState();
}

class _PlayerMenuDialogState extends State<_PlayerMenuDialog> {
  Color _getTierColor(String tier) {
    switch (tier) {
      case 'S': return Colors.amber;
      case 'A': return Colors.purpleAccent;
      case 'B': return Colors.blueAccent;
      case 'C': return Colors.greenAccent;
      case 'D': return Colors.orangeAccent;
      case 'E':
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = widget.profile.stats;

    // Recalculate stats dynamically
    final calculatedHp = stats.calculate('HP', widget.statsScaling);
    final calculatedCp = stats.calculate('CP', widget.statsScaling);
    final calculatedSp = stats.calculate('SP', widget.statsScaling);

    return DefaultTabController(
      length: 3,
      child: Container(
        width: 520,
        height: 600,
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.greenAccent.withOpacity(0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.7),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          children: [
            // Menu Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield, color: Colors.greenAccent, size: 28),
                      const SizedBox(width: 8),
                      Text(
                        widget.profile.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
            ),

            // Tab bar
            const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.info_outline), text: 'Overview'),
                Tab(icon: Icon(Icons.bar_chart), text: 'Stats'),
                Tab(icon: Icon(Icons.bolt), text: 'Jutsus'),
              ],
              labelColor: Colors.greenAccent,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.greenAccent,
              dividerColor: Colors.white12,
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                children: [
                  // Tab 1: Overview
                  _buildOverviewTab(calculatedHp, calculatedCp, calculatedSp),

                  // Tab 2: Stats
                  _buildStatsTab(stats),

                  // Tab 3: Jutsus
                  _buildJutsusTab(stats),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab(int hp, int cp, int sp) {
    final stats = widget.profile.stats;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Styled Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF222222),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.greenAccent, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.greenAccent.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.profile.gender == 'male' ? '🥷' : '👩‍🥷',
                    style: const TextStyle(fontSize: 40),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level ${stats.level} Shinobi',
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Gender: ${widget.profile.gender.toUpperCase()}',
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  Text(
                    'Nature: ${widget.profile.naturalNature.toUpperCase()}',
                    style: const TextStyle(color: Colors.orangeAccent, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const Divider(color: Colors.white12, height: 32),

          // HP gauge
          _buildGauge('HEALTH POINTS (HP)', hp, widget.statsScaling.maxes['HP']!.toInt(), Colors.redAccent),
          const SizedBox(height: 16),

          // CP gauge
          _buildGauge('CHAKRA POINTS (CP)', widget.game.demoState.value.currentChakra, cp, Colors.blueAccent),
          const SizedBox(height: 16),

          // SP gauge
          _buildGauge('SENJUTSU (SP)', sp, widget.statsScaling.maxes['SP']!.toInt(), Colors.purpleAccent),

          const Divider(color: Colors.white12, height: 32),
          const Text(
            'CHAKRA AFFINITIES',
            style: TextStyle(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildAffinityBadge(widget.profile.naturalNature, isPrimary: true),
              const SizedBox(width: 8),
              _buildAffinityBadge(widget.profile.secondaryNature, isPrimary: false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGauge(String label, int current, int max, Color color) {
    final double percentage = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
            Text('$current / $max', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 8,
            backgroundColor: Colors.white10,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildAffinityBadge(String nature, {required bool isPrimary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isPrimary ? Colors.greenAccent.withOpacity(0.15) : Colors.amber.withOpacity(0.1),
        border: Border.all(color: isPrimary ? Colors.greenAccent : Colors.amber),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${nature.toUpperCase()} ${isPrimary ? "(Primary)" : "(Secondary)"}',
        style: TextStyle(
          color: isPrimary ? Colors.greenAccent : Colors.amber,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatsTab(NinjaStats stats) {
    const list = [
      'HP',
      'CP',
      'SP',
      'Armor',
      'Speed',
      'SpeedReaction',
      'SpeedSeal',
      'ChakraControl',
      'ChakraBuffer',
      'Taijutsu'
    ];

    final labels = {
      'HP': 'Health Points',
      'CP': 'Chakra Points',
      'SP': 'Senjutsu',
      'Armor': 'Armor / Defense',
      'Speed': 'Movement Speed',
      'SpeedReaction': 'Speed Reaction',
      'SpeedSeal': 'Speed Seal',
      'ChakraControl': 'Chakra Control',
      'ChakraBuffer': 'Chakra Buffer',
      'Taijutsu': 'Taijutsu (Attack)',
    };

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final key = list[index];
        final tier = stats.scalingTiers[key] ?? 'B';
        final val = stats.calculate(key, widget.statsScaling);
        final spent = stats.spentPoints[key] ?? 0;
        final tierColor = _getTierColor(tier);

        return Card(
          color: const Color(0xFF1E1E1E),
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Row(
              children: [
                Text(labels[key] ?? key, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: tierColor.withOpacity(0.15),
                    border: Border.all(color: tierColor),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tier,
                    style: TextStyle(color: tierColor, fontWeight: FontWeight.bold, fontSize: 10),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              'Points Spent: $spent',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            trailing: Text(
              '$val',
              style: const TextStyle(
                color: Colors.greenAccent,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildJutsusTab(NinjaStats stats) {
    final list = widget.game.playerJutsu;

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final jutsu = list[index];
        final lvl = widget.game.practice.getJutsuLevel(jutsu.id);
        final exp = widget.game.practice.getJutsuExp(jutsu.id);
        final maxLvl = widget.jutsuProgression.maxLevels[jutsu.id] ?? 5;
        final cost = widget.game.practice.practiceCost(jutsu);

        final reductionSeals = (lvl - 1) * widget.jutsuProgression.handSealsReduction;
        final seals = max(1, jutsu.handSeals.length - reductionSeals);
        final damageBoost = (lvl - 1) * widget.jutsuProgression.damageBoostPercent;
        final finalDamage = (jutsu.damage * (1.0 + damageBoost)).toInt();

        final expNeeded = widget.jutsuProgression.expToNextLevel;
        final expPct = (exp / expNeeded).clamp(0.0, 1.0);

        final isAffinityNature = jutsu.chakraNature == widget.profile.naturalNature ||
            jutsu.chakraNature == widget.profile.secondaryNature;

        return Card(
          color: const Color(0xFF1E1E1E),
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          jutsu.displayName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'LV $lvl / $maxLvl',
                          style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isAffinityNature ? Colors.orangeAccent.withOpacity(0.15) : Colors.white12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        jutsu.chakraNature.toUpperCase(),
                        style: TextStyle(
                          color: isAffinityNature ? Colors.orangeAccent : Colors.white60,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Chakra Cost: $cost CP', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('Hand Signs: $seals', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('Est. Damage: $finalDamage', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: () {
                        // Cast in overworld!
                        final casted = widget.game.practiceJutsu(jutsu.id);
                        if (casted != null) {
                          // Show toast or trigger state update locally in dialog
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Cast ${jutsu.displayName} in overworld successfully!'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(widget.game.demoState.value.practiceLog),
                              backgroundColor: Colors.redAccent,
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        }
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2F6F4E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('Cast Overworld', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // EXP Bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: expPct,
                          minHeight: 6,
                          backgroundColor: Colors.white10,
                          color: Colors.greenAccent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$exp / $expNeeded EXP',
                      style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FpsCounter extends StatefulWidget {
  const _FpsCounter();

  @override
  State<_FpsCounter> createState() => _FpsCounterState();
}

class _FpsCounterState extends State<_FpsCounter> {
  int _fps = 0;
  int _frameCount = 0;
  double _lastUpdateTime = 0;
  late final FrameCallback _frameCallback;

  @override
  void initState() {
    super.initState();
    _frameCallback = (duration) {
      if (!mounted) return;
      _frameCount++;
      final double sec = duration.inMicroseconds / 1000000.0;
      if (_lastUpdateTime == 0) {
        _lastUpdateTime = sec;
      } else {
        final double elapsed = sec - _lastUpdateTime;
        if (elapsed >= 0.400) {
          setState(() {
            _fps = (_frameCount / elapsed).round();
            _frameCount = 0;
            _lastUpdateTime = sec;
          });
        }
      }
      SchedulerBinding.instance.addPostFrameCallback(_frameCallback);
    };
    SchedulerBinding.instance.addPostFrameCallback(_frameCallback);
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      'FPS: $_fps',
      style: const TextStyle(
        color: Colors.greenAccent,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
