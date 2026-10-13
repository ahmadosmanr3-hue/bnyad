import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/theme/app_theme.dart';
import 'package:nutrify/utils/weekly_summary_stats.dart';

class WeeklySummaryScreen extends StatefulWidget {
  const WeeklySummaryScreen({super.key});

  @override
  State<WeeklySummaryScreen> createState() => _WeeklySummaryScreenState();
}

class _WeeklySummaryScreenState extends State<WeeklySummaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<AppState>();
      if (state.isLoggedIn && !state.isMockUser && state.isOnline) {
        state.refreshNutritionHistoryFromCloud();
      }
    });
  }

  Future<void> _promptUpdateWeight(AppState state) async {
    final t = state.t;
    final current = state.userProfile?.weight ?? 70.0;
    final controller = TextEditingController(
      text: current == current.roundToDouble() ? '${current.round()}' : current.toStringAsFixed(1),
    );

    final value = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.weeklyUpdateWeight),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            labelText: t.weight,
            suffixText: 'kg',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel)),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(controller.text.trim().replaceAll(',', '.'));
              if (v == null || v <= 0) return;
              Navigator.pop(ctx, v);
            },
            child: Text(t.save),
          ),
        ],
      ),
    );

    controller.dispose();
    if (value != null) {
      await state.recordTodayWeight(value);
    }
  }

  String _weightDeltaLabel(dynamic t, WeeklySummaryStats stats) {
    final d = stats.weightDeltaKg;
    if (d == null) return t.weeklyLogWeightHint;
    if (d == 0) return t.weeklyWeightStable;
    final abs = d.abs().toStringAsFixed(1);
    if (d < 0) return '$abs kg ${t.weeklyWeightLost}';
    return '$abs kg ${t.weeklyWeightGained}';
  }

  String _heroInsight(dynamic t, WeeklySummaryStats stats) {
    final highlights = <String>[];
    if (stats.loggingStreak > 0) {
      highlights.add('${stats.loggingStreak} ${t.weeklyDayStreak}');
    }
    if (stats.weightDeltaKg != null && stats.weightDeltaKg != 0) {
      highlights.add(_weightDeltaLabel(t, stats));
    } else if (stats.daysLogged >= 5) {
      highlights.add('${stats.daysLogged}/7 ${t.weeklyDaysLoggedHint}');
    }
    if (stats.goalHitDays >= 3) {
      highlights.add('${stats.goalHitDays}/7 ${t.weeklyOnTarget}');
    }
    if (highlights.isEmpty) {
      return stats.loggingStreak == 0 ? t.weeklyStreakStart : t.weeklySummarySubtitle;
    }
    return highlights.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.t;
    final isDark = state.isDark;

    final stats = buildWeeklySummaryStats(
      dateKeys: state.last7DateKeys(),
      nutritionHistory: state.nutritionHistory,
      weightHistory: state.weightHistory,
      profile: state.userProfile,
      goals: state.goals,
      lang: state.lang,
    );

    final maxCal = stats.days.fold<int>(
      stats.calorieGoal,
      (m, d) => d.calories > m ? d.calories : m,
    );

    return Scaffold(
      backgroundColor: isDark ? AppTheme.slate950 : AppTheme.slate50,
      appBar: AppBar(
        title: Text(t.weeklySummary),
        actions: [
          IconButton(
            tooltip: t.weeklyUpdateWeight,
            onPressed: () => _promptUpdateWeight(state),
            icon: const Icon(Icons.monitor_weight_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            stats.weekRangeLabel,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : AppTheme.slate900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t.weeklySummarySubtitle,
            style: TextStyle(fontSize: 14, color: isDark ? AppTheme.slate400 : AppTheme.slate600),
          ),
          if (!state.isOnline) ...[
            const SizedBox(height: 12),
            Text(t.offlineBanner, style: const TextStyle(fontSize: 12, color: AppTheme.amber)),
          ],
          const SizedBox(height: 16),
          _WeeklyHero(
            isDark: isDark,
            insight: _heroInsight(t, stats),
            streak: stats.loggingStreak,
          ),
          const SizedBox(height: 20),
          _ProgressGrid(
            isDark: isDark,
            stats: stats,
            t: t,
            weightSubtitle: _weightDeltaLabel(t, stats),
          ),
          const SizedBox(height: 24),
          Text(
            t.weeklyCalorieChart,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: isDark ? AppTheme.slate500 : AppTheme.slate600,
            ),
          ),
          const SizedBox(height: 12),
          _CalorieChart(
            days: stats.days,
            maxCal: maxCal,
            goal: stats.calorieGoal,
            isDark: isDark,
            kcalLabel: t.kcal,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _legendDot(AppTheme.indigo, t.calories, isDark),
              const SizedBox(width: 16),
              _legendDot(AppTheme.emerald.withValues(alpha: 0.55), t.goals, isDark, dashed: true),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: t.weeklyAvgCalories,
                  value: '${stats.avgCalories}',
                  suffix: t.kcal,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  label: t.protein,
                  value: '${stats.avgProtein}g',
                  suffix: '',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: t.carbs,
                  value: '${stats.avgCarbs}g',
                  suffix: '',
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  label: t.fat,
                  value: '${stats.avgFat}g',
                  suffix: '',
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            t.weeklyDailyBreakdown,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: isDark ? AppTheme.slate500 : AppTheme.slate600,
            ),
          ),
          const SizedBox(height: 12),
          ...stats.days.reversed.map(
            (d) => _DayRow(day: d, goal: stats.calorieGoal, isDark: isDark, t: t),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _promptUpdateWeight(state),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(t.weeklyUpdateWeight),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label, bool isDark, {bool dashed = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: dashed ? 2 : 12,
          decoration: BoxDecoration(
            color: dashed ? color : color,
            borderRadius: BorderRadius.circular(dashed ? 1 : 3),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 11, color: isDark ? AppTheme.slate400 : AppTheme.slate600)),
      ],
    );
  }
}

class _ProgressGrid extends StatelessWidget {
  final bool isDark;
  final WeeklySummaryStats stats;
  final dynamic t;
  final String weightSubtitle;

  const _ProgressGrid({
    required this.isDark,
    required this.stats,
    required this.t,
    required this.weightSubtitle,
  });

  @override
  Widget build(BuildContext context) {
    final weightValue = stats.weightDeltaKg == null
        ? '—'
        : stats.weightDeltaKg == 0
            ? '0 kg'
            : '${stats.weightDeltaKg! > 0 ? '+' : ''}${stats.weightDeltaKg!.toStringAsFixed(1)} kg';

    final streakSubtitle = stats.loggingStreak > 0 ? t.weeklyDayStreak : t.weeklyStreakStart;

    Color weightColor = AppTheme.indigo;
    if (stats.weightDeltaKg != null && stats.weightDeltaKg != 0) {
      final losing = stats.userGoal == 'loseWeight';
      final gained = stats.weightDeltaKg! > 0;
      final good = losing ? !gained : gained;
      weightColor = good ? AppTheme.emerald : AppTheme.amber;
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _HighlightCard(
                icon: Icons.local_fire_department_rounded,
                iconColor: AppTheme.amber,
                label: t.weeklyStreak,
                value: '${stats.loggingStreak}',
                subtitle: streakSubtitle,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _HighlightCard(
                icon: Icons.monitor_weight_outlined,
                iconColor: weightColor,
                label: t.weeklyWeightChange,
                value: weightValue,
                subtitle: weightSubtitle,
                isDark: isDark,
                subtitleSmall: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _HighlightCard(
                icon: Icons.check_circle_outline_rounded,
                iconColor: AppTheme.emerald,
                label: t.weeklyDaysLogged,
                value: '${stats.daysLogged}/7',
                subtitle: t.weeklyDaysLoggedHint,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _HighlightCard(
                icon: Icons.flag_outlined,
                iconColor: AppTheme.indigoLight,
                label: t.weeklyGoalDays,
                value: '${stats.goalHitDays}/7',
                subtitle: t.weeklyOnTarget,
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WeeklyHero extends StatelessWidget {
  final bool isDark;
  final String insight;
  final int streak;

  const _WeeklyHero({
    required this.isDark,
    required this.insight,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [AppTheme.indigo.withValues(alpha: 0.35), AppTheme.slate900]
              : [AppTheme.indigo.withValues(alpha: 0.12), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? AppTheme.slate800 : AppTheme.indigo.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.amber.withValues(alpha: isDark ? 0.2 : 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              streak >= 7 ? Icons.emoji_events_rounded : Icons.insights_rounded,
              color: streak >= 7 ? AppTheme.amber : AppTheme.indigoLight,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              insight,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppTheme.slate800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;
  final bool isDark;
  final bool subtitleSmall;

  const _HighlightCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.isDark,
    this.subtitleSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.slate900 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppTheme.slate800 : AppTheme.slate200),
        boxShadow: isDark
            ? null
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.slate500 : AppTheme.slate600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              height: 1,
              color: isDark ? Colors.white : AppTheme.slate900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            maxLines: subtitleSmall ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: subtitleSmall ? 10 : 11,
              height: 1.25,
              color: isDark ? AppTheme.slate500 : AppTheme.slate500,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalorieChart extends StatelessWidget {
  final List<WeeklyDayStat> days;
  final int maxCal;
  final int goal;
  final bool isDark;
  final String kcalLabel;

  const _CalorieChart({
    required this.days,
    required this.maxCal,
    required this.goal,
    required this.isDark,
    required this.kcalLabel,
  });

  @override
  Widget build(BuildContext context) {
    final chartMax = (maxCal * 1.1).clamp(goal.toDouble(), 4000.0);
    final goalLine = goal / chartMax;

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.slate900 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppTheme.slate800 : AppTheme.slate200),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final goalTop = (1 - goalLine) * 140;
          return Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: 16 + goalTop,
                child: Container(
                  height: 1.5,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppTheme.emerald.withValues(alpha: 0.45),
                        width: 1.5,
                        strokeAlign: BorderSide.strokeAlignCenter,
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: days.map((d) {
                  final h = d.calories <= 0
                      ? 6.0
                      : (d.calories / chartMax * 140).clamp(8.0, 140.0);
                  final barColor = !d.logged
                      ? (isDark ? AppTheme.slate800 : AppTheme.slate200)
                      : d.onGoal
                          ? AppTheme.indigo
                          : AppTheme.amber;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (d.logged)
                            Text(
                              '${d.calories}',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: isDark ? AppTheme.slate500 : AppTheme.slate600,
                              ),
                            )
                          else
                            const SizedBox(height: 12),
                          const SizedBox(height: 4),
                          Container(
                            height: h,
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            d.weekdayShort,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppTheme.slate400 : AppTheme.slate600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final String suffix;
  final bool isDark;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.suffix,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.slate900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.slate800 : AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isDark ? AppTheme.slate500 : AppTheme.slate600)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: isDark ? AppTheme.indigoLight : AppTheme.indigo),
              ),
              if (suffix.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(suffix, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? AppTheme.slate500 : AppTheme.slate600)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final WeeklyDayStat day;
  final int goal;
  final bool isDark;
  final dynamic t;

  const _DayRow({
    required this.day,
    required this.goal,
    required this.isDark,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal > 0 ? (day.calories / goal).clamp(0.0, 1.2) : 0.0;
    final progressClamped = progress.clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.slate900 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppTheme.slate800 : AppTheme.slate200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: day.logged
                      ? AppTheme.indigo.withValues(alpha: isDark ? 0.2 : 0.12)
                      : (isDark ? AppTheme.slate800 : AppTheme.slate100),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  day.weekdayShort,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: day.logged ? AppTheme.indigoLight : (isDark ? AppTheme.slate500 : AppTheme.slate600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      day.dateKey,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isDark ? Colors.white : AppTheme.slate900,
                      ),
                    ),
                    Text(
                      day.logged
                          ? '${day.calories} ${t.kcal} · P${day.protein} C${day.carbs} F${day.fat}'
                          : '—',
                      style: TextStyle(fontSize: 11, color: isDark ? AppTheme.slate500 : AppTheme.slate600),
                    ),
                  ],
                ),
              ),
              if (day.logged && day.onGoal)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.emerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    t.weeklyOnTarget,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.emerald),
                  ),
                ),
            ],
          ),
          if (day.logged) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressClamped,
                minHeight: 6,
                backgroundColor: isDark ? AppTheme.slate800 : AppTheme.slate100,
                color: day.onGoal ? AppTheme.indigo : AppTheme.amber,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
