import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'step_models.dart';
import 'step_strings.dart';
import 'step_tracker.dart';

class DailyActivityWidget extends StatelessWidget {
  final StepTracker tracker;
  final String locale;
  final bool isDark;
  final VoidCallback? onTap;
  const DailyActivityWidget({
    super.key,
    required this.tracker,
    required this.locale,
    required this.isDark,
    this.onTap,
  });
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: tracker,
    builder: (context, _) {
      final s = StepStrings(locale), count = tracker.todaySteps;
      final ink = isDark ? AppTheme.slate100 : AppTheme.slate800;
      final muted = isDark ? AppTheme.slate400 : AppTheme.slate600;
      return Semantics(
        button: onTap != null,
        child: Material(
          color: isDark
              ? AppTheme.brandTeal.withValues(alpha: .10)
              : AppTheme.brandTeal.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            key: const ValueKey('daily-activity'),
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_walk_rounded,
                        size: 20,
                        color: AppTheme.brandTeal,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.text('activity'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: ink,
                          ),
                        ),
                      ),
                      if (onTap != null)
                        const Icon(
                          // This IconData mirrors itself in RTL.
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: AppTheme.brandTeal,
                        ),
                    ],
                  ),
                  if (tracker.simulated)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        s.text('demo'),
                        key: const ValueKey('simulated-steps'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: muted,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (count != null) ...[
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          '$count / ${tracker.goal} ${s.text('steps')}',
                          key: const ValueKey('step-count'),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: ink,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        Text(
                          '${(tracker.progress * 100).round()}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: ExcludeSemantics(
                        child: LinearProgressIndicator(
                          value: tracker.progress,
                          minHeight: 5,
                          color: AppTheme.brandTeal,
                          backgroundColor: AppTheme.brandTeal.withValues(
                            alpha: .12,
                          ),
                          semanticsLabel: s.text('activity'),
                          semanticsValue:
                              '${(tracker.progress * 100).round()}%',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${s.text('estimated')}: ${tracker.walking?.calories ?? '—'} ${s.text('unit')}',
                      key: const ValueKey('walking-calories'),
                      style: TextStyle(fontSize: 11, color: muted, height: 1.4),
                    ),
                    Text(
                      s.text('notAdded'),
                      style: TextStyle(fontSize: 10, color: muted, height: 1.4),
                    ),
                  ] else
                    Text(
                      s.status(
                        kIsWeb && !tracker.simulated
                            ? StepStatus.unavailable
                            : tracker.status,
                      ),
                      style: TextStyle(fontSize: 12, color: muted, height: 1.4),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

void openStepDetails(
  BuildContext context,
  StepTracker tracker,
  String locale,
  bool isDark,
) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) =>
          StepDetailsScreen(tracker: tracker, locale: locale, isDark: isDark),
    ),
  );
}

class StepDetailsScreen extends StatelessWidget {
  final StepTracker tracker;
  final String locale;
  final bool isDark;
  const StepDetailsScreen({
    super.key,
    required this.tracker,
    required this.locale,
    required this.isDark,
  });
  StepStrings get s => StepStrings(locale);

  Future<void> _connect(BuildContext context) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.text('privacyTitle')),
        scrollable: true,
        content: Text(
          tracker.simulated ? s.text('demoNote') : s.text('privacy'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.text('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.text('allow')),
          ),
        ],
      ),
    );
    if (accepted == true && context.mounted) await tracker.connect();
  }

  Future<void> _manual(BuildContext context) async {
    final value = await showDialog<int>(
      context: context,
      builder: (_) => _StepGoalDialog(goal: tracker.goal, strings: s),
    );
    if (value != null) await tracker.setManualGoal(value);
  }

  Future<void> _history(BuildContext context) async {
    final selected = {...tracker.confirmedDays};
    final days = tracker.pastDays;
    final value = await showDialog<Set<String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(s.text('review')),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(s.text('reviewHint')),
              if (days.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(s.text('noHistory')),
                ),
              for (final day in days)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(day.date),
                  subtitle: Text('${day.steps} ${s.text('steps')}'),
                  value: selected.contains(day.date),
                  onChanged: (value) => setState(() {
                    if (value == true) {
                      selected.add(day.date);
                    } else {
                      selected.remove(day.date);
                    }
                  }),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(s.text('cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, selected),
              child: Text(s.text('confirmDays')),
            ),
          ],
        ),
      ),
    );
    if (value != null) await tracker.confirmHistory(value);
  }

  Widget _button(String label, VoidCallback? onPressed, {Key? key}) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: OutlinedButton(
      key: key,
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        foregroundColor: isDark ? AppTheme.slate100 : AppTheme.slate800,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(label, textAlign: TextAlign.center),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Directionality(
    textDirection: s.rtl ? TextDirection.rtl : TextDirection.ltr,
    child: Scaffold(
      appBar: AppBar(title: Text(s.text('details'))),
      body: AnimatedBuilder(
        animation: tracker,
        builder: (context, _) {
          final webUnavailable = kIsWeb && !tracker.simulated;
          final suggestion = tracker.recommendation;
          final last = tracker.lastUpdated;
          return RefreshIndicator(
            onRefresh: () => tracker.refresh(force: true),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DailyActivityWidget(
                          tracker: tracker,
                          locale: locale,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          tracker.simulated &&
                                  tracker.status == StepStatus.ready
                              ? s.text('demo')
                              : s.status(
                                  webUnavailable
                                      ? StepStatus.unavailable
                                      : tracker.status,
                                ),
                        ),
                        if (last != null)
                          Text(
                            '${s.text('updated')}: ${stepDateKey(last)} '
                            '${last.hour.toString().padLeft(2, '0')}:${last.minute.toString().padLeft(2, '0')}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        if (tracker.simulated)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(s.text('demoNote')),
                          ),
                        if (!tracker.connected ||
                            tracker.status == StepStatus.denied ||
                            tracker.status == StepStatus.emptyOrPrivate)
                          _button(
                            s.text('connect'),
                            webUnavailable || tracker.busy
                                ? null
                                : () => _connect(context),
                            key: const ValueKey('connect-steps'),
                          ),
                        if (tracker.connected) ...[
                          _button(
                            s.text('refresh'),
                            tracker.busy
                                ? null
                                : () => tracker.refresh(force: true),
                          ),
                          _button(
                            s.text('disconnect'),
                            () => tracker.disconnect(),
                            key: const ValueKey('disconnect-steps'),
                          ),
                        ],
                        _button(
                          s.text('manage'),
                          webUnavailable || tracker.simulated
                              ? null
                              : () async {
                                  try {
                                    await tracker.provider.openSettings();
                                  } catch (_) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(s.text('error')),
                                        ),
                                      );
                                    }
                                  }
                                },
                        ),
                        const SizedBox(height: 12),
                        Text(
                          s.text('revoke'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Divider(height: 32),
                        Text(
                          '${s.text('goal')}: ${tracker.goal}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '${s.text('initial')}: ${initialStepGoal(tracker.profile())} ${s.text('steps')}',
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: Text(s.text('automatic')),
                          subtitle: Text(s.text('automaticHint')),
                          value: tracker.automatic,
                          onChanged: (value) => tracker.setAutomatic(value),
                        ),
                        _button(
                          s.text('manual'),
                          () => _manual(context),
                          key: const ValueKey('manual-step-goal'),
                        ),
                        if (!tracker.automatic)
                          _button(
                            s.text('restore'),
                            () => tracker.setAutomatic(true),
                          ),
                        if (needsGentleStepGoals(tracker.profile()))
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(s.text('gentle')),
                          ),
                        _button(
                          s.text('review'),
                          tracker.connected ? () => _history(context) : null,
                        ),
                        Text(
                          '${s.text('historyCount')}: ${tracker.pastDays.where((d) => tracker.confirmedDays.contains(d.date)).length} / 14',
                        ),
                        if (suggestion != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            '${s.text('suggested')}: $suggestion ${s.text('steps')}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          _button(s.text('accept'), () async {
                            final accepted = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(s.text('suggested')),
                                content: Text(
                                  '${tracker.goal} → $suggestion ${s.text('steps')}',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text(s.text('cancel')),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text(s.text('accept')),
                                  ),
                                ],
                              ),
                            );
                            if (accepted == true) {
                              await tracker.acceptRecommendation(
                                expected: suggestion,
                              );
                            }
                          }),
                        ],
                        const SizedBox(height: 16),
                        Text(s.text('algorithm')),
                        const Divider(height: 32),
                        Text(s.text('calorieNote')),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

int? parseStepGoal(String value) {
  const arabic = '٠١٢٣٤٥٦٧٨٩', persian = '۰۱۲۳۴۵۶۷۸۹';
  final normalized = value.trim().split('').map((c) {
    final a = arabic.indexOf(c), p = persian.indexOf(c);
    return a >= 0
        ? '$a'
        : p >= 0
        ? '$p'
        : c;
  }).join();
  if (!RegExp(r'^\d{1,5}$').hasMatch(normalized)) return null;
  final result = int.tryParse(normalized);
  return result != null && result >= 1 && result <= 20000 ? result : null;
}

class _StepGoalDialog extends StatefulWidget {
  final int goal;
  final StepStrings strings;
  const _StepGoalDialog({required this.goal, required this.strings});
  @override
  State<_StepGoalDialog> createState() => _StepGoalDialogState();
}

class _StepGoalDialogState extends State<_StepGoalDialog> {
  late final controller = TextEditingController(text: '${widget.goal}');
  bool invalid = false;
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.strings.text('manual')),
    scrollable: true,
    content: TextField(
      key: const ValueKey('step-goal-input'),
      controller: controller,
      keyboardType: TextInputType.number,
      maxLength: 5,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp('[0-9٠-٩۰-۹]')),
      ],
      decoration: InputDecoration(
        labelText: widget.strings.text('goal'),
        helperText: widget.strings.text('range'),
        helperMaxLines: 3,
        errorText: invalid ? widget.strings.text('range') : null,
        errorMaxLines: 3,
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(widget.strings.text('cancel')),
      ),
      TextButton(
        onPressed: () {
          final value = parseStepGoal(controller.text);
          if (value == null) {
            setState(() => invalid = true);
          } else {
            Navigator.pop(context, value);
          }
        },
        child: Text(widget.strings.text('save')),
      ),
    ],
  );
}
