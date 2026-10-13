import 'package:flutter_test/flutter_test.dart';
import 'package:nutrify/utils/weekly_summary_stats.dart';

void main() {
  group('computeLoggingStreak', () {
    test('counts consecutive logged days from today', () {
      final today = DateTime.now();
      String key(DateTime d) =>
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

      final history = <String, Map<String, int>>{
        key(today): {'calories': 1800},
        key(today.subtract(const Duration(days: 1))): {'calories': 1900},
        key(today.subtract(const Duration(days: 2))): {'calories': 0},
      };

      expect(computeLoggingStreak(history), 2);
    });
  });

  group('buildWeeklySummaryStats', () {
    test('computes weight delta across the week', () {
      final end = DateTime.now();
      final keys = List.generate(7, (i) {
        final d = end.subtract(Duration(days: 6 - i));
        return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      });
      final stats = buildWeeklySummaryStats(
        dateKeys: keys,
        nutritionHistory: {
          keys.last: {'calories': 2000, 'protein': 120, 'carbs': 200, 'fat': 60},
        },
        weightHistory: {
          keys.first: 82.0,
          keys.last: 80.5,
        },
        profile: null,
        goals: null,
        lang: 'en',
      );

      expect(stats.weightStartKg, 82.0);
      expect(stats.weightEndKg, 80.5);
      expect(stats.weightDeltaKg, closeTo(-1.5, 0.001));
      expect(stats.daysLogged, 1);
      expect(stats.loggingStreak, 1);
    });
  });
}
