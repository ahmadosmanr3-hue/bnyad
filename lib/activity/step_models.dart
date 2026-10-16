import 'dart:math' as math;
import '../models/user_profile.dart';

String stepDateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

class StepWindow {
  final DateTime start, end;
  StepWindow(this.start, this.end);
  String get date => stepDateKey(start);
  Map<String, Object> toMap() => {
    'date': date,
    'start': start.millisecondsSinceEpoch,
    'end': end.millisecondsSinceEpoch,
  };
}

/// Calendar arithmetic (not 24-hour subtraction) preserves local DST boundaries.
List<StepWindow> stepWindows(DateTime now) => [
  for (var offset = 0; offset <= 14; offset++)
    StepWindow(
      DateTime(now.year, now.month, now.day - offset),
      offset == 0 ? now : DateTime(now.year, now.month, now.day - offset + 1),
    ),
];

class StepDay {
  final String date;

  /// Null means missing or unreadable, never an inferred zero.
  final int? steps;

  /// Optional native aggregate; may include running/other activity. The calorie
  /// estimator caps it at the conservative step-derived walking distance.
  final double? distanceMeters;
  const StepDay(this.date, this.steps, {this.distanceMeters});
}

enum HealthPermission { unknown, granted, denied }

enum HealthAvailability { available, unavailable, installRequired }

class HealthAccess {
  final HealthAvailability availability;
  final HealthPermission permission;
  const HealthAccess(this.availability, this.permission);
  factory HealthAccess.fromMap(Map<Object?, Object?> map) => HealthAccess(
    switch (map['availability']) {
      'available' => HealthAvailability.available,
      'installRequired' => HealthAvailability.installRequired,
      _ => HealthAvailability.unavailable,
    },
    switch (map['permission']) {
      'granted' => HealthPermission.granted,
      'denied' => HealthPermission.denied,
      _ => HealthPermission.unknown,
    },
  );
}

bool needsGentleStepGoals(UserProfile? profile) =>
    profile != null &&
    (profile.disabilities.any((v) => v != 'none' && v.isNotEmpty) ||
        profile.age < 18 ||
        profile.age >= 65 ||
        !['none', 'planning'].contains(profile.pregnancyStatus));

/// Product starting points, not medical prescriptions or fitness requirements.
int initialStepGoal(UserProfile? profile) {
  if (needsGentleStepGoals(profile)) return 1000;
  return switch (profile?.activityLevel) {
    'lightlyActive' => 4000,
    'moderatelyActive' => 5000,
    'veryActive' => 6000,
    'extraActive' => 6500,
    _ => 3000,
  };
}

/// Only user-confirmed, completed calendar days can be used. Health platforms
/// cannot establish that the phone/watch was carried all day. Never equate a
/// positive aggregate with complete wear-time coverage.
int? suggestedStepGoal({
  required List<StepDay> days,
  required Set<String> confirmedDays,
  required int currentGoal,
  required DateTime now,
  required DateTime? lastAccepted,
  required bool gentle,
}) {
  if (gentle ||
      currentGoal < 1000 ||
      currentGoal > 10000 ||
      (lastAccepted != null && now.difference(lastAccepted).inDays < 7)) {
    return null;
  }
  final eligible = stepWindows(now).skip(1).map((w) => w.date).toSet();
  final byDate = <String, int>{};
  for (final day in days) {
    final value = day.steps;
    if (eligible.contains(day.date) &&
        confirmedDays.contains(day.date) &&
        value != null &&
        value >= 0 &&
        value <= 100000) {
      byDate[day.date] = value;
    }
  }
  if (byDate.length < 7) return null;
  final sorted = byDate.values.toList()..sort();
  final mid = sorted.length ~/ 2;
  final median = sorted.length.isOdd
      ? sorted[mid].toDouble()
      : (sorted[mid - 1] + sorted[mid]) / 2;
  final target = (median * 1.05).clamp(1000, 10000).round();
  // Round DOWN the allowable movement: rounding up would exceed the 5% cap.
  final delta = (math.min(currentGoal * .05, 500) / 50).floor() * 50;
  if (delta == 0) return null;
  final candidate = target.clamp(currentGoal - delta, currentGoal + delta);
  return candidate == currentGoal ? null : candidate;
}

class WalkingEstimate {
  final double kilometers;
  final int calories;
  const WalkingEstimate(this.kilometers, this.calories);
}

/// Read the newest valid existing account-local weigh-in, never future/corrupt
/// entries. This does not recalculate or mutate any nutrition target.
double? latestWalkingWeight(
  Map<String, double> history,
  DateTime now,
  double? fallback,
) {
  final today = stepDateKey(now);
  final valid = history.entries.where((entry) {
    final date = DateTime.tryParse(entry.key);
    return date != null &&
        stepDateKey(date) == entry.key &&
        entry.key.compareTo(today) <= 0 &&
        entry.value.isFinite &&
        entry.value >= 20 &&
        entry.value <= 350;
  }).toList()..sort((a, b) => b.key.compareTo(a.key));
  return valid.isEmpty ? fallback : valid.first.value;
}

/// Conservative net walking approximation: 0.45 kcal/kg/km. No resting-energy
/// component, exercise credit, TDEE modification or nutrition side effects.
/// All steps are treated as walking for illustration, not measured exercise.
WalkingEstimate? estimateWalking({
  required int? steps,
  required double? weightKg,
  required double? heightCm,
  double? distanceMeters,
}) {
  if (steps == null ||
      steps < 0 ||
      steps > 100000 ||
      weightKg == null ||
      !weightKg.isFinite ||
      weightKg < 20 ||
      weightKg > 350 ||
      heightCm == null ||
      !heightCm.isFinite ||
      heightCm < 80 ||
      heightCm > 250) {
    return null;
  }
  final stride = (heightCm / 100 * .40).clamp(.30, .75);
  var meters = steps * stride;
  if (distanceMeters != null &&
      distanceMeters.isFinite &&
      distanceMeters >= 0) {
    meters = math.min(meters, distanceMeters);
  }
  final km = meters / 1000;
  return WalkingEstimate(km, (km * weightKg * .45).floor());
}
