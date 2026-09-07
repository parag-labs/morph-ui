/// The mode/state engine — the deterministic core of MorphUI. It maps a [MorphContext]
/// (time of day, current activity, and a cognitive-load signal) to a [UiMode], and each mode
/// carries a full [ModeConfig] describing how the interface should look: density, column count,
/// accent, motion intensity, and which component set to show. This is pure Dart with no Flutter
/// imports, so the "which mode, laid out how" decision is unit-testable and reproducible.
library;

/// The distinct interface modes. Each is a meaningfully different visual language, not just a
/// colour swap.
enum UiMode { deepWork, browse, quickAction, discover, windDown }

/// The signals the engine reacts to.
class MorphContext {
  const MorphContext({required this.hour, required this.activity, required this.cognitiveLoad});

  /// 0..23.
  final int hour;

  /// A coarse activity label the device could infer.
  final Activity activity;

  /// 0..1 — higher means the user is under more cognitive load (calmer, sparser UI).
  final double cognitiveLoad;
}

enum Activity { working, browsing, commuting, relaxing, exercising }

/// The layout language for a mode.
class ModeConfig {
  const ModeConfig({
    required this.mode,
    required this.title,
    required this.description,
    required this.columns,
    required this.density,
    required this.motion,
    required this.accent,
    required this.components,
  });

  final UiMode mode;
  final String title;
  final String description;

  /// Grid columns (1 = focused/stacked, 3 = dense).
  final int columns;

  /// 0..1 — visual density (spacing, font size scale inversely).
  final double density;

  /// 0..1 — animation intensity.
  final double motion;

  /// A hex ARGB accent as an int, e.g. 0xFF7C6CFF.
  final int accent;

  /// The ordered component set to render.
  final List<MorphComponent> components;
}

enum MorphComponent { focusTimer, taskList, quickActions, feed, stats, nowPlaying, breathing, suggestions, search, calendar }

/// Choose a mode from context. Deterministic and total — every context maps to exactly one mode.
///
/// The rules, in priority order:
///  - high cognitive load late in the day → wind down (protect the user);
///  - working activity or work hours with focus → deep work;
///  - commuting or a quick spare moment → quick action;
///  - relaxing in the evening → wind down;
///  - browsing → browse; otherwise → discover.
UiMode selectMode(MorphContext ctx) {
  final evening = ctx.hour >= 20 || ctx.hour < 6;
  if (ctx.cognitiveLoad >= 0.75 && (evening || ctx.activity == Activity.relaxing)) return UiMode.windDown;
  if (ctx.activity == Activity.working || (ctx.hour >= 9 && ctx.hour <= 17 && ctx.cognitiveLoad < 0.6)) {
    return UiMode.deepWork;
  }
  if (ctx.activity == Activity.commuting || ctx.activity == Activity.exercising) return UiMode.quickAction;
  if (ctx.activity == Activity.relaxing || evening) return UiMode.windDown;
  if (ctx.activity == Activity.browsing) return UiMode.browse;
  return UiMode.discover;
}

const Map<UiMode, ModeConfig> _configs = {
  UiMode.deepWork: ModeConfig(
    mode: UiMode.deepWork,
    title: 'Deep Work',
    description: 'Focused and sparse. One thing at a time.',
    columns: 1,
    density: 0.25,
    motion: 0.3,
    accent: 0xFF7C6CFF,
    components: [MorphComponent.focusTimer, MorphComponent.taskList, MorphComponent.stats],
  ),
  UiMode.browse: ModeConfig(
    mode: UiMode.browse,
    title: 'Browse',
    description: 'Comfortable reading with a rich feed.',
    columns: 2,
    density: 0.55,
    motion: 0.5,
    accent: 0xFF34D9C8,
    components: [MorphComponent.feed, MorphComponent.search, MorphComponent.suggestions, MorphComponent.stats],
  ),
  UiMode.quickAction: ModeConfig(
    mode: UiMode.quickAction,
    title: 'Quick Action',
    description: 'Big, thumb-sized shortcuts for a spare moment.',
    columns: 2,
    density: 0.4,
    motion: 0.7,
    accent: 0xFFFFB020,
    components: [MorphComponent.quickActions, MorphComponent.nowPlaying, MorphComponent.calendar],
  ),
  UiMode.discover: ModeConfig(
    mode: UiMode.discover,
    title: 'Discover',
    description: 'Dense and exploratory.',
    columns: 3,
    density: 0.8,
    motion: 0.8,
    accent: 0xFFF472B6,
    components: [MorphComponent.feed, MorphComponent.suggestions, MorphComponent.stats, MorphComponent.search, MorphComponent.calendar],
  ),
  UiMode.windDown: ModeConfig(
    mode: UiMode.windDown,
    title: 'Wind Down',
    description: 'Calm, minimal, low motion.',
    columns: 1,
    density: 0.2,
    motion: 0.2,
    accent: 0xFF8B93FF,
    components: [MorphComponent.breathing, MorphComponent.nowPlaying],
  ),
};

/// The full layout config for a mode.
ModeConfig configFor(UiMode mode) => _configs[mode]!;
