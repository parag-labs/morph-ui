import 'package:flutter_test/flutter_test.dart';
import 'package:morph_ui/core/morph_engine.dart';

MorphContext ctx({int hour = 12, Activity activity = Activity.browsing, double load = 0.3}) =>
    MorphContext(hour: hour, activity: activity, cognitiveLoad: load);

void main() {
  group('selectMode', () {
    test('working activity → Deep Work', () {
      expect(selectMode(ctx(activity: Activity.working)), UiMode.deepWork);
    });

    test('work hours with low load → Deep Work', () {
      expect(selectMode(ctx(hour: 11, activity: Activity.browsing, load: 0.3)), UiMode.deepWork);
    });

    test('commuting or exercising → Quick Action', () {
      expect(selectMode(ctx(hour: 8, activity: Activity.commuting)), UiMode.quickAction);
      expect(selectMode(ctx(hour: 7, activity: Activity.exercising)), UiMode.quickAction);
    });

    test('high load in the evening → Wind Down', () {
      expect(selectMode(ctx(hour: 22, activity: Activity.relaxing, load: 0.9)), UiMode.windDown);
    });

    test('relaxing in the evening → Wind Down', () {
      expect(selectMode(ctx(hour: 21, activity: Activity.relaxing, load: 0.3)), UiMode.windDown);
    });

    test('browsing midday → Browse (when not in the focus window)', () {
      expect(selectMode(ctx(hour: 19, activity: Activity.browsing, load: 0.7)), UiMode.browse);
    });

    test('is total — every context yields a valid mode', () {
      for (var h = 0; h < 24; h++) {
        for (final a in Activity.values) {
          for (final l in [0.0, 0.5, 1.0]) {
            final mode = selectMode(MorphContext(hour: h, activity: a, cognitiveLoad: l));
            expect(UiMode.values.contains(mode), isTrue);
          }
        }
      }
    });

    test('is deterministic', () {
      final c = ctx(hour: 10, activity: Activity.working, load: 0.2);
      expect(selectMode(c), selectMode(c));
    });
  });

  group('configFor', () {
    test('every mode has a config with a distinct component set', () {
      final signatures = <String>{};
      for (final mode in UiMode.values) {
        final cfg = configFor(mode);
        expect(cfg.mode, mode);
        expect(cfg.title.isNotEmpty, isTrue);
        expect(cfg.columns, inInclusiveRange(1, 3));
        expect(cfg.density, inInclusiveRange(0.0, 1.0));
        expect(cfg.components, isNotEmpty);
        signatures.add(cfg.components.map((c) => c.name).join(','));
      }
      expect(signatures.length, UiMode.values.length, reason: 'each mode should look meaningfully different');
    });

    test('Deep Work is sparse (1 column, low density); Discover is dense (3 columns)', () {
      expect(configFor(UiMode.deepWork).columns, 1);
      expect(configFor(UiMode.deepWork).density, lessThan(0.4));
      expect(configFor(UiMode.discover).columns, 3);
      expect(configFor(UiMode.discover).density, greaterThan(0.6));
    });
  });
}
