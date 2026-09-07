import 'package:flutter/material.dart';
import 'core/morph_engine.dart';

void main() => runApp(const MorphApp());

class MorphApp extends StatelessWidget {
  const MorphApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MorphUI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, brightness: Brightness.dark, scaffoldBackgroundColor: const Color(0xFF0A0C12)),
      home: const MorphScreen(),
    );
  }
}

class MorphScreen extends StatefulWidget {
  const MorphScreen({super.key});

  @override
  State<MorphScreen> createState() => _MorphScreenState();
}

class _MorphScreenState extends State<MorphScreen> {
  int _hour = 10;
  Activity _activity = Activity.working;
  double _load = 0.3;

  MorphContext get _ctx => MorphContext(hour: _hour, activity: _activity, cognitiveLoad: _load);
  UiMode get _mode => selectMode(_ctx);

  @override
  Widget build(BuildContext context) {
    final cfg = configFor(_mode);
    final accent = Color(cfg.accent);

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.5, -0.9),
                radius: 1.4,
                colors: [accent.withOpacity(0.16), const Color(0xFF0A0C12)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('MorphUI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                        const Spacer(),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            key: ValueKey(cfg.mode),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: accent.withOpacity(0.18), borderRadius: BorderRadius.circular(999)),
                            child: Text(cfg.title, style: TextStyle(color: accent, fontWeight: FontWeight.w600, fontSize: 12.5)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Text(cfg.description, key: ValueKey(cfg.description), style: const TextStyle(color: Color(0xFF98A2B8), fontSize: 12.5)),
                    ),
                    const SizedBox(height: 16),
                    Expanded(child: _MorphSurface(cfg: cfg, accent: accent)),
                    const SizedBox(height: 12),
                    _Controls(
                      hour: _hour,
                      activity: _activity,
                      load: _load,
                      accent: accent,
                      onHour: (v) => setState(() => _hour = v),
                      onActivity: (a) => setState(() => _activity = a),
                      onLoad: (v) => setState(() => _load = v),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The morphing surface. Component cards animate in/out and re-flow as the mode's column count
/// and density change, giving the sense of a UI that continuously redesigns itself.
class _MorphSurface extends StatelessWidget {
  const _MorphSurface({required this.cfg, required this.accent});
  final ModeConfig cfg;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final spacing = 8.0 + (1 - cfg.density) * 10;
    return SingleChildScrollView(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
        alignment: Alignment.topCenter,
        child: Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final c in cfg.components)
              _ComponentCard(
                key: ValueKey(c),
                component: c,
                accent: accent,
                columns: cfg.columns,
                density: cfg.density,
                spacing: spacing,
              ),
          ],
        ),
      ),
    );
  }
}

class _ComponentCard extends StatelessWidget {
  const _ComponentCard({super.key, required this.component, required this.accent, required this.columns, required this.density, required this.spacing});
  final MorphComponent component;
  final Color accent;
  final int columns;
  final double density;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.of(context).size.width.clamp(0, 460).toDouble() - 32;
    final width = (maxW - spacing * (columns - 1)) / columns;
    final pad = 10.0 + (1 - density) * 8;
    final meta = _meta(component);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
      width: width,
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: const Color(0xFF141824),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x22FFFFFF)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(meta.$1, color: accent, size: columns >= 3 ? 18 : 22),
          SizedBox(height: 6 + (1 - density) * 4),
          Text(meta.$2, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: columns >= 3 ? 12.5 : 14)),
          Text(meta.$3, style: const TextStyle(color: Color(0xFF98A2B8), fontSize: 11.5)),
        ],
      ),
    );
  }

  (IconData, String, String) _meta(MorphComponent c) {
    switch (c) {
      case MorphComponent.focusTimer:
        return (Icons.timer_outlined, 'Focus timer', '25:00');
      case MorphComponent.taskList:
        return (Icons.checklist_rounded, "Today's focus", '3 tasks');
      case MorphComponent.quickActions:
        return (Icons.bolt_rounded, 'Quick actions', 'Tap to act');
      case MorphComponent.feed:
        return (Icons.dynamic_feed_rounded, 'Feed', 'Fresh for you');
      case MorphComponent.stats:
        return (Icons.insights_rounded, 'Stats', 'Your day');
      case MorphComponent.nowPlaying:
        return (Icons.music_note_outlined, 'Now playing', 'Ambient');
      case MorphComponent.breathing:
        return (Icons.spa_outlined, 'Breathe', '4-7-8');
      case MorphComponent.suggestions:
        return (Icons.auto_awesome, 'For you', 'Suggestions');
      case MorphComponent.search:
        return (Icons.search_rounded, 'Search', 'Find anything');
      case MorphComponent.calendar:
        return (Icons.calendar_today_outlined, 'Up next', '2:00 PM');
    }
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.hour,
    required this.activity,
    required this.load,
    required this.accent,
    required this.onHour,
    required this.onActivity,
    required this.onLoad,
  });

  final int hour;
  final Activity activity;
  final double load;
  final Color accent;
  final ValueChanged<int> onHour;
  final ValueChanged<Activity> onActivity;
  final ValueChanged<double> onLoad;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF11141F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, size: 15, color: Color(0xFF98A2B8)),
              const SizedBox(width: 8),
              Text('${hour.toString().padLeft(2, '0')}:00', style: const TextStyle(color: Colors.white, fontSize: 12.5)),
              Expanded(
                child: Slider(
                  value: hour.toDouble(),
                  min: 0,
                  max: 23,
                  divisions: 23,
                  activeColor: accent,
                  onChanged: (v) => onHour(v.round()),
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.psychology_outlined, size: 15, color: Color(0xFF98A2B8)),
              const SizedBox(width: 8),
              const Text('Load', style: TextStyle(color: Colors.white, fontSize: 12.5)),
              Expanded(child: Slider(value: load, activeColor: accent, onChanged: onLoad)),
            ],
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 30,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: Activity.values.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (_, i) {
                final a = Activity.values[i];
                final on = a == activity;
                return GestureDetector(
                  onTap: () => onActivity(a),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: on ? accent.withOpacity(0.22) : const Color(0x14FFFFFF),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: on ? accent : const Color(0x22FFFFFF)),
                    ),
                    child: Text(a.name, style: TextStyle(color: on ? Colors.white : const Color(0xFF98A2B8), fontSize: 12)),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
