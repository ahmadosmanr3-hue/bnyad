import 'package:nutrify/models/nutritional_goals.dart';
import 'package:nutrify/models/user_profile.dart';

class WeeklyDayStat {
  final String dateKey;
  final String weekdayShort;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final bool logged;
  final bool onGoal;

  const WeeklyDayStat({
    required this.dateKey,
    required this.weekdayShort,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.logged,
    required this.onGoal,
  });
}

class WeeklySummaryStats {
  final List<WeeklyDayStat> days;
  final int daysLogged;
  final int loggingStreak;
  final int goalHitDays;
  final int avgCalories;
  final int avgProtein;
  final int avgCarbs;
  final int avgFat;
  final int calorieGoal;
  final double? weightStartKg;
  final double? weightEndKg;
  final double? weightDeltaKg;
  final String weekRangeLabel;
  final String userGoal;

  const WeeklySummaryStats({
    required this.days,
    required this.daysLogged,
    required this.loggingStreak,
    required this.goalHitDays,
    required this.avgCalories,
    required this.avgProtein,
    required this.avgCarbs,
    required this.avgFat,
    required this.calorieGoal,
    this.weightStartKg,
    this.weightEndKg,
    this.weightDeltaKg,
    required this.weekRangeLabel,
    required this.userGoal,
  });

  bool get hasWeightDelta => weightDeltaKg != null;
}

int computeLoggingStreak(Map<String, Map<String, int>> history) {
  var streak = 0;
  var day = DateTime.now();
  for (var i = 0; i < 400; i++) {
    final key = _dateKey(day);
    final cal = history[key]?['calories'] ?? 0;
    if (cal <= 0) break;
    streak++;
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
}

bool isOnCalorieGoal({
  required int consumed,
  required int goal,
  required String userGoal,
}) {
  if (goal <= 0) return consumed > 0;
  switch (userGoal) {
    case 'loseWeight':
      return consumed <= goal && consumed >= (goal * 0.65).round();
    case 'gainWeight':
    case 'gainMuscle':
      return consumed >= (goal * 0.85).round();
    case 'athletic':
      return consumed >= (goal * 0.8).round() && consumed <= (goal * 1.15).round();
    default:
      final diff = (consumed - goal).abs();
      return diff <= (goal * 0.15).round();
  }
}

String _dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime _parseDateKey(String key) {
  final p = key.split('-');
  if (p.length != 3) return DateTime.now();
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

String _weekdayShort(DateTime d, String lang) {
  const en = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const ar = ['إث', 'ثل', 'أر', 'خم', 'جم', 'سب', 'أح'];
  const ku = ['دو', 'سێ', 'چو', 'پێ', 'هە', 'شە', 'یە'];
  final i = (d.weekday - 1).clamp(0, 6);
  if (lang == 'ar') return ar[i];
  if (lang == 'ku') return ku[i];
  return en[i];
}

String _weekRangeLabel(List<String> keys, String lang) {
  if (keys.isEmpty) return '';
  final start = _parseDateKey(keys.first);
  final end = _parseDateKey(keys.last);
  String month(int m) {
    const en = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const ar = ['ين', 'فبر', 'مار', 'أبر', 'ماي', 'يون', 'يول', 'أغس', 'سب', 'أكت', 'نوف', 'ديس'];
    if (lang == 'ar') return ar[m - 1];
    return en[m - 1];
  }
  if (start.month == end.month) {
    return '${start.day}–${end.day} ${month(end.month)}';
  }
  return '${start.day} ${month(start.month)} – ${end.day} ${month(end.month)}';
}

WeeklySummaryStats buildWeeklySummaryStats({
  required List<String> dateKeys,
  required Map<String, Map<String, int>> nutritionHistory,
  required Map<String, double> weightHistory,
  UserProfile? profile,
  NutritionalGoals? goals,
  required String lang,
}) {
  final calorieGoal = goals?.calories ?? profile?.dailyCalories ?? 2000;
  final userGoal = profile?.goal ?? 'stayHealthy';

  final days = <WeeklyDayStat>[];
  var totalCal = 0;
  var totalPro = 0;
  var totalCar = 0;
  var totalFat = 0;
  var daysLogged = 0;
  var goalHitDays = 0;

  for (final key in dateKeys) {
    final m = nutritionHistory[key];
    final cal = m?['calories'] ?? 0;
    final pro = m?['protein'] ?? 0;
    final car = m?['carbs'] ?? 0;
    final fat = m?['fat'] ?? 0;
    final logged = cal > 0;
    if (logged) {
      daysLogged++;
      totalCal += cal;
      totalPro += pro;
      totalCar += car;
      totalFat += fat;
    }
    final onGoal = logged &&
        isOnCalorieGoal(consumed: cal, goal: calorieGoal, userGoal: userGoal);
    if (onGoal) goalHitDays++;

    days.add(WeeklyDayStat(
      dateKey: key,
      weekdayShort: _weekdayShort(_parseDateKey(key), lang),
      calories: cal,
      protein: pro,
      carbs: car,
      fat: fat,
      logged: logged,
      onGoal: onGoal,
    ));
  }

  double? weightStart;
  for (final key in dateKeys) {
    final w = weightHistory[key];
    if (w != null) {
      weightStart ??= w;
    }
  }
  if (weightStart == null && dateKeys.isNotEmpty) {
    final before = _parseDateKey(dateKeys.first).subtract(const Duration(days: 1));
    weightStart = weightHistory[_dateKey(before)];
  }

  final lastKey = dateKeys.isNotEmpty ? dateKeys.last : _dateKey(DateTime.now());
  final weightEnd = weightHistory[lastKey] ?? profile?.weight;

  double? delta;
  if (weightStart != null && weightEnd != null) {
    delta = weightEnd - weightStart;
    if (delta.abs() < 0.05) delta = 0;
  }

  return WeeklySummaryStats(
    days: days,
    daysLogged: daysLogged,
    loggingStreak: computeLoggingStreak(nutritionHistory),
    goalHitDays: goalHitDays,
    avgCalories: daysLogged == 0 ? 0 : (totalCal / daysLogged).round(),
    avgProtein: daysLogged == 0 ? 0 : (totalPro / daysLogged).round(),
    avgCarbs: daysLogged == 0 ? 0 : (totalCar / daysLogged).round(),
    avgFat: daysLogged == 0 ? 0 : (totalFat / daysLogged).round(),
    calorieGoal: calorieGoal,
    weightStartKg: weightStart,
    weightEndKg: weightEnd,
    weightDeltaKg: delta,
    weekRangeLabel: _weekRangeLabel(dateKeys, lang),
    userGoal: userGoal,
  );
}
