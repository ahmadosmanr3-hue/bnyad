import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/models/nutritional_goals.dart';
import 'package:nutrify/constants/food_database.dart';
import 'package:nutrify/widgets/app_logo.dart';
import 'package:nutrify/theme/app_theme.dart';
import 'package:nutrify/l10n/app_localizations.dart';
import 'package:nutrify/utils/nutrition_calculator.dart';
import 'package:nutrify/utils/responsive.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  int _step = 1;
  bool _loading = false;
  bool _saving = false;
  bool _finished = false;
  NutritionalGoals? _aiGoals;
  int? _aiWaterTargetMl;
  String? _error;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnim;

  // ── Core (used for calorie calculation) ──────────────
  double _weight = 70;
  double _height = 175;
  int _age = 25;
  String _gender = 'male';
  String _activity = 'lightlyActive';
  String _goal = 'stayHealthy';

  // ── Extended profile (meal plans & micros, not calories) ──
  double _targetWeight = 70;
  final List<String> _allergies = [];
  final List<String> _sicknesses = [];
  String _dietaryPattern = 'omnivore';
  String _cuisinePreference = 'mixed';
  int _mealsPerDay = 3;
  int _workoutDays = 0;
  String _workoutType = 'workoutNone';

  static const int _totalSteps = 5;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    _fadeController.reset();
    setState(() => _step = step);
    _fadeController.forward();
  }

  void _toggleSelection(List<String> list, String item) {
    setState(() {
      if (list.contains(item)) {
        list.remove(item);
      } else {
        list.add(item);
      }
    });
  }

  Map<String, dynamic> _collectProfile() => {
        'weight': _weight,
        'height': _height,
        'age': _age,
        'gender': _gender,
        'activity': _activity,
        'goal': _goal,
        'disabilities': <String>[],
        'sicknesses': _sicknesses,
        'allergies': _allergies,
        'targetWeight': _targetWeight,
        'pace': 'moderate',
        'pregnancyStatus': 'none',
        'dietaryPattern': _dietaryPattern,
        'dislikedFoods': <String>[],
        'cuisinePreference': _cuisinePreference,
        'mealsPerDay': _mealsPerDay,
        'fastingWindow': 'fastingNone',
        'sleepHours': 7.0,
        'stressLevel': 'stressMedium',
        'medications': '',
        'workoutDaysPerWeek': _workoutDays,
        'workoutType': _workoutType,
        'cookingSkill': 'cookingIntermediate',
        'cookingTime': 'cookingTimeUnder30',
        if (_aiWaterTargetMl != null) 'waterTargetMl': _aiWaterTargetMl,
      };

  Future<void> _generatePlan() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final state = Provider.of<AppState>(context, listen: false);

    try {
      final profile = _collectProfile();
      final goals = await state.generateAiGoals(profile);
      final waterMl = state.fallbackWaterTargetMl(profile);

      if (mounted) {
        setState(() {
          if (goals != null) {
            _aiGoals = goals;
            _aiWaterTargetMl = waterMl;
            _finished = true;
          } else {
            _error = state.t.goalGenerationError;
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = state.t.goalGenerationError;
          _loading = false;
        });
      }
    }
  }

  Future<void> _completeOnboarding(AppState state) async {
    if (_aiGoals == null || _saving) return;
    setState(() => _saving = true);
    try {
      await state
          .finishOnboarding(_aiGoals!, _collectProfile())
          .timeout(const Duration(seconds: 20));
    } catch (_) {
      if (mounted) {
        setState(() => _error = state.t.goalGenerationError);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.t;
    final isDark = state.isDark;
    final isRTL = state.isRTL;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? AppTheme.darkWelcomeGradient
                : AppTheme.lightWelcomeGradient,
          ),
          color: isDark ? AppTheme.navy900 : null,
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 380;
              final hPad = compact ? 12.0 : 20.0;
              final cardPad = compact ? 14.0 : 24.0;
              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 12),
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 480),
                    padding: EdgeInsets.fromLTRB(cardPad, 16, cardPad, 24),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.navy800.withValues(alpha: 0.72)
                          : Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(compact ? 22 : 28),
                      border: Border.all(
                        color: isDark
                            ? AppTheme.brandGreen.withValues(alpha: 0.18)
                            : AppTheme.brandGreen.withValues(alpha: 0.1),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.brandTeal.withValues(
                            alpha: isDark ? 0.08 : 0.06,
                          ),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  AppLogo.icon(size: compact ? 24 : 28),
                                  SizedBox(width: compact ? 8 : 10),
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: AppBrandTitle(
                                        fontSize: compact ? 18 : 20,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildLangMenu(state, t, isDark),
                          ],
                        ),
                    if (!_loading && !_finished) ...[
                      const SizedBox(height: 20),
                      _buildProgressHeader(t, isDark),
                      const SizedBox(height: 20),
                    ],
                    if (_loading) _buildLoading(t, isDark),
                    if (_finished && _aiGoals != null)
                      _buildResults(state, t, isDark),
                    if (!_loading && _error != null) ...[
                      const SizedBox(height: 16),
                      _buildError(_error!, isDark),
                    ],
                    if (!_loading && !_finished) ...[
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.04, 0),
                            end: Offset.zero,
                          ).animate(_fadeAnim),
                          child: _buildStep(t, isDark),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildNavButtons(t, isDark, isRTL),
                    ],
                  ],
                ),
              ),
            ),
          );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader(AppLocalizations t, bool isDark) {
    final progress = _step / _totalSteps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              t.onboardStepOf(_step, _totalSteps),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: isDark ? AppTheme.slate400 : AppTheme.slate500,
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.brandOrangeDeep,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor:
                isDark ? AppTheme.slate700 : AppTheme.slate200,
            valueColor: const AlwaysStoppedAnimation(AppTheme.brandTeal),
          ),
        ),
      ],
    );
  }

  Widget _buildLangMenu(AppState state, AppLocalizations t, bool isDark) {
    return PopupMenuButton<String>(
      onSelected: (lang) => state.setLang(lang),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (_) => [
        PopupMenuItem(value: 'en', child: Text(t.english)),
        PopupMenuItem(value: 'ar', child: Text(t.arabic)),
        PopupMenuItem(value: 'ku', child: Text(t.kurdish)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.slate800 : AppTheme.slate100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language,
              size: 14,
              color: isDark ? AppTheme.slate300 : AppTheme.slate600,
            ),
            const SizedBox(width: 6),
            Text(
              state.lang == 'en'
                  ? t.english
                  : state.lang == 'ar'
                      ? t.arabic
                      : t.kurdish,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.slate300 : AppTheme.slate600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(AppLocalizations t, bool isDark) {
    switch (_step) {
      case 1:
        return _buildStepBody(t, isDark);
      case 2:
        return _buildStepActivity(t, isDark);
      case 3:
        return _buildStepGoal(t, isDark);
      case 4:
        return _buildStepHealth(t, isDark);
      case 5:
        return _buildStepDiet(t, isDark);
      default:
        return const SizedBox();
    }
  }

  // ─── Step 1: Body ───────────────────────────────────

  Widget _buildStepBody(AppLocalizations t, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader(
          icon: Icons.person_outline_rounded,
          title: t.onboardingTitle,
          subtitle: t.onboardingSubtitle,
          isDark: isDark,
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _statStepper(
                label: t.weight,
                icon: Icons.monitor_weight_outlined,
                value: _weight,
                min: 40,
                max: 150,
                unit: 'kg',
                step: 1,
                isDark: isDark,
                onChanged: (v) => setState(() {
                  if (_targetWeight == _weight) _targetWeight = v;
                  _weight = v;
                }),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statStepper(
                label: t.height,
                icon: Icons.height_rounded,
                value: _height,
                min: 140,
                max: 220,
                unit: 'cm',
                step: 1,
                isDark: isDark,
                onChanged: (v) => setState(() => _height = v),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _statStepper(
          label: t.age,
          icon: Icons.cake_outlined,
          value: _age.toDouble(),
          min: 15,
          max: 80,
          unit: '',
          step: 1,
          isDark: isDark,
          onChanged: (v) => setState(() => _age = v.round()),
        ),
        const SizedBox(height: 16),
        _sectionLabel(t.gender, isDark),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _genderButton(t.male, 'male', Icons.male, isDark)),
            const SizedBox(width: 12),
            Expanded(
              child: _genderButton(t.female, 'female', Icons.female, isDark),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Step 2: Activity & training ────────────────────

  Widget _buildStepActivity(AppLocalizations t, bool isDark) {
    const activityIcons = {
      'sedentary': Icons.weekend_outlined,
      'lightlyActive': Icons.directions_walk_rounded,
      'moderatelyActive': Icons.directions_run_rounded,
      'veryActive': Icons.fitness_center_rounded,
      'extraActive': Icons.sports_martial_arts_rounded,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader(
          icon: Icons.local_fire_department_outlined,
          title: t.onboardActivityStepTitle,
          subtitle: t.onboardActivityStepSubtitle,
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        ...activityIcons.entries.map((e) {
          final key = e.key;
          final label = switch (key) {
            'sedentary' => t.sedentary,
            'lightlyActive' => t.lightlyActive,
            'moderatelyActive' => t.moderatelyActive,
            'veryActive' => t.veryActive,
            'extraActive' => t.extraActive,
            _ => key,
          };
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _activityTile(
              icon: e.value,
              title: label,
              subtitle: t.getActivityHint(key),
              isSelected: _activity == key,
              isDark: isDark,
              onTap: () => setState(() => _activity = key),
            ),
          );
        }),
        const SizedBox(height: 8),
        _infoCard(
          icon: Icons.info_outline_rounded,
          text: t.onboardTrainingSubtitle,
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        _sectionLabel('${t.workoutDaysPerWeek} · ${t.optionalField}', isDark),
        const SizedBox(height: 8),
        _statStepper(
          label: t.workoutDaysPerWeek,
          icon: Icons.calendar_month_outlined,
          value: _workoutDays.toDouble(),
          min: 0,
          max: 7,
          unit: '',
          step: 1,
          isDark: isDark,
          onChanged: (v) => setState(() => _workoutDays = v.round()),
        ),
        if (_workoutDays > 0) ...[
          const SizedBox(height: 12),
          _styledDropdown(
            label: t.workoutType,
            value: _workoutType,
            options: {
              for (final k in workoutTypeList) k: t.getWorkoutType(k),
            },
            isDark: isDark,
            onChanged: (v) => setState(() => _workoutType = v),
          ),
        ],
      ],
    );
  }

  // ─── Step 3: Goal ───────────────────────────────────

  Widget _buildStepGoal(AppLocalizations t, bool isDark) {
    const goals = [
      ('loseWeight', Icons.trending_down_rounded, AppTheme.rose),
      ('gainWeight', Icons.trending_up_rounded, AppTheme.brandGold),
      ('gainMuscle', Icons.fitness_center_rounded, AppTheme.brandTeal),
      ('stayHealthy', Icons.favorite_rounded, AppTheme.emerald),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader(
          icon: Icons.flag_outlined,
          title: t.selectGoal,
          subtitle: t.onboardGoalStepSubtitle,
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: MediaQuery.sizeOf(context).width < 380 ? 0.92 : 1.0,
          children: goals.map((g) {
            return _goalCard(
              label: t.getGoal(g.$1),
              icon: g.$2,
              accent: g.$3,
              isSelected: _goal == g.$1,
              isDark: isDark,
              onTap: () => setState(() => _goal = g.$1),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        _sectionLabel('${t.targetWeight} · ${t.optionalField}', isDark),
        const SizedBox(height: 8),
        _statStepper(
          label: t.targetWeight,
          icon: Icons.flag_circle_outlined,
          value: _targetWeight,
          min: 40,
          max: 150,
          unit: 'kg',
          step: 1,
          isDark: isDark,
          onChanged: (v) => setState(() => _targetWeight = v),
        ),
      ],
    );
  }

  // ─── Step 4: Health ─────────────────────────────────

  Widget _buildStepHealth(AppLocalizations t, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader(
          icon: Icons.health_and_safety_outlined,
          title: t.onboardHealthStepTitle,
          subtitle: t.onboardHealthStepSubtitle,
          isDark: isDark,
        ),
        const SizedBox(height: 12),
        _infoCard(
          icon: Icons.touch_app_outlined,
          text: t.onboardHealthOptionalNote,
          isDark: isDark,
        ),
        const SizedBox(height: 20),
        _sectionLabel(t.selectAllergies, isDark),
        const SizedBox(height: 10),
        _chipWrap(
          items: allergiesList,
          selected: _allergies,
          labelBuilder: t.getAllergy,
          isDark: isDark,
          activeColor: AppTheme.rose,
          onToggle: (item) => _toggleSelection(_allergies, item),
        ),
        const SizedBox(height: 20),
        _sectionLabel(t.selectSicknesses, isDark),
        const SizedBox(height: 10),
        _chipWrap(
          items: sicknessList,
          selected: _sicknesses,
          labelBuilder: t.getSickness,
          isDark: isDark,
          onToggle: (item) => _toggleSelection(_sicknesses, item),
        ),
      ],
    );
  }

  // ─── Step 5: Diet ───────────────────────────────────

  Widget _buildStepDiet(AppLocalizations t, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _stepHeader(
          icon: Icons.restaurant_menu_rounded,
          title: t.onboardDietTitle,
          subtitle: t.onboardDietSubtitle,
          isDark: isDark,
        ),
        const SizedBox(height: 16),
        _styledDropdown(
          label: t.dietaryPattern,
          value: _dietaryPattern,
          options: {
            for (final k in dietaryPatternList) k: t.getDietaryPattern(k),
          },
          isDark: isDark,
          onChanged: (v) => setState(() => _dietaryPattern = v),
        ),
        const SizedBox(height: 12),
        _styledDropdown(
          label: t.cuisinePreference,
          value: _cuisinePreference,
          options: {
            for (final k in cuisinePreferenceList) k: t.getCuisinePreference(k),
          },
          isDark: isDark,
          onChanged: (v) => setState(() => _cuisinePreference = v),
        ),
        const SizedBox(height: 12),
        _styledDropdown(
          label: t.mealsPerDay,
          value: _mealsPerDayKey(),
          options: {
            for (final k in mealsPerDayList) k: t.getMealsPerDay(k),
          },
          isDark: isDark,
          onChanged: (v) => setState(() => _mealsPerDay = _mealsPerDayFromKey(v)),
        ),
        const SizedBox(height: 16),
        _infoCard(
          icon: Icons.auto_awesome_rounded,
          text: t.goalCalculatedDesc,
          isDark: isDark,
          accent: AppTheme.brandOrangeDeep,
        ),
      ],
    );
  }

  String _mealsPerDayKey() {
    switch (_mealsPerDay) {
      case 2:
        return 'two';
      case 4:
        return 'four';
      case 5:
        return 'five';
      case 3:
      default:
        return 'three';
    }
  }

  int _mealsPerDayFromKey(String k) {
    switch (k) {
      case 'two':
        return 2;
      case 'four':
        return 4;
      case 'five':
        return 5;
      case 'three':
      default:
        return 3;
    }
  }

  Widget _buildNavButtons(AppLocalizations t, bool isDark, bool isRTL) {
    return Row(
      children: [
        if (_step > 1)
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _goToStep(_step - 1),
              icon: Icon(
                isRTL ? Icons.chevron_right : Icons.chevron_left,
                size: 20,
              ),
              label: Text(t.back, maxLines: 1, overflow: TextOverflow.ellipsis),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                side: BorderSide(
                  color: isDark ? AppTheme.slate600 : AppTheme.slate200,
                ),
              ),
            ),
          ),
        if (_step > 1) const SizedBox(width: 10),
        Expanded(
          flex: _step > 1 ? 2 : 1,
          child: ElevatedButton.icon(
            onPressed: _step == _totalSteps
                ? _generatePlan
                : () => _goToStep(_step + 1),
            icon: Icon(
              _step == _totalSteps
                  ? Icons.auto_awesome_rounded
                  : (isRTL ? Icons.chevron_left : Icons.chevron_right),
              size: 18,
            ),
            label: Text(
              _step == _totalSteps ? t.generatePlan : t.next,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoading(AppLocalizations t, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: AppTheme.brandTeal,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            t.analyzing,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.slate300 : AppTheme.slate600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 18, color: AppTheme.rose),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.rose,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults(AppState state, AppLocalizations t, bool isDark) {
    final profile = _collectProfile();
    final weight = (profile['weight'] as num).toDouble();
    final height = (profile['height'] as num).toDouble();
    final age = profile['age'] as int;
    final gender = profile['gender'] as String;
    final activity = profile['activity'] as String;
    final bmi = computeBmi(weightKg: weight, heightCm: height);
    final maintenance = computeMaintenanceTdee(
      weightKg: weight,
      heightCm: height,
      age: age,
      gender: gender,
      activityLevel: activity,
    ).round();
    final targetCal = _aiGoals!.calories;
    final calDelta = targetCal - maintenance;
    final proteinPerKg = weight > 0 ? _aiGoals!.protein / weight : 0.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, val, child) => Opacity(
        opacity: val,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - val)),
          child: child,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.brandTeal.withValues(alpha: 0.2),
                  AppTheme.brandGold.withValues(alpha: 0.15),
                ],
              ),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppTheme.emerald,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t.goalSet,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppTheme.slate900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t.goalCalculatedDesc,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: isDark ? AppTheme.slate400 : AppTheme.slate500,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.brandTeal.withValues(alpha: isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.brandTeal.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              children: [
                Text(
                  t.dailyCalorieTarget,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.slate400 : AppTheme.slate500,
                  ),
                ),
                const SizedBox(height: 4),
                scaleDownText(
                  '$targetCal ${t.kcal}',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.brandTealDark,
                  ),
                ),
                if (calDelta != 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${calDelta > 0 ? '+' : ''}$calDelta ${t.kcal} vs ${t.maintenanceCalories.toLowerCase()} ($maintenance)',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.slate400 : AppTheme.slate500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.brandTeal.withValues(alpha: isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '${t.yourBmi}: ${bmi.toStringAsFixed(1)}  ·  ${t.maintenanceCalories}: $maintenance ${t.kcal}',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.brandGreenLight : AppTheme.brandTealDark,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.rose.withValues(alpha: isDark ? 0.12 : 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '${_aiGoals!.protein} ${t.grams} ${t.protein} · ${proteinPerKg.toStringAsFixed(1)} ${t.proteinPerKgBody}',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.rose.withValues(alpha: 0.9) : AppTheme.rose,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _goalBox(t.calories, _aiGoals!.calories, t.kcal, AppTheme.brandTeal, isDark),
              const SizedBox(width: 8),
              _goalBox(t.protein, _aiGoals!.protein, t.grams, AppTheme.rose, isDark),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _goalBox(t.carbs, _aiGoals!.carbs, t.grams, AppTheme.brandGold, isDark),
              const SizedBox(width: 8),
              _goalBox(t.fat, _aiGoals!.fat, t.grams, AppTheme.emerald, isDark),
            ],
          ),
          if (_aiWaterTargetMl != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                _goalBox(
                  t.dailyWaterGoal,
                  _aiWaterTargetMl!,
                  t.ml,
                  AppTheme.cyan,
                  isDark,
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : () => _completeOnboarding(state),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(t.getStarted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _goalBox(
    String label,
    int value,
    String unit,
    Color color,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: color.withValues(alpha: 0.75),
              ),
            ),
            const SizedBox(height: 6),
            scaleDownText(
              '$value $unit',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Shared UI components ─────────────────────────────

  Widget _stepHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.brandTeal.withValues(alpha: isDark ? 0.25 : 0.15),
                AppTheme.brandGold.withValues(alpha: isDark ? 0.2 : 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, size: 22, color: AppTheme.brandTealDark),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: isDark ? Colors.white : AppTheme.slate900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: isDark ? AppTheme.slate400 : AppTheme.slate500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: isDark ? AppTheme.slate400 : AppTheme.slate500,
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String text,
    required bool isDark,
    Color accent = AppTheme.brandTeal,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.1 : 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: accent),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: isDark ? AppTheme.slate300 : AppTheme.slate600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statStepper({
    required String label,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required String unit,
    required int step,
    required bool isDark,
    required ValueChanged<double> onChanged,
  }) {
    final display = unit.isEmpty
        ? value.round().toString()
        : '${value.round()} $unit';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.navy700.withValues(alpha: 0.45)
            : AppTheme.lightSurfaceTint,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? AppTheme.slate600.withValues(alpha: 0.5)
              : AppTheme.slate200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isDark ? AppTheme.slate400 : AppTheme.slate500,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.slate400 : AppTheme.slate500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _roundIconButton(
                icon: Icons.remove_rounded,
                isDark: isDark,
                onTap: value > min
                    ? () => onChanged((value - step).clamp(min, max))
                    : null,
              ),
              Expanded(
                child: scaleDownText(
                  display,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppTheme.slate900,
                  ),
                ),
              ),
              _roundIconButton(
                icon: Icons.add_rounded,
                isDark: isDark,
                onTap: value < max
                    ? () => onChanged((value + step).clamp(min, max))
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required bool isDark,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return Material(
      color: enabled
          ? (isDark ? AppTheme.slate700 : Colors.white)
          : (isDark ? AppTheme.slate800 : AppTheme.slate100),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 18,
            color: enabled
                ? (isDark ? Colors.white : AppTheme.slate800)
                : (isDark ? AppTheme.slate600 : AppTheme.slate300),
          ),
        ),
      ),
    );
  }

  Widget _genderButton(
    String label,
    String value,
    IconData icon,
    bool isDark,
  ) {
    final isSelected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [AppTheme.brandTeal, AppTheme.brandTealDark],
                )
              : null,
          color: isSelected
              ? null
              : (isDark ? AppTheme.navy700.withValues(alpha: 0.45) : AppTheme.slate100),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.brandTeal
                : (isDark ? AppTheme.slate600 : AppTheme.slate200),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppTheme.slate400 : AppTheme.slate500),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppTheme.slate300 : AppTheme.slate600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activityTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.brandTeal.withValues(alpha: isDark ? 0.18 : 0.1)
              : (isDark
                  ? AppTheme.navy700.withValues(alpha: 0.4)
                  : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppTheme.brandTeal
                : (isDark ? AppTheme.slate600 : AppTheme.slate200),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.brandTeal.withValues(alpha: 0.2)
                    : (isDark ? AppTheme.slate700 : AppTheme.slate100),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected
                    ? AppTheme.brandTealDark
                    : (isDark ? AppTheme.slate400 : AppTheme.slate500),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? (isDark ? Colors.white : AppTheme.brandTealDark)
                          : (isDark ? AppTheme.slate200 : AppTheme.slate800),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.3,
                      color: isDark ? AppTheme.slate400 : AppTheme.slate500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.brandTeal,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Widget _goalCard({
    required String label,
    required IconData icon,
    required Color accent,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [accent, accent.withValues(alpha: 0.75)],
                )
              : null,
          color: isSelected
              ? null
              : (isDark
                  ? AppTheme.navy700.withValues(alpha: 0.4)
                  : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? accent
                : (isDark ? AppTheme.slate600 : AppTheme.slate200),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 14)]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppTheme.slate400 : accent),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                height: 1.2,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppTheme.slate200 : AppTheme.slate700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chipWrap({
    required List<String> items,
    required List<String> selected,
    required String Function(String) labelBuilder,
    required bool isDark,
    required ValueChanged<String> onToggle,
    Color activeColor = AppTheme.brandTeal,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = selected.contains(item);
        return GestureDetector(
          onTap: () => onToggle(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor
                  : (isDark ? AppTheme.navy700 : AppTheme.slate100),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isSelected
                    ? activeColor
                    : (isDark ? AppTheme.slate600 : AppTheme.slate200),
              ),
            ),
            child: Text(
              labelBuilder(item),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppTheme.slate300 : AppTheme.slate600),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _styledDropdown({
    required String label,
    required String value,
    required Map<String, String> options,
    required bool isDark,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel(label, isDark),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: isDark
                ? AppTheme.navy700.withValues(alpha: 0.45)
                : AppTheme.lightSurfaceTint,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppTheme.slate600 : AppTheme.slate200,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: isDark ? AppTheme.navy800 : Colors.white,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppTheme.slate800,
              ),
              items: options.entries
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}
