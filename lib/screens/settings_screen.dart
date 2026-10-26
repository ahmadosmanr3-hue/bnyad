import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:nutrify/widgets/app_build_info.dart';
import 'package:nutrify/l10n/localized_time_picker.dart';
import 'package:nutrify/l10n/localized_numbers.dart';
import '../activity/step_widgets.dart';
import '../activity/step_strings.dart';
import 'package:nutrify/widgets/ai_consent.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/screens/weekly_summary_screen.dart';
import 'package:nutrify/screens/shopping_list_screen.dart';
import 'package:nutrify/screens/premium_paywall_screen.dart';
import 'package:nutrify/screens/medical_citations_screen.dart';
import 'package:nutrify/screens/login_screen.dart';
import 'package:nutrify/widgets/auth_gate.dart';
import 'package:nutrify/services/notification_service.dart';
import 'package:nutrify/theme/app_theme.dart';
import 'package:nutrify/models/nutritional_goals.dart';
import 'package:nutrify/models/vitamin_entry.dart';
import 'package:nutrify/l10n/app_localizations.dart';
import 'package:nutrify/utils/nutrition_calculator.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.t;
    final isDark = state.isDark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.settings,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              color: isDark ? AppTheme.slate50 : AppTheme.slate900,
            ),
          ),
          const SizedBox(height: 20),

          if (state.isGuest) ...[
            _GuestSignInCard(isDark: isDark, t: t),
            const SizedBox(height: 16),
          ] else ...[
            _AccountCard(state: state, isDark: isDark, t: t),
            const SizedBox(height: 16),
          ],

          _PremiumStatusCard(state: state, isDark: isDark),
          const SizedBox(height: 16),
          if (state.isAuthenticated) AiPrivacySettings(state: state),

          _settingsCard(
            isDark: isDark,
            icon: Icons.directions_walk_rounded,
            iconColor: AppTheme.brandTeal,
            title: StepStrings(state.lang).text('settings'),
            child: _settingsNavTile(
              context: context,
              icon: Icons.directions_walk_rounded,
              title: StepStrings(state.lang).text('details'),
              isDark: isDark,
              onTap: () =>
                  openStepDetails(context, state.steps, state.lang, isDark),
            ),
          ),
          const SizedBox(height: 16),

          // Language
          _settingsCard(
            isDark: isDark,
            icon: Icons.language,
            iconColor: AppTheme.indigo,
            title: t.language,
            child: Column(
              children: [
                _langOption(context, t.english, 'en', state, isDark),
                const SizedBox(height: 8),
                _langOption(context, t.arabic, 'ar', state, isDark),
                const SizedBox(height: 8),
                _langOption(context, t.kurdish, 'ku', state, isDark),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Theme
          _settingsCard(
            isDark: isDark,
            icon: isDark ? Icons.dark_mode : Icons.light_mode,
            iconColor: isDark ? AppTheme.indigoLight : AppTheme.amber,
            title: t.theme,
            child: Row(
              children: [
                Expanded(
                  child: _themeOption(context, t.light, 'light', state, isDark),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _themeOption(context, t.dark, 'dark', state, isDark),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Macros
          _settingsCard(
            isDark: isDark,
            icon: Icons.tune,
            iconColor: AppTheme.rose,
            title: t.macronutrients,
            child: _MacrosCard(isDark: isDark),
          ),
          const SizedBox(height: 16),

          _settingsCard(
            isDark: isDark,
            icon: Icons.insights_outlined,
            iconColor: AppTheme.emerald,
            title: t.insightsLists,
            child: Column(
              children: [
                _settingsNavTile(
                  context: context,
                  icon: Icons.calendar_view_week,
                  title: t.weeklySummary,
                  isDark: isDark,
                  onTap: () => guardAuth(context, () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const WeeklySummaryScreen(),
                      ),
                    );
                  }),
                ),
                Divider(
                  height: 1,
                  color: isDark ? AppTheme.navy700 : AppTheme.slate200,
                ),
                _settingsNavTile(
                  context: context,
                  icon: Icons.shopping_cart_outlined,
                  title: t.shoppingList,
                  isDark: isDark,
                  onTap: () => guardAuth(context, () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ShoppingListScreen(),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          _settingsCard(
            isDark: isDark,
            icon: Icons.notifications_active_outlined,
            iconColor: AppTheme.amber,
            title: t.mealReminders,
            child: kIsWeb
                ? _NotificationsWebInfo(t: t, isDark: isDark)
                : _MealReminderControls(state: state, isDark: isDark),
          ),
          const SizedBox(height: 16),

          _settingsCard(
            isDark: isDark,
            icon: Icons.medication_outlined,
            iconColor: AppTheme.indigo,
            title: t.supplementReminders,
            child: kIsWeb
                ? _NotificationsWebInfo(t: t, isDark: isDark)
                : _SupplementReminderControls(state: state, isDark: isDark),
          ),
          const SizedBox(height: 16),

          // How to Use
          _settingsCard(
            isDark: isDark,
            icon: Icons.help_outline,
            iconColor: AppTheme.indigoLight,
            title: t.howToUse,
            child: Column(
              children: t.instructionsSteps
                  .asMap()
                  .entries
                  .map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.indigo.withValues(alpha: 0.2)
                                  : AppTheme.lightSurfaceTint,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppTheme.indigoLight
                                      : AppTheme.indigo,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Legal & Medical Citations Card (Guideline 1.4.1 & 3.1.2c)
          _settingsCard(
            isDark: isDark,
            icon: Icons.gavel_rounded,
            iconColor: AppTheme.indigo,
            title: t.legalAndMedicalSources,
            child: Column(
              children: [
                _settingsNavTile(
                  context: context,
                  icon: Icons.shield_outlined,
                  title: t.privacyPolicy,
                  isDark: isDark,
                  onTap: () async {
                    final uri = Uri.parse(
                      'https://nutrify-api-lovat.vercel.app/privacy',
                    );
                    try {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (_) {}
                  },
                ),
                Divider(
                  height: 1,
                  color: isDark ? AppTheme.navy700 : AppTheme.slate200,
                ),
                _settingsNavTile(
                  context: context,
                  icon: Icons.description_outlined,
                  title: t.termsOfUseEula,
                  isDark: isDark,
                  onTap: () async {
                    final uri = Uri.parse(
                      'https://nutrify-api-lovat.vercel.app/terms',
                    );
                    try {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (_) {}
                  },
                ),
                Divider(
                  height: 1,
                  color: isDark ? AppTheme.navy700 : AppTheme.slate200,
                ),
                _settingsNavTile(
                  context: context,
                  icon: Icons.person_remove_outlined,
                  title: t.accountDeletionWeb,
                  isDark: isDark,
                  onTap: () async {
                    final uri = Uri.parse(
                      'https://nutrify-api-lovat.vercel.app/delete-account',
                    );
                    try {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    } catch (_) {}
                  },
                ),
                Divider(
                  height: 1,
                  color: isDark ? AppTheme.navy700 : AppTheme.slate200,
                ),
                _settingsNavTile(
                  context: context,
                  icon: Icons.science_outlined,
                  title: t.medicalSourcesCitations,
                  isDark: isDark,
                  onTap: () => showMedicalCitationsModal(context),
                ),
              ],
            ),
          ),
          Center(child: AppBuildInfo(lang: state.lang)),
        ],
      ),
    );
  }

  Widget _settingsCard({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Material(
      color: isDark
          ? AppTheme.navy800.withValues(alpha: 0.75)
          : AppTheme.lightSurface.withValues(alpha: 0.92),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(
          color: isDark
              ? AppTheme.brandGreen.withValues(alpha: 0.12)
              : AppTheme.brandGreen.withValues(alpha: 0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: iconColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppTheme.slate900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _settingsNavTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDark ? AppTheme.indigoLight : AppTheme.indigo,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppTheme.slate900,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark ? AppTheme.slate500 : AppTheme.slate400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langOption(
    BuildContext context,
    String label,
    String code,
    AppState state,
    bool isDark,
  ) {
    final isActive = state.lang == code;
    return GestureDetector(
      onTap: () => state.setLang(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.indigo
              : (isDark
                    ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppTheme.indigo
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.indigo.withValues(alpha: 0.2),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: isActive
                ? Colors.white
                : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  Widget _themeOption(
    BuildContext context,
    String label,
    String code,
    AppState state,
    bool isDark,
  ) {
    final isActive = state.themeMode == code;
    return GestureDetector(
      onTap: () => state.setTheme(code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.indigo
              : (isDark
                    ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? AppTheme.indigo
                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.indigo.withValues(alpha: 0.2),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isActive
                  ? Colors.white
                  : (isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF475569)),
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumStatusCard extends StatelessWidget {
  const _PremiumStatusCard({required this.state, required this.isDark});

  final AppState state;
  final bool isDark;

  String _formatUntil(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final t = state.t;
    final premium = state.isPremium;
    final until = state.premiumUntil;

    final daysLeft = state.premiumDaysLeft;
    final title = premium ? t.premiumActive : t.premiumTitle;
    final subtitle = premium
        ? (until != null
              ? '${t.premiumActiveUntil.replaceAll('{date}', _formatUntil(until))}${daysLeft > 0 ? ' (${t.get('daysRemaining').replaceAll('{days}', '$daysLeft')})' : ''}'
              : t.premium)
        : t.premiumSubtitle;
    final cta = premium ? t.premiumManage : t.premiumUnlockCta;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showPremiumPaywall(context),
        borderRadius: BorderRadius.circular(28),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: premium
                  ? [
                      AppTheme.emerald.withValues(alpha: isDark ? 0.35 : 0.22),
                      AppTheme.indigo.withValues(alpha: isDark ? 0.30 : 0.18),
                    ]
                  : [
                      AppTheme.indigo.withValues(alpha: isDark ? 0.40 : 0.22),
                      AppTheme.violet.withValues(alpha: isDark ? 0.30 : 0.16),
                    ],
            ),
            border: Border.all(
              color: isDark
                  ? AppTheme.indigoLight.withValues(alpha: 0.45)
                  : AppTheme.indigo.withValues(alpha: 0.35),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: AppTheme.brandGradient,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.indigo.withValues(
                        alpha: isDark ? 0.45 : 0.3,
                      ),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(
                  premium
                      ? Icons.workspace_premium_rounded
                      : Icons.lock_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: isDark ? AppTheme.slate50 : AppTheme.slate900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                        color: isDark ? AppTheme.slate300 : AppTheme.slate600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: AppTheme.indigo,
                          ),
                          child: Text(
                            cta,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (!premium) ...[
                          GestureDetector(
                            onTap: () async {
                              final success = await state.restorePurchases();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      success
                                          ? t.restoreSuccess
                                          : state.purchaseVerificationPending
                                          ? t.purchaseVerificationPending
                                          : t.restoreNotFound,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              child: Text(
                                t.premiumRestore,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppTheme.indigoLight
                                      : AppTheme.indigo,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? AppTheme.slate400 : AppTheme.slate600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacrosCard extends StatelessWidget {
  final bool isDark;

  const _MacrosCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.t;
    final g = state.goals;
    final sub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.editMacrosDesc,
          style: TextStyle(fontSize: 12.5, height: 1.4, color: sub),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _macroPill(
              t.calories,
              '${g?.calories ?? 0}',
              t.kcal,
              AppTheme.indigo,
            ),
            const SizedBox(width: 8),
            _macroPill(t.protein, '${g?.protein ?? 0}', t.grams, AppTheme.rose),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _macroPill(t.carbs, '${g?.carbs ?? 0}', t.grams, AppTheme.amber),
            const SizedBox(width: 8),
            _macroPill(t.fat, '${g?.fat ?? 0}', t.grams, AppTheme.emerald),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _openEditor(context),
            icon: const Icon(Icons.edit, size: 18),
            label: Text(t.editMacros),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openEditor(BuildContext context) {
    final state = context.read<AppState>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MacrosEditorSheet(state: state, isDark: isDark),
    );
  }

  Widget _macroPill(String label, String value, String unit, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MacrosEditorSheet extends StatefulWidget {
  final AppState state;
  final bool isDark;

  const _MacrosEditorSheet({required this.state, required this.isDark});

  @override
  State<_MacrosEditorSheet> createState() => _MacrosEditorSheetState();
}

class _MacrosEditorSheetState extends State<_MacrosEditorSheet> {
  late final TextEditingController _calCtrl;
  late final TextEditingController _proCtrl;
  late final TextEditingController _carbCtrl;
  late final TextEditingController _fatCtrl;
  bool _saving = false;
  bool _syncing = false;
  MacroEditField _lastEdited = MacroEditField.protein;

  @override
  void initState() {
    super.initState();
    final g = widget.state.goals;
    _calCtrl = TextEditingController(text: '${g?.calories ?? 2000}');
    _proCtrl = TextEditingController(text: '${g?.protein ?? 100}');
    _carbCtrl = TextEditingController(text: '${g?.carbs ?? 200}');
    _fatCtrl = TextEditingController(text: '${g?.fat ?? 60}');
    _calCtrl.addListener(() => _onFieldChanged(MacroEditField.calories));
    _proCtrl.addListener(() => _onFieldChanged(MacroEditField.protein));
    _carbCtrl.addListener(() => _onFieldChanged(MacroEditField.carbs));
    _fatCtrl.addListener(() => _onFieldChanged(MacroEditField.fat));
  }

  NutritionalGoals _goalsFromFields() {
    final g = widget.state.goals;
    return NutritionalGoals(
      calories: _parse(_calCtrl) ?? g?.calories ?? 2000,
      protein: _parse(_proCtrl) ?? g?.protein ?? 100,
      carbs: _parse(_carbCtrl) ?? g?.carbs ?? 200,
      fat: _parse(_fatCtrl) ?? g?.fat ?? 60,
    );
  }

  void _onFieldChanged(MacroEditField field) {
    if (_syncing) return;
    _lastEdited = field;
    _syncing = true;
    try {
      final balanced = rebalanceMacroEdit(
        current: _goalsFromFields(),
        changed: field,
        calories: _parse(_calCtrl),
        protein: _parse(_proCtrl),
        carbs: _parse(_carbCtrl),
        fat: _parse(_fatCtrl),
      );
      _applyBalanced(balanced, skip: field);
    } finally {
      _syncing = false;
    }
    if (mounted) setState(() {});
  }

  void _applyBalanced(NutritionalGoals goals, {required MacroEditField skip}) {
    void setUnlessEditing(
      TextEditingController c,
      int value,
      MacroEditField field,
    ) {
      if (skip == field) return;
      final text = '$value';
      if (c.text != text) c.text = text;
    }

    setUnlessEditing(_calCtrl, goals.calories, MacroEditField.calories);
    setUnlessEditing(_proCtrl, goals.protein, MacroEditField.protein);
    setUnlessEditing(_carbCtrl, goals.carbs, MacroEditField.carbs);
    setUnlessEditing(_fatCtrl, goals.fat, MacroEditField.fat);
  }

  @override
  void dispose() {
    _calCtrl.dispose();
    _proCtrl.dispose();
    _carbCtrl.dispose();
    _fatCtrl.dispose();
    super.dispose();
  }

  int? _parse(TextEditingController c) {
    final v = parseLocalizedInt(c.text);
    if (v == null) return null;
    return v;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final balanced = rebalanceMacroEdit(
      current: _goalsFromFields(),
      changed: _lastEdited,
      calories: _parse(_calCtrl),
      protein: _parse(_proCtrl),
      carbs: _parse(_carbCtrl),
      fat: _parse(_fatCtrl),
    );
    await widget.state.updateMacros(
      calories: balanced.calories,
      protein: balanced.protein,
      carbs: balanced.carbs,
      fat: balanced.fat,
      changed: _lastEdited,
    );
    if (!mounted) return;
    final t = widget.state.t;
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.macrosUpdated)));
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.state.t;
    final isDark = widget.isDark;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                t.editMacros,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                t.editMacrosDesc,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              _field(t.calories, t.kcal, _calCtrl, AppTheme.indigo, isDark),
              const SizedBox(height: 12),
              _field(t.protein, t.grams, _proCtrl, AppTheme.rose, isDark),
              const SizedBox(height: 12),
              _field(t.carbs, t.grams, _carbCtrl, AppTheme.amber, isDark),
              const SizedBox(height: 12),
              _field(t.fat, t.grams, _fatCtrl, AppTheme.emerald, isDark),
              const SizedBox(height: 10),
              Builder(
                builder: (_) {
                  final p =
                      _parse(_proCtrl) ?? widget.state.goals?.protein ?? 0;
                  final c = _parse(_carbCtrl) ?? widget.state.goals?.carbs ?? 0;
                  final f = _parse(_fatCtrl) ?? widget.state.goals?.fat ?? 0;
                  final fromMacros = caloriesFromMacros(p, c, f);
                  return Text(
                    '↔ $fromMacros ${t.kcal} (${t.protein}×4 + ${t.carbs}×4 + ${t.fat}×9)',
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      color: isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(t.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(t.save),
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

  Widget _field(
    String label,
    String unit,
    TextEditingController ctrl,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.4)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 78,
            child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 8,
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: color, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 38,
            child: Text(
              unit,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationsWebInfo extends StatelessWidget {
  final AppLocalizations t;
  final bool isDark;

  const _NotificationsWebInfo({required this.t, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final sub = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.phone_android_outlined,
              size: 22,
              color: isDark ? AppTheme.indigoLight : AppTheme.indigo,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                t.notificationsWebInfo,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          t.notificationsWebHint,
          style: TextStyle(fontSize: 12, height: 1.4, color: sub),
        ),
      ],
    );
  }
}

class _MealReminderControls extends StatelessWidget {
  final AppState state;
  final bool isDark;

  const _MealReminderControls({required this.state, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final t = state.t;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _reminderRow(context, 'breakfast', t.breakfastReminder),
        const SizedBox(height: 10),
        _reminderRow(context, 'lunch', t.lunchReminder),
        const SizedBox(height: 10),
        _reminderRow(context, 'dinner', t.dinnerReminder),
        const SizedBox(height: 10),
        _reminderRow(context, 'snacks', t.snacksReminder),
        const Divider(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                t.weeklyDigestNotify,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF475569),
                ),
              ),
            ),
            Switch(
              value: state.weeklyDigestEnabled,
              onChanged: (v) => state.setWeeklyDigestEnabled(v),
              activeTrackColor: AppTheme.indigo,
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () =>
                NotificationService.instance.showTestNotification(),
            icon: const Icon(Icons.notifications_active_outlined, size: 18),
            label: Text(
              t.testNotification,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _reminderRow(BuildContext context, String mealId, String label) {
    final enabled = state.getReminderEnabled(mealId);
    final time = state.getReminderTime(mealId);
    final timeStr =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
        ),
        GestureDetector(
          onTap: () async {
            final picked = await showBnyadTimePicker(
              context: context,
              initialTime: time,
            );
            if (picked != null) {
              state.setReminderTime(mealId, picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Text(
              timeStr,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: enabled
                    ? AppTheme.indigo
                    : (isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 32,
          child: Switch(
            value: enabled,
            onChanged: (val) => state.setReminderEnabled(mealId, val),
            activeTrackColor: AppTheme.indigo,
          ),
        ),
      ],
    );
  }
}

class _SupplementReminderControls extends StatelessWidget {
  final AppState state;
  final bool isDark;

  const _SupplementReminderControls({
    required this.state,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final t = state.t;
    final vitamins = state.vitamins;

    if (vitamins.isEmpty) {
      return Text(
        t.noSupplementsForReminders,
        style: TextStyle(
          fontSize: 13,
          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < vitamins.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _supplementRow(context, vitamins[i]),
        ],
      ],
    );
  }

  Widget _supplementRow(BuildContext context, VitaminEntry v) {
    final enabled = v.reminderEnabled;
    final hour = v.reminderHour ?? 8;
    final minute = v.reminderMinute ?? 0;
    final timeStr =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    return Row(
      children: [
        Expanded(
          child: Text(
            v.name,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
            ),
          ),
        ),
        GestureDetector(
          onTap: () async {
            final picked = await showBnyadTimePicker(
              context: context,
              initialTime: TimeOfDay(hour: hour, minute: minute),
            );
            if (picked != null) {
              await state.setVitaminReminder(v.id, enabled: true, time: picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            child: Text(
              timeStr,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: enabled
                    ? AppTheme.indigo
                    : (isDark
                          ? const Color(0xFF64748B)
                          : const Color(0xFF94A3B8)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 32,
          child: Switch(
            value: enabled,
            onChanged: (val) => state.setVitaminReminder(
              v.id,
              enabled: val,
              time: TimeOfDay(hour: hour, minute: minute),
            ),
            activeTrackColor: AppTheme.indigo,
          ),
        ),
      ],
    );
  }
}

class _GuestSignInCard extends StatelessWidget {
  const _GuestSignInCard({required this.isDark, required this.t});

  final bool isDark;
  final AppLocalizations t;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const LoginScreen(fromGuestUpgrade: true),
          ),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                AppTheme.indigo.withValues(alpha: isDark ? 0.35 : 0.14),
                AppTheme.violet.withValues(alpha: isDark ? 0.25 : 0.10),
              ],
            ),
            border: Border.all(
              color: AppTheme.indigo.withValues(alpha: isDark ? 0.5 : 0.35),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.login_rounded,
                color: isDark ? AppTheme.indigoLight : AppTheme.indigo,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.signInFromSettings,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.guestModeLimited,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountCard extends StatefulWidget {
  final AppState state;
  final bool isDark;
  final AppLocalizations t;

  const _AccountCard({
    required this.state,
    required this.isDark,
    required this.t,
  });

  @override
  State<_AccountCard> createState() => _AccountCardState();
}

class _AccountCardState extends State<_AccountCard> {
  bool _isDeleting = false;

  Future<void> _confirmDeleteAccount(BuildContext context) async {
    final t = widget.t;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: widget.isDark ? AppTheme.navy800 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.rose.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.rose,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                t.deleteAccountConfirmTitle,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: widget.isDark ? AppTheme.slate50 : AppTheme.slate900,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          t.deleteAccountConfirmDesc,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: widget.isDark
                ? const Color(0xFF94A3B8)
                : const Color(0xFF64748B),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(
              t.cancel,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: widget.isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.rose,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: Text(
              t.deleteAccountButton,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isDeleting = true);
      try {
        final success = await widget.state.deleteAccount();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? t.deleteAccountSuccess : t.deleteAccountFailed,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: success ? AppTheme.emerald : AppTheme.rose,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isDeleting = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final isDark = widget.isDark;
    final profileName = widget.state.userProfile?.displayName;
    final displayName = (profileName != null && profileName.trim().isNotEmpty)
        ? profileName.trim()
        : 'BNYAD Member';

    return Material(
      color: isDark
          ? AppTheme.navy800.withValues(alpha: 0.75)
          : AppTheme.lightSurface.withValues(alpha: 0.92),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(
          color: isDark
              ? AppTheme.brandGreen.withValues(alpha: 0.12)
              : AppTheme.brandGreen.withValues(alpha: 0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.indigo.withValues(
                      alpha: isDark ? 0.25 : 0.12,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person_rounded,
                      color: AppTheme.indigo,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.account,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppTheme.slate50 : AppTheme.slate900,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => widget.state.logout(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark
                        ? const Color(0xFFCBD5E1)
                        : const Color(0xFF475569),
                    side: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 16),
                  label: Text(
                    t.logout,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(
              height: 1,
              color: isDark ? AppTheme.navy700 : AppTheme.slate200,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: _isDeleting
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.rose,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              t.deletingAccount,
                              style: const TextStyle(
                                color: AppTheme.rose,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : OutlinedButton.icon(
                      onPressed: () => _confirmDeleteAccount(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.rose,
                        side: BorderSide(
                          color: AppTheme.rose.withValues(
                            alpha: isDark ? 0.5 : 0.4,
                          ),
                        ),
                        backgroundColor: AppTheme.rose.withValues(
                          alpha: isDark ? 0.08 : 0.04,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: AppTheme.rose,
                      ),
                      label: Text(
                        t.deleteAccount,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: AppTheme.rose,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
