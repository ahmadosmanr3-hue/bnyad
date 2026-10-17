import 'dart:math';
import '../activity/step_widgets.dart';
import 'package:flutter/material.dart';
import 'package:nutrify/l10n/localized_time_picker.dart';
import 'package:nutrify/l10n/localized_numbers.dart';
import 'package:provider/provider.dart';
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/screens/body_fat_estimator_screen.dart';
import 'package:nutrify/widgets/auth_gate.dart';
import 'package:nutrify/screens/weekly_summary_screen.dart';
import 'package:nutrify/screens/shopping_list_screen.dart';
import 'package:nutrify/screens/medical_citations_screen.dart';
import 'package:nutrify/screens/notifications_screen.dart';
import 'package:nutrify/models/vitamin_entry.dart';
import 'package:nutrify/models/log_entry.dart';
import 'package:nutrify/models/meal.dart';
import 'package:nutrify/constants/food_database.dart';
import 'package:nutrify/utils/micro_display.dart';
import 'package:nutrify/utils/micro_nutrient_calculator.dart';
import 'package:nutrify/navigation/main_shell_tabs.dart';
import 'package:nutrify/theme/app_theme.dart';
import 'package:nutrify/utils/responsive.dart';
import 'package:nutrify/widgets/premium_gate.dart';
import 'package:nutrify/screens/premium_paywall_screen.dart';

class _PremiumFrame extends StatelessWidget {
  final bool isDark;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _PremiumFrame({
    required this.isDark,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    final outer = isDark
        ? [const Color(0xFF3D4152), const Color(0xFF1C1F2A)]
        : [const Color(0xFFDDD7CE), const Color(0xFFC9C2B6)];
    final inner = isDark ? const Color(0xFF0E1018) : const Color(0xFFFDFBF7);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF5C5348).withValues(alpha: 0.08),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: outer,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(1),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(27),
              child: ColoredBox(
                color: inner,
                child: Padding(padding: padding, child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final bool isDark;
  const _NotificationBell({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final unread = state.unreadNotificationCount;
    final color = isDark ? AppTheme.slate200 : AppTheme.slate700;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(Icons.notifications_none_rounded, color: color, size: 26),
          tooltip: state.t.get('notifications'),
          onPressed: () => guardAuth(context, () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const NotificationsScreen(),
              ),
            );
          }),
        ),
        if (unread > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.all(2),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFef4444),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isDark ? const Color(0xFF0E1018) : Colors.white,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  unread > 9 ? '9+' : '$unread',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AnimatedNutritionCard extends StatefulWidget {
  final bool isDark;
  final Color titleColor;
  final Color muted;
  final dynamic t;
  final int caloriesConsumed;
  final int caloriesGoal;
  final double percentage;
  final int carbs;
  final int protein;
  final int fat;
  final int carbGoal;
  final int proteinGoal;
  final int fatGoal;

  const _AnimatedNutritionCard({
    super.key,
    required this.isDark,
    required this.titleColor,
    required this.muted,
    required this.t,
    required this.caloriesConsumed,
    required this.caloriesGoal,
    required this.percentage,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.carbGoal,
    required this.proteinGoal,
    required this.fatGoal,
  });

  @override
  State<_AnimatedNutritionCard> createState() => _AnimatedNutritionCardState();
}

class _AnimatedNutritionCardState extends State<_AnimatedNutritionCard>
    with TickerProviderStateMixin {
  late final AnimationController _motion;
  late final AnimationController _ringLoop;
  late final List<Animation<double>> _macroStagger;

  @override
  void initState() {
    super.initState();
    _ringLoop = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _macroStagger = List.generate(3, (i) {
      final s = (0.22 + i * 0.11).clamp(0.0, 1.0);
      final e = (s + 0.28).clamp(0.0, 1.0);
      if (e <= s) return const AlwaysStoppedAnimation<double>(1);
      return CurvedAnimation(
        parent: _motion,
        curve: Interval(s, e, curve: Curves.easeOutCubic),
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _motion.forward();
    });
  }

  @override
  void dispose() {
    _motion.dispose();
    _ringLoop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final calorieHead = CurvedAnimation(
      parent: _motion,
      curve: const Interval(0.0, 0.38, curve: Curves.easeOutCubic),
    );
    final macroTitle = CurvedAnimation(
      parent: _motion,
      curve: const Interval(0.12, 0.45, curve: Curves.easeOut),
    );

    return _PremiumFrame(
      isDark: w.isDark,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      child: Column(
        children: [
          AnimatedBuilder(
            animation: calorieHead,
            builder: (_, _) {
              return Opacity(
                opacity: calorieHead.value,
                child: Transform.translate(
                  offset: Offset(0, 14 * (1 - calorieHead.value)),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            w.t.calories.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.4,
                              color: w.muted,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => showMedicalCitationsModal(context),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(
                                Icons.info_outline_rounded,
                                size: 14,
                                color: w.muted.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: SizedBox(
                          width: 192,
                          height: 192,
                          child: TweenAnimationBuilder<double>(
                            key: ValueKey(
                              'ring-${w.caloriesConsumed}-${w.caloriesGoal}',
                            ),
                            duration: const Duration(milliseconds: 1300),
                            curve: Curves.easeOutCubic,
                            tween: Tween<double>(begin: 0, end: w.percentage),
                            builder: (_, ringPct, child) {
                              return AnimatedBuilder(
                                animation: _ringLoop,
                                builder: (_, _) {
                                  return CustomPaint(
                                    painter: _CalorieRingPainter(
                                      percentage: ringPct,
                                      isDark: w.isDark,
                                      pulse: _ringLoop.value,
                                    ),
                                    child: child,
                                  );
                                },
                              );
                            },
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TweenAnimationBuilder<int>(
                                    key: ValueKey(
                                      'calkcal-${w.caloriesConsumed}',
                                    ),
                                    duration: const Duration(
                                      milliseconds: 1200,
                                    ),
                                    curve: Curves.easeOutCubic,
                                    tween: IntTween(
                                      begin: 0,
                                      end: w.caloriesConsumed,
                                    ),
                                    builder: (_, v, _) {
                                      return scaleDownText(
                                        '$v',
                                        style: TextStyle(
                                          fontSize: 36,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -1.5,
                                          color: w.titleColor,
                                          fontFeatures: const [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 2),
                                  scaleDownText(
                                    '${w.t.get('ofTotal').replaceAll('{total}', ltrFragment('${w.caloriesGoal}'))} ${w.t.kcal}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2,
                                      color: w.muted,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TweenAnimationBuilder<double>(
                        key: ValueKey(
                          'calpct-${w.caloriesConsumed}-${w.caloriesGoal}',
                        ),
                        duration: const Duration(milliseconds: 1100),
                        curve: Curves.easeOutCubic,
                        tween: Tween<double>(begin: 0, end: w.percentage),
                        builder: (_, calPct, _) {
                          return Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(999),
                                color: w.isDark
                                    ? AppTheme.indigo.withValues(alpha: 0.18)
                                    : AppTheme.indigo.withValues(alpha: 0.1),
                                border: Border.all(
                                  color: AppTheme.indigo.withValues(
                                    alpha: w.isDark ? 0.35 : 0.22,
                                  ),
                                ),
                              ),
                              child: Text(
                                '${(calPct * 100).round()}%',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.2,
                                  color: w.isDark
                                      ? AppTheme.indigoLight
                                      : AppTheme.indigoDark,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Consumer<AppState>(
            builder: (context, state, _) => DailyActivityWidget(
              tracker: state.steps,
              locale: state.lang,
              isDark: state.isDark,
              onTap: () => openStepDetails(
                context,
                state.steps,
                state.lang,
                state.isDark,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: AnimatedBuilder(
              animation: _motion,
              builder: (_, _) {
                final t = CurvedAnimation(
                  parent: _motion,
                  curve: const Interval(0.2, 0.5, curve: Curves.easeOut),
                );
                return Opacity(
                  opacity: t.value,
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: w.isDark
                        ? AppTheme.slate800.withValues(alpha: 0.85)
                        : AppTheme.slate200,
                  ),
                );
              },
            ),
          ),
          AnimatedBuilder(
            animation: macroTitle,
            builder: (_, _) {
              return Align(
                alignment: AlignmentDirectional.centerStart,
                child: Opacity(
                  opacity: macroTitle.value,
                  child: Transform.translate(
                    offset: Offset(8 * (1 - macroTitle.value), 0),
                    child: Text(
                      w.t.macronutrients.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.4,
                        color: w.muted,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AnimatedBuilder(
                  animation: _macroStagger[0],
                  builder: (_, _) => _MacroOrbCard(
                    animation: _macroStagger[0],
                    ringPulse: _ringLoop,
                    label: w.t.protein,
                    current: w.protein,
                    goal: w.proteinGoal,
                    unit: w.t.grams,
                    isDark: w.isDark,
                    icon: Icons.bolt_rounded,
                    colors: const [Color(0xFF6EE7B7), AppTheme.emeraldDeep],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AnimatedBuilder(
                  animation: _macroStagger[1],
                  builder: (_, _) => _MacroOrbCard(
                    animation: _macroStagger[1],
                    ringPulse: _ringLoop,
                    label: w.t.carbs,
                    current: w.carbs,
                    goal: w.carbGoal,
                    unit: w.t.grams,
                    isDark: w.isDark,
                    icon: Icons.grain_rounded,
                    colors: const [Color(0xFFFCD34D), AppTheme.amberDeep],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AnimatedBuilder(
                  animation: _macroStagger[2],
                  builder: (_, _) => _MacroOrbCard(
                    animation: _macroStagger[2],
                    ringPulse: _ringLoop,
                    label: w.t.fat,
                    current: w.fat,
                    goal: w.fatGoal,
                    unit: w.t.grams,
                    isDark: w.isDark,
                    icon: Icons.water_drop_rounded,
                    colors: const [AppTheme.roseSoft, AppTheme.rose],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroOrbCard extends StatelessWidget {
  final Animation<double> animation;
  final Animation<double> ringPulse;
  final String label;
  final int current;
  final int goal;
  final String unit;
  final bool isDark;
  final IconData icon;
  final List<Color> colors;

  const _MacroOrbCard({
    required this.animation,
    required this.ringPulse,
    required this.label,
    required this.current,
    required this.goal,
    required this.unit,
    required this.isDark,
    required this.icon,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    final pct = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
    final titleColor = isDark ? AppTheme.slate50 : AppTheme.slate900;
    final muted = isDark ? AppTheme.slate500 : AppTheme.slate600;
    final scale = 0.86 + 0.14 * animation.value;
    final y = 22 * (1 - animation.value);

    return Transform.translate(
      offset: Offset(0, y),
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: animation.value.clamp(0.0, 1.0),
          child: Container(
            padding: const EdgeInsets.fromLTRB(6, 12, 6, 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        colors.last.withValues(alpha: 0.2),
                        colors.first.withValues(alpha: 0.06),
                      ]
                    : [
                        colors.first.withValues(alpha: 0.22),
                        Colors.white.withValues(alpha: 0.35),
                      ],
              ),
              border: Border.all(
                color: colors.last.withValues(alpha: isDark ? 0.35 : 0.28),
              ),
              boxShadow: isDark
                  ? [
                      BoxShadow(
                        color: colors.last.withValues(alpha: 0.12),
                        blurRadius: 14,
                        spreadRadius: 0,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: colors.last.withValues(alpha: 0.14),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
            ),
            child: Column(
              children: [
                SizedBox(
                  width: 88,
                  height: 88,
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey('macro-$label-$current-$goal'),
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeOutCubic,
                    tween: Tween<double>(begin: 0, end: pct),
                    builder: (_, animatedPct, _) {
                      return AnimatedBuilder(
                        animation: ringPulse,
                        builder: (_, _) {
                          return CustomPaint(
                            painter: _MacroDonutPainter(
                              percentage: animatedPct,
                              isDark: isDark,
                              colors: colors,
                              pulse: ringPulse.value,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$current',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: titleColor,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '/$goal',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: muted,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 13, color: colors.last),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                          color: titleColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MacroDonutPainter extends CustomPainter {
  final double percentage;
  final bool isDark;
  final List<Color> colors;
  final double pulse;

  _MacroDonutPainter({
    required this.percentage,
    required this.isDark,
    required this.colors,
    this.pulse = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 8.0;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -pi / 2;

    final bgPaint = Paint()
      ..color = isDark ? AppTheme.navy750 : const Color(0xFFE0F5EC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawCircle(center, radius, bgPaint);

    if (percentage <= 0) return;

    final sweep = 2 * pi * percentage;

    _paintSmoothProgressArc(
      canvas: canvas,
      rect: rect,
      startAngle: startAngle,
      sweep: sweep,
      colors: colors.length >= 2
          ? [colors.first, colors.last]
          : [colors.first, colors.first],
      strokeWidth: strokeWidth,
    );
  }

  @override
  bool shouldRepaint(covariant _MacroDonutPainter old) =>
      old.percentage != percentage ||
      old.isDark != isDark ||
      old.colors != colors ||
      old.pulse != pulse;
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.t;
    final isDark = state.isDark;
    final stats = state.consumedStats;
    final caloriesGoal = state.goals?.calories ?? 2200;
    final caloriesConsumed = stats['calories'] ?? 0;
    final percentage = (caloriesConsumed / caloriesGoal).clamp(0.0, 1.0);

    final dateLabel = MaterialLocalizations.of(
      context,
    ).formatMediumDate(DateTime.now());
    final titleColor = isDark ? AppTheme.slate50 : AppTheme.slate900;
    final muted = isDark ? AppTheme.slate500 : AppTheme.slate500;
    final displayName = state.userDisplayName;
    final welcomeText = displayName.isNotEmpty
        ? t.welcomeName.replaceAll('{name}', displayName)
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (welcomeText != null) ...[
                      Text(
                        welcomeText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: AppTheme.indigo.withValues(
                            alpha: isDark ? 0.95 : 0.9,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      t.dashboard,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.0,
                        height: 1.05,
                        color: titleColor,
                        fontFeatures: const [FontFeature.enable('lnum')],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.champagne.withValues(
                                  alpha: isDark ? 0.9 : 0.75,
                                ),
                                AppTheme.indigo.withValues(alpha: 0.4),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          dateLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                            color: muted,
                            fontFeatures: const [FontFeature.enable('lnum')],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _NotificationBell(isDark: isDark),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _DashboardShortcutTile(
                  icon: Icons.calendar_view_week_rounded,
                  label: t.weeklySummary,
                  isDark: isDark,
                  onTap: () => guardAuth(context, () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const WeeklySummaryScreen(),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DashboardShortcutTile(
                  icon: Icons.shopping_bag_outlined,
                  label: t.shoppingList,
                  isDark: isDark,
                  onTap: () => guardAuth(context, () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ShoppingListScreen(),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DashboardShortcutTile(
                  icon: Icons.monitor_weight_outlined,
                  label: t.bodyFatShortcut,
                  isDark: isDark,
                  onTap: () => guardAuth(context, () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const BodyFatEstimatorScreen(),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          _AnimatedNutritionCard(
            key: ValueKey(
              'nutrition-goals-${state.goals?.calories}-${state.goals?.protein}-'
              '${state.goals?.carbs}-${state.goals?.fat}',
            ),
            isDark: isDark,
            titleColor: titleColor,
            muted: muted,
            t: t,
            caloriesConsumed: caloriesConsumed,
            caloriesGoal: caloriesGoal,
            percentage: percentage,
            carbs: stats['carbs'] ?? 0,
            protein: stats['protein'] ?? 0,
            fat: stats['fat'] ?? 0,
            carbGoal: state.goals?.carbs ?? 250,
            proteinGoal: state.goals?.protein ?? 120,
            fatGoal: state.goals?.fat ?? 70,
          ),

          const SizedBox(height: 18),

          TodaysMealsSection(state: state, isDark: isDark),

          const SizedBox(height: 16),

          GestureDetector(
            onTap: () {
              guardAuth(context, () {
                if (state.hasPremiumFeatures) {
                  _showVitaminSheet(context, state);
                } else {
                  showPremiumPaywall(context);
                }
              });
            },
            child: _PremiumFrame(
              isDark: isDark,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.indigo.withValues(
                            alpha: isDark ? 0.35 : 0.2,
                          ),
                          AppTheme.violet.withValues(
                            alpha: isDark ? 0.2 : 0.12,
                          ),
                        ],
                      ),
                    ),
                    child: Icon(
                      state.hasPremiumFeatures
                          ? Icons.biotech_rounded
                          : Icons.lock_rounded,
                      size: 22,
                      color: isDark
                          ? AppTheme.indigoLight
                          : AppTheme.indigoDark,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      t.nutrientsAndSupplements,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color: isDark ? AppTheme.slate50 : AppTheme.slate900,
                      ),
                    ),
                  ),
                  if (!state.hasPremiumFeatures) ...[
                    const PremiumBadge(compact: true),
                    const SizedBox(width: 6),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: isDark
                            ? AppTheme.indigo.withValues(alpha: 0.2)
                            : AppTheme.indigo.withValues(alpha: 0.1),
                      ),
                      child: Text(
                        '${state.vitamins.where((v) => v.taken).length}/${state.vitamins.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? AppTheme.indigoLight
                              : AppTheme.indigoDark,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Icon(
                    state.hasPremiumFeatures
                        ? Icons.expand_less_rounded
                        : Icons.chevron_right_rounded,
                    size: 22,
                    color: muted,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          _PremiumFrame(
            isDark: isDark,
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.cyan.withValues(alpha: isDark ? 0.35 : 0.25),
                        AppTheme.indigo.withValues(alpha: isDark ? 0.25 : 0.15),
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.water_drop_rounded,
                    color: isDark ? AppTheme.cyan : AppTheme.indigoDark,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.waterIntake.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 2,
                          color: muted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ltrFragment('${state.waterIntake} / ${state.dailyWaterTargetMl}')} ${t.ml}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppTheme.slate100 : AppTheme.slate800,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    _waterButton(
                      '-',
                      () => state.updateWater(max(0, state.waterIntake - 250)),
                      isDark,
                      false,
                    ),
                    const SizedBox(width: 8),
                    _waterButton(
                      '+',
                      () => state.updateWater(state.waterIntake + 250),
                      isDark,
                      true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (state.hasPremiumFeatures && state.healthGuidance != null)
            _PremiumFrame(
              isDark: isDark,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        size: 20,
                        color: isDark ? AppTheme.champagne : AppTheme.violet,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          t.aiGuidance.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2.2,
                            color: muted,
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          Icons.refresh_rounded,
                          size: 20,
                          color: muted,
                        ),
                        onPressed: () =>
                            state.generateHealthGuidance(state.userProfile),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.healthGuidance!,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.65,
                      color: isDark ? AppTheme.slate300 : AppTheme.slate600,
                    ),
                  ),
                ],
              ),
            )
          else if (!state.hasPremiumFeatures)
            GestureDetector(
              onTap: () => showPremiumPaywall(context),
              child: _PremiumFrame(
                isDark: isDark,
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 22,
                      color: isDark ? AppTheme.champagne : AppTheme.violet,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.aiGuidance.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.2,
                              color: muted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t.premiumPerkAiTips,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppTheme.slate100
                                  : AppTheme.slate800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const PremiumBadge(compact: true),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showVitaminSheet(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VitaminSheet(state: state),
    );
  }

  Widget _waterButton(
    String label,
    VoidCallback onTap,
    bool isDark,
    bool isPrimary,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isPrimary
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.indigoLight, AppTheme.indigoDark],
                )
              : null,
          color: isPrimary
              ? null
              : (isDark ? const Color(0xFF1A1D28) : const Color(0xFFEDEAE4)),
          border: isPrimary
              ? null
              : Border.all(
                  color: isDark ? AppTheme.slate700 : AppTheme.slate200,
                ),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: AppTheme.indigo.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isPrimary
                  ? Colors.white
                  : (isDark ? AppTheme.slate400 : AppTheme.slate600),
            ),
          ),
        ),
      ),
    );
  }
}

/// Public for focused layout regression tests without mounting the other
/// dashboard widgets (including their continuously animated progress rings).
class TodaysMealsSection extends StatelessWidget {
  final AppState state;
  final bool isDark;

  const TodaysMealsSection({
    super.key,
    required this.state,
    required this.isDark,
  });

  static const _mealIcons = {
    'breakfast': Icons.wb_sunny_outlined,
    'lunch': Icons.restaurant_outlined,
    'dinner': Icons.nightlight_outlined,
    'snacks': Icons.cookie_outlined,
  };

  static const _mealColors = {
    'breakfast': AppTheme.brandGold,
    'lunch': AppTheme.brandTeal,
    'dinner': AppTheme.brandTealDark,
    'snacks': AppTheme.brandLime,
  };

  @override
  Widget build(BuildContext context) {
    final t = state.t;
    final eatenMeals = state.eatenMeals;
    // Do not show AI-generated meal plan on the dashboard — only on Meal Plan.
    final placeholder = Meal(
      name: t.noMealPlanned,
      ingredients: const [],
      instructions: const [],
      calories: 0,
      protein: 0,
      carbs: 0,
      fat: 0,
    );

    return _PremiumFrame(
      isDark: isDark,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.restaurant_menu_rounded,
                size: 20,
                color: isDark
                    ? AppTheme.champagne.withValues(alpha: 0.85)
                    : AppTheme.indigoDark,
              ),
              const SizedBox(width: 10),
              Text(
                t.todaysMeals.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.4,
                  color: isDark ? AppTheme.slate500 : AppTheme.slate500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMealCard(
            context,
            'breakfast',
            t.breakfast,
            placeholder,
            eatenMeals.contains('breakfast'),
            false,
          ),
          const SizedBox(height: 14),
          _buildMealCard(
            context,
            'lunch',
            t.lunch,
            placeholder,
            eatenMeals.contains('lunch'),
            false,
          ),
          const SizedBox(height: 14),
          _buildMealCard(
            context,
            'dinner',
            t.dinner,
            placeholder,
            eatenMeals.contains('dinner'),
            false,
          ),
          const SizedBox(height: 14),
          _buildMealCard(
            context,
            'snacks',
            t.snacks,
            placeholder,
            eatenMeals.contains('snacks'),
            false,
          ),
          if (state.dailyLog.any((e) => e.mealId == null)) ...[
            const SizedBox(height: 18),
            _buildOtherFoodsCard(context, t),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => guardAuth(context, () => state.openFoodLog()),
              style: TextButton.styleFrom(
                backgroundColor: isDark
                    ? AppTheme.indigo.withValues(alpha: 0.14)
                    : AppTheme.indigo.withValues(alpha: 0.08),
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: BorderSide(
                  color: AppTheme.indigo.withValues(
                    alpha: isDark ? 0.35 : 0.22,
                  ),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    t.addFood,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                      color: isDark
                          ? AppTheme.indigoLight
                          : AppTheme.indigoDark,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: isDark ? AppTheme.indigoLight : AppTheme.indigoDark,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedFoodLines(
    BuildContext context,
    List<LogEntry> entries, {
    bool showSectionLabel = true,
  }) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(top: showSectionLabel ? 10 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showSectionLabel) ...[
            Text(
              state.t.loggedToday.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: isDark ? AppTheme.slate500 : AppTheme.slate500,
              ),
            ),
            const SizedBox(height: 6),
          ],
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Tooltip(
              message: entries[i].name,
              child: Text(
                entries[i].name,
                key: ValueKey('logged-food-name-${entries[i].id}'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                  color: isDark ? AppTheme.slate100 : AppTheme.slate800,
                ),
              ),
            ),
            const SizedBox(height: 4),
            // A wrapping footer keeps calories readable even with large RTL
            // text. The name never shares horizontal space with any controls.
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              children: [
                Text(
                  '${entries[i].calories.round()} ${state.t.kcal}',
                  key: ValueKey('logged-food-calories-${entries[i].id}'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppTheme.slate400 : AppTheme.slate600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      key: ValueKey('logged-food-info-${entries[i].id}'),
                      tooltip: entries[i].name,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      onPressed: () => _showLoggedFoodName(context, entries[i]),
                      icon: Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: isDark ? AppTheme.slate400 : AppTheme.slate600,
                      ),
                    ),
                    Material(
                      color: AppTheme.rose.withValues(alpha: isDark ? .16 : .1),
                      borderRadius: BorderRadius.circular(10),
                      child: IconButton(
                        key: ValueKey('logged-food-delete-${entries[i].id}'),
                        tooltip: state.t.remove,
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed: () =>
                            _confirmRemoveLogEntry(context, entries[i]),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                          color: AppTheme.rose,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showLoggedFoodName(BuildContext context, LogEntry entry) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        title: Text(state.t.foodLog),
        scrollable: true,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectableText(
              entry.name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.slate100 : AppTheme.slate800,
              ),
            ),
            const SizedBox(height: 12),
            Text('${entry.calories.round()} ${state.t.kcal}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(state.t.close),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemoveLogEntry(
    BuildContext context,
    LogEntry entry,
  ) async {
    final t = state.t;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        title: Text(
          t.removeLoggedTitle,
          style: TextStyle(color: isDark ? Colors.white : AppTheme.slate900),
        ),
        content: Text(
          t.removeLoggedBody.replaceAll('{name}', entry.name),
          style: TextStyle(
            color: isDark ? AppTheme.slate300 : AppTheme.slate700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              t.remove,
              style: const TextStyle(
                color: AppTheme.rose,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final saved = await state.removeLogEntry(entry.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(saved ? t.itemRemoved : t.saveFailed)),
      );
    }
  }

  Widget _buildMealCard(
    BuildContext context,
    String mealId,
    String label,
    Meal meal,
    bool isEaten,
    bool hasMealPlan,
  ) {
    final loggedForSlot = state.dailyLog
        .where((e) => e.mealId == mealId)
        .toList();
    final icon = _mealIcons[mealId] ?? Icons.restaurant;
    final color = _mealColors[mealId] ?? AppTheme.indigo;
    final muted = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final showPlanKcal = hasMealPlan && meal.calories > 0;
    final slotKcalTotal = loggedForSlot.fold<double>(
      0,
      (a, e) => a + e.calories,
    );
    final showMealSubtitle = hasMealPlan || loggedForSlot.isEmpty;
    final edgeColor = isEaten
        ? AppTheme.emerald.withValues(alpha: 0.28)
        : (isDark
              ? const Color(0xFF334155).withValues(alpha: 0.55)
              : const Color(0xFFE2E8F0));

    return GestureDetector(
      key: ValueKey('today-meal-$mealId'),
      behavior: HitTestBehavior.opaque,
      onTap: () => guardAuth(context, () => state.openFoodLog(mealId: mealId)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isEaten
                  ? (isDark
                        ? AppTheme.emerald.withValues(alpha: 0.08)
                        : const Color(0xFFF0FDF4))
                  : (isDark
                        ? const Color(0xFF1E293B).withValues(alpha: 0.45)
                        : Colors.white),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: edgeColor),
              boxShadow: isDark
                  ? null
                  : [
                      BoxShadow(
                        color: const Color(0xFF64748B).withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMealHeader(context, label, icon, color, isEaten),
                if (showMealSubtitle) ...[
                  const SizedBox(height: 8),
                  Tooltip(
                    message: meal.name,
                    child: Text(
                      meal.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: !hasMealPlan
                            ? muted
                            : (isDark ? Colors.white : const Color(0xFF1E293B)),
                        fontStyle: !hasMealPlan
                            ? FontStyle.italic
                            : FontStyle.normal,
                        decoration: isEaten ? TextDecoration.lineThrough : null,
                        decorationColor: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
                _buildLoggedFoodLines(context, loggedForSlot),
                if (!isEaten && (showPlanKcal || loggedForSlot.isNotEmpty)) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${showPlanKcal ? meal.calories : slotKcalTotal.round()} ${state.t.kcal}',
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: showPlanKcal ? 17 : 15,
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppTheme.indigoLight : AppTheme.indigo,
                    ),
                  ),
                ],
              ],
            ),
          ),
          PositionedDirectional(
            start: 0,
            top: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadiusDirectional.only(
                topStart: Radius.circular(20),
                bottomStart: Radius.circular(20),
              ),
              child: Container(width: 5, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealHeader(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    bool isEaten,
  ) {
    final mealIcon = Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? .18 : .12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, size: 22, color: color),
    );
    final mealLabel = Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        letterSpacing: .8,
        color: color,
      ),
    );
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.emerald.withValues(alpha: isDark ? .15 : .1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 14, color: AppTheme.emerald),
          const SizedBox(width: 4),
          Text(
            state.t.eaten,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppTheme.emerald,
            ),
          ),
        ],
      ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackStatus =
            constraints.maxWidth < 200 ||
            (constraints.maxWidth < 280 &&
                MediaQuery.textScalerOf(context).scale(11) > 14);
        final heading = Row(
          children: [
            mealIcon,
            const SizedBox(width: 12),
            Expanded(child: mealLabel),
            if (isEaten && !stackStatus) ...[const SizedBox(width: 8), badge],
          ],
        );
        if (!isEaten || !stackStatus) return heading;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            heading,
            const SizedBox(height: 6),
            Align(alignment: AlignmentDirectional.centerEnd, child: badge),
          ],
        );
      },
    );
  }

  Widget _buildOtherFoodsCard(BuildContext context, dynamic t) {
    final entries = state.dailyLog.where((e) => e.mealId == null).toList();
    final slate = isDark ? const Color(0xFF64748B) : const Color(0xFF475569);
    final totalKcal = entries.fold<double>(0, (a, e) => a + e.calories);

    final edge = isDark
        ? const Color(0xFF475569).withValues(alpha: 0.5)
        : const Color(0xFFE2E8F0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          guardAuth(context, () => state.setActiveTab(MainShellTab.foodLog)),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.45)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: edge),
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.restaurant_menu, size: 18, color: slate),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t.otherFoods,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          color: slate,
                        ),
                      ),
                    ),
                    Text(
                      '${totalKcal.round()} ${state.t.kcal}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppTheme.slate300 : AppTheme.slate700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  t.otherFoodsHint,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                    color: isDark ? AppTheme.slate500 : AppTheme.slate500,
                  ),
                ),
                if (entries.isNotEmpty) const SizedBox(height: 8),
                _buildLoggedFoodLines(
                  context,
                  entries,
                  showSectionLabel: false,
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: Container(width: 5, color: slate.withValues(alpha: 0.75)),
            ),
          ),
        ],
      ),
    );
  }
}

class _VitaminSheet extends StatefulWidget {
  final AppState state;
  const _VitaminSheet({required this.state});

  @override
  State<_VitaminSheet> createState() => _VitaminSheetState();
}

class _VitaminSheetState extends State<_VitaminSheet>
    with SingleTickerProviderStateMixin {
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  late final TabController _tabCtrl;
  bool _reminderOnAdd = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  void _addVitamin() {
    final name = _nameCtrl.text.trim();
    final dosage = _dosageCtrl.text.trim();
    if (name.isEmpty) return;
    widget.state.addVitamin(
      VitaminEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        dosage: dosage.isEmpty ? '1x' : dosage,
        reminderEnabled: _reminderOnAdd,
        reminderHour: _reminderOnAdd ? _reminderTime.hour : null,
        reminderMinute: _reminderOnAdd ? _reminderTime.minute : null,
      ),
    );
    _nameCtrl.clear();
    _dosageCtrl.clear();
    _reminderOnAdd = false;
    setState(() {});
  }

  String _formatGoal(double value) {
    if (value >= 100) return value.toStringAsFixed(0);
    if (value >= 10) return value.toStringAsFixed(1);
    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final t = state.t;
    final isDark = state.isDark;
    final vitamins = state.vitamins;
    final micros = state.dailyMicronutrients;

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(Icons.science, size: 22, color: AppTheme.indigo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t.nutrientsAndSupplements,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabCtrl,
              onTap: (_) => setState(() {}),
              indicator: BoxDecoration(
                color: AppTheme.indigo,
                borderRadius: BorderRadius.circular(14),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerHeight: 0,
              labelColor: Colors.white,
              unselectedLabelColor: isDark
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFF64748B),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: [
                Tab(text: t.fromFood),
                Tab(text: t.supplements),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildNutrientsTab(isDark, micros),
                _buildSupplementsTab(isDark, vitamins, state, t),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientsTab(bool isDark, Map<String, double> micros) {
    final goals = widget.state.dailyMicroGoals;
    final keys = kTrackedMicroKeys;
    final hasAnyIntake = micros.values.any((v) => v > 0);

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        if (!hasAnyIntake)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              widget.state.t.logFoodForNutrients,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ),
        ...keys.map((key) {
          final current = micros[key] ?? 0;
          final goal = goals[key] ?? dailyRecommended[key] ?? 1;
          final pct = microProgressPct(key, current, goal);
          final barPct = pct.clamp(0.0, 1.0);
          final isOverLimit =
              kMicroUpperLimitKeys.contains(key) && current > goal;
          final isOverTarget =
              !kMicroUpperLimitKeys.contains(key) && current > goal;
          final unit = microUnits[key] ?? '';
          final color = isOverLimit
              ? AppTheme.rose
              : isOverTarget
              ? AppTheme.amberDeep
              : microColor(key);
          final t = widget.state.t;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.4)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155).withValues(alpha: 0.5)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        microLabel(t, key),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Text(
                      '${_formatGoal(current)} / ${_formatGoal(goal)} $unit',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: barPct,
                    minHeight: 6,
                    backgroundColor: isDark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    microProgressLabel(key, current, goal),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: color.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSupplementsTab(
    bool isDark,
    List<VitaminEntry> vitamins,
    AppState state,
    dynamic t,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    hintText: t.vitaminName,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _dosageCtrl,
                  decoration: InputDecoration(
                    hintText: t.dosage,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _addVitamin,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.indigo,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  t.enableReminder,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
              if (_reminderOnAdd)
                GestureDetector(
                  onTap: () async {
                    final picked = await showBnyadTimePicker(
                      context: context,
                      initialTime: _reminderTime,
                    );
                    if (picked != null) {
                      setState(() => _reminderTime = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.indigo,
                      ),
                    ),
                  ),
                ),
              Switch(
                value: _reminderOnAdd,
                onChanged: (v) => setState(() => _reminderOnAdd = v),
                activeTrackColor: AppTheme.indigo,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  t.enableReminder,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
              if (_reminderOnAdd)
                GestureDetector(
                  onTap: () async {
                    final picked = await showBnyadTimePicker(
                      context: context,
                      initialTime: _reminderTime,
                    );
                    if (picked != null) {
                      setState(() => _reminderTime = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.indigo,
                      ),
                    ),
                  ),
                ),
              Switch(
                value: _reminderOnAdd,
                onChanged: (v) => setState(() => _reminderOnAdd = v),
                activeTrackColor: AppTheme.indigo,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: vitamins.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.medication_outlined,
                        size: 48,
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t.noVitamins,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFF64748B)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.noVitaminsDesc,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF475569)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: vitamins.length,
                  itemBuilder: (_, i) {
                    final v = vitamins[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: v.taken
                            ? (isDark
                                  ? AppTheme.emerald.withValues(alpha: 0.1)
                                  : const Color(0xFFF0FDF4))
                            : (isDark
                                  ? const Color(
                                      0xFF1E293B,
                                    ).withValues(alpha: 0.5)
                                  : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: v.taken
                              ? AppTheme.emerald.withValues(alpha: 0.3)
                              : (isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  state.toggleVitaminTaken(v.id);
                                  setState(() {});
                                },
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: v.taken
                                        ? AppTheme.emerald
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: v.taken
                                          ? AppTheme.emerald
                                          : (isDark
                                                ? const Color(0xFF475569)
                                                : const Color(0xFFCBD5E1)),
                                      width: 2,
                                    ),
                                  ),
                                  child: v.taken
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      v.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1E293B),
                                        decoration: v.taken
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                    Text(
                                      v.dosage,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? const Color(0xFF64748B)
                                            : const Color(0xFF94A3B8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: isDark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFFCBD5E1),
                                ),
                                onPressed: () {
                                  state.removeVitamin(v.id);
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                Icons.notifications_outlined,
                                size: 14,
                                color: isDark
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                t.enableReminder,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                              const Spacer(),
                              if (v.reminderEnabled)
                                GestureDetector(
                                  onTap: () async {
                                    final initial = TimeOfDay(
                                      hour: v.reminderHour ?? 8,
                                      minute: v.reminderMinute ?? 0,
                                    );
                                    final picked = await showBnyadTimePicker(
                                      context: context,
                                      initialTime: initial,
                                    );
                                    if (picked != null) {
                                      await state.setVitaminReminder(
                                        v.id,
                                        enabled: true,
                                        time: picked,
                                      );
                                      setState(() {});
                                    }
                                  },
                                  child: Text(
                                    '${(v.reminderHour ?? 8).toString().padLeft(2, '0')}:${(v.reminderMinute ?? 0).toString().padLeft(2, '0')}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.indigo,
                                    ),
                                  ),
                                ),
                              Switch(
                                value: v.reminderEnabled,
                                onChanged: (val) async {
                                  await state.setVitaminReminder(
                                    v.id,
                                    enabled: val,
                                    time: TimeOfDay(
                                      hour: v.reminderHour ?? 8,
                                      minute: v.reminderMinute ?? 0,
                                    ),
                                  );
                                  setState(() {});
                                },
                                activeTrackColor: AppTheme.indigo,
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _DashboardShortcutTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _DashboardShortcutTile({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDark
        ? Border.all(color: AppTheme.slate700.withValues(alpha: 0.85))
        : Border.all(color: AppTheme.slate200);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1A1D28), const Color(0xFF12141C)]
                  : [Colors.white, const Color(0xFFF5F2ED)],
            ),
            border: border,
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFF5C5348).withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isDark
                      ? AppTheme.indigo.withValues(alpha: 0.15)
                      : AppTheme.indigo.withValues(alpha: 0.08),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isDark ? AppTheme.indigoLight : AppTheme.indigoDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                    color: isDark ? AppTheme.slate50 : AppTheme.slate900,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isDark ? AppTheme.slate500 : AppTheme.slate400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Solid progress arc with a smooth linear gradient (no sweep-gradient seam).
void _paintSmoothProgressArc({
  required Canvas canvas,
  required Rect rect,
  required double startAngle,
  required double sweep,
  required List<Color> colors,
  required double strokeWidth,
}) {
  if (sweep <= 0) return;

  final center = rect.center;
  final radius = rect.width / 2;
  final start = Offset(
    center.dx + radius * cos(startAngle),
    center.dy + radius * sin(startAngle),
  );
  final end = Offset(
    center.dx + radius * cos(startAngle + sweep),
    center.dy + radius * sin(startAngle + sweep),
  );

  Alignment toAlignment(Offset point) => Alignment(
    ((point.dx - center.dx) / (rect.width / 2)).clamp(-1.0, 1.0),
    ((point.dy - center.dy) / (rect.height / 2)).clamp(-1.0, 1.0),
  );

  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeWidth
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true
    ..shader = LinearGradient(
      colors: colors.length >= 2 ? colors : [colors.first, colors.first],
      begin: toAlignment(start),
      end: toAlignment(end),
    ).createShader(rect);

  canvas.drawArc(rect, startAngle, sweep, false, paint);
}

class _CalorieRingPainter extends CustomPainter {
  final double percentage;
  final bool isDark;
  final double pulse;

  _CalorieRingPainter({
    required this.percentage,
    required this.isDark,
    this.pulse = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;
    const strokeWidth = 11.0;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -pi / 2;

    final bgPaint = Paint()
      ..color = isDark ? const Color(0xFF252836) : const Color(0xFFE8E4DD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;
    canvas.drawCircle(center, radius, bgPaint);

    if (percentage <= 0) return;

    final sweep = 2 * pi * percentage;

    _paintSmoothProgressArc(
      canvas: canvas,
      rect: rect,
      startAngle: startAngle,
      sweep: sweep,
      colors: const [
        AppTheme.brandOrange,
        AppTheme.brandGold,
        AppTheme.brandOrangeDeep,
      ],
      strokeWidth: strokeWidth,
    );
  }

  @override
  bool shouldRepaint(covariant _CalorieRingPainter old) =>
      old.percentage != percentage ||
      old.isDark != isDark ||
      old.pulse != pulse;
}
