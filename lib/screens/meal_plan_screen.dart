import 'package:flutter/material.dart';
import 'package:nutrify/widgets/ai_consent.dart';
import 'package:nutrify/utils/ai_strings.dart';
import 'package:provider/provider.dart';
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/models/meal.dart';
import 'package:nutrify/models/nutritional_goals.dart';
import 'package:nutrify/models/log_entry.dart';
import 'package:nutrify/models/favorite_template.dart';
import 'package:nutrify/theme/app_theme.dart';
import 'package:nutrify/utils/meal_micro_estimator.dart';
import 'package:nutrify/utils/meal_micros_resolver.dart';
import 'package:nutrify/widgets/ai_meal_plan_shopping_sheet.dart';
import 'package:nutrify/widgets/shopping_feedback_snackbar.dart';
import 'package:nutrify/utils/ai_trilingual_strings.dart';

class MealPlanScreen extends StatefulWidget {
  const MealPlanScreen({super.key});

  @override
  State<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends State<MealPlanScreen> {
  bool _loading = false;
  bool _generatingAllDetails = false;
  String? _error;
  final Map<String, bool> _detailLoading = {};
  final Map<String, String?> _detailError = {};
  final Map<String, bool> _swapLoading = {};
  final Map<String, GlobalKey> _mealKeys = {
    'breakfast': GlobalKey(),
    'lunch': GlobalKey(),
    'dinner': GlobalKey(),
    'snacks': GlobalKey(),
  };

  Future<void> _generate(AppState state) async {
    if (!await ensureAiConsent(context, state) || !mounted) return;
    if (!state.isOnline) {
      setState(() => _error = state.t.noInternet);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = state.userProfile;
      final sick = profile?.sicknesses ?? [];
      final alle = profile?.allergies ?? [];
      final result = await state.ai.generateMealPlan(
        calories: state.goals?.calories ?? 2200,
        protein: state.goals?.protein ?? 120,
        carbs: state.goals?.carbs ?? 250,
        fat: state.goals?.fat ?? 70,
        goal: state.localizedNutritionGoalLabel,
        healthConditionsSummary: sick.isEmpty
            ? ''
            : state.formatSicknessesForPrompt(sick),
        allergiesSummary: alle.isEmpty
            ? ''
            : state.formatAllergiesForPrompt(alle),
        lang: state.lang,
        mealCuisine: state.mealPlanCuisine,
        dietaryPattern: profile?.dietaryPattern ?? 'omnivore',
        dislikedFoods: profile?.dislikedFoods ?? const [],
        cuisinePreference: profile?.cuisinePreference ?? 'mixed',
        mealsPerDay: profile?.mealsPerDay ?? 4,
        fastingWindow: profile?.fastingWindow ?? 'none',
        cookingSkill: profile?.cookingSkill ?? 'intermediate',
        cookingTime: profile?.cookingTime ?? 'under30',
        pregnancyStatus: profile?.pregnancyStatus ?? 'none',
      );
      if (result != null) {
        final plan = MealPlanData.fromMap(result);
        final review = ['breakfast', 'lunch', 'dinner', 'snacks']
            .map((id) {
              final meal = _mealForId(plan, id);
              return '${meal.nameForLang(state.lang)}\n${meal.ingredientsForLang(state.lang).join('\n')}';
            })
            .join('\n\n');
        if (!mounted ||
            !await confirmAiEstimate(context, state, details: review) ||
            !mounted) {
          return;
        }
        await state.saveMealPlan(plan);
      } else {
        if (mounted) {
          setState(() => _error = AiStrings.get(state.lang, state.aiErrorCode));
        }
      }
    } catch (e) {
      debugPrint('Meal plan error: $e');
      if (!mounted) return;
      setState(() {
        _error =
            e.toString().contains('SocketException') ||
                e.toString().contains('ClientException')
            ? state.t.errorNetwork
            : e.toString().contains('TimeoutException')
            ? state.t.errorTimeout
            : state.t.mealGenerationFailed;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Meal _mealForId(MealPlanData plan, String mealId) {
    switch (mealId) {
      case 'breakfast':
        return plan.breakfast;
      case 'lunch':
        return plan.lunch;
      case 'dinner':
        return plan.dinner;
      case 'snacks':
        return plan.snacks;
      default:
        return plan.breakfast;
    }
  }

  bool _mealNeedsDetails(AppState state, Meal m) =>
      m.needsDetailsForLang(state.lang);

  /// Returns `null` on success, or an error message.
  Future<String?> _runMealDetailsGeneration(
    AppState state,
    String mealId,
    Meal meal,
  ) async {
    if (!await ensureAiConsent(context, state) || !mounted) {
      return state.t.detailsFailed;
    }
    try {
      final sick = state.userProfile?.sicknesses ?? [];
      final alle = state.userProfile?.allergies ?? [];
      final dishLabel = meal.nameForLang(state.lang).isNotEmpty
          ? meal.nameForLang(state.lang)
          : meal.name;
      final details = await state.ai.generateMealDetails(
        mealName: dishLabel,
        slot: mealId,
        calories: meal.calories,
        protein: meal.protein,
        carbs: meal.carbs,
        fat: meal.fat,
        goal: state.localizedNutritionGoalLabel,
        healthConditionsSummary: sick.isEmpty
            ? ''
            : state.formatSicknessesForPrompt(sick),
        allergiesSummary: alle.isEmpty
            ? ''
            : state.formatAllergiesForPrompt(alle),
        lang: state.lang,
        mealCuisine: state.mealPlanCuisine,
      );

      if (details == null) return AiStrings.get(state.lang, state.aiErrorCode);

      final detailMicros = parseMicrosFromJson(details['micros']);
      final mergedMap = Map<String, dynamic>.from(meal.toMap());
      mergedMap['ingredients'] = details['ingredients'];
      mergedMap['instructions'] = details['instructions'];
      for (final key in ['calories', 'protein', 'carbs', 'fat', 'names']) {
        mergedMap[key] = details[key];
      }
      if (detailMicros.isNotEmpty) mergedMap['micros'] = detailMicros;
      final updatedMeal = Meal.fromMap(mergedMap);
      if (!mounted ||
          !await confirmAiEstimate(
            context,
            state,
            details: updatedMeal.ingredientsForLang(state.lang).join('\n'),
          ) ||
          !mounted) {
        return state.t.detailsFailed;
      }

      final current = state.currentMealPlan;
      if (current == null) return state.t.detailsFailed;

      MealPlanData updatedPlan;
      switch (mealId) {
        case 'breakfast':
          updatedPlan = current.copyWith(breakfast: updatedMeal);
          break;
        case 'lunch':
          updatedPlan = current.copyWith(lunch: updatedMeal);
          break;
        case 'dinner':
          updatedPlan = current.copyWith(dinner: updatedMeal);
          break;
        case 'snacks':
          updatedPlan = current.copyWith(snacks: updatedMeal);
          break;
        default:
          updatedPlan = current;
      }

      return await state.saveMealPlan(updatedPlan)
          ? null
          : state.t.detailsFailed;
    } catch (e) {
      return e.toString().contains('SocketException')
          ? state.t.errorNetwork
          : state.t.detailsFailed;
    }
  }

  Future<void> _generateDetailsForMeal(
    AppState state,
    String mealId,
    Meal meal,
  ) async {
    setState(() {
      _detailLoading[mealId] = true;
      _detailError[mealId] = null;
    });

    final err = await _runMealDetailsGeneration(state, mealId, meal);

    if (mounted) {
      setState(() {
        _detailLoading[mealId] = false;
        if (err != null) _detailError[mealId] = err;
      });
    }
  }

  Future<void> _generateAllMealDetails(
    BuildContext context,
    AppState state,
  ) async {
    if (!state.isOnline) {
      setState(() => _error = state.t.noInternet);
      return;
    }
    final plan = state.currentMealPlan;
    if (plan == null) return;

    setState(() {
      _generatingAllDetails = true;
      _error = null;
      for (final id in const ['breakfast', 'lunch', 'dinner', 'snacks']) {
        _detailError[id] = null;
      }
    });

    var filled = 0;
    var skipped = 0;
    var hadFailure = false;

    for (final mealId in const ['breakfast', 'lunch', 'dinner', 'snacks']) {
      if (!mounted) break;
      var currentPlan = state.currentMealPlan;
      if (currentPlan == null) break;

      final meal = _mealForId(currentPlan, mealId);
      if (!_mealNeedsDetails(state, meal)) {
        skipped++;
        continue;
      }

      setState(() {
        _detailLoading[mealId] = true;
        _detailError[mealId] = null;
      });

      final err = await _runMealDetailsGeneration(state, mealId, meal);

      if (!mounted) break;

      setState(() {
        _detailLoading[mealId] = false;
        if (err != null) {
          _detailError[mealId] = err;
          hadFailure = true;
        } else {
          filled++;
        }
      });
    }

    if (mounted) {
      setState(() => _generatingAllDetails = false);
    }

    if (!context.mounted) return;
    final t = state.t;
    final messenger = ScaffoldMessenger.of(context);
    if (filled == 0 && skipped == 4 && !hadFailure) {
      messenger.showSnackBar(
        SnackBar(content: Text(t.allMealsAlreadyDetailed)),
      );
    } else if (filled > 0 && !hadFailure) {
      messenger.showSnackBar(
        SnackBar(content: Text(t.allDetailsGeneratedSuccess(filled))),
      );
    } else if (filled > 0 && hadFailure) {
      messenger.showSnackBar(
        SnackBar(content: Text(t.allDetailsPartialSuccess(filled))),
      );
    } else if (hadFailure && filled == 0) {
      messenger.showSnackBar(SnackBar(content: Text(t.allDetailsAllFailed)));
    }
  }

  Future<void> _swapMeal(
    AppState state,
    String mealId,
    Meal currentMeal,
  ) async {
    if (!await ensureAiConsent(context, state) || !mounted) return;
    setState(() => _swapLoading[mealId] = true);
    try {
      final alle = state.userProfile?.allergies ?? [];
      final result = await state.ai.generateSingleMeal(
        mealSlotLabel: mealId,
        currentName: currentMeal.nameForLang('en').isNotEmpty
            ? currentMeal.nameForLang('en')
            : currentMeal.name,
        calories: currentMeal.calories,
        protein: currentMeal.protein,
        carbs: currentMeal.carbs,
        fat: currentMeal.fat,
        goal: state.localizedNutritionGoalLabel,
        allergiesSummary: alle.isEmpty
            ? ''
            : state.formatAllergiesForPrompt(alle),
        lang: state.lang,
        mealCuisine: state.mealPlanCuisine,
      );

      if (result != null) {
        final newMeal = Meal.fromMap(result);
        if (!mounted ||
            !await confirmAiEstimate(
              context,
              state,
              details: newMeal.ingredientsForLang(state.lang).join('\n'),
            ) ||
            !mounted) {
          return;
        }
        final current = state.currentMealPlan;
        if (current == null) return;

        MealPlanData updatedPlan;
        switch (mealId) {
          case 'breakfast':
            updatedPlan = current.copyWith(breakfast: newMeal);
            break;
          case 'lunch':
            updatedPlan = current.copyWith(lunch: newMeal);
            break;
          case 'dinner':
            updatedPlan = current.copyWith(dinner: newMeal);
            break;
          case 'snacks':
            updatedPlan = current.copyWith(snacks: newMeal);
            break;
          default:
            updatedPlan = current;
        }
        await state.saveMealPlan(updatedPlan);
      }
    } catch (e) {
      debugPrint('Swap meal error: $e');
    } finally {
      if (mounted) setState(() => _swapLoading[mealId] = false);
    }
  }

  void _showIngredientDialog(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _IngredientRecipeSheet(state: state),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final t = state.t;
    final isDark = state.isDark;
    final plan = state.currentMealPlan;

    if (state.targetMealId != null && plan != null) {
      final targetId = state.targetMealId!;
      state.clearTargetMealId();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final key = _mealKeys[targetId];
        if (key?.currentContext != null) {
          Scrollable.ensureVisible(
            key!.currentContext!,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            alignment: 0.1,
          );
        }
      });
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.mealPlan,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: isDark ? AppTheme.slate50 : AppTheme.slate900,
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _loading ? null : () => _generate(state),
                  borderRadius: BorderRadius.circular(18),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        colors: _loading
                            ? [AppTheme.slate600, AppTheme.slate700]
                            : [AppTheme.indigoLight, AppTheme.indigoDark],
                      ),
                      boxShadow: _loading
                          ? null
                          : [
                              BoxShadow(
                                color: AppTheme.indigo.withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_loading)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          const Icon(
                            Icons.auto_fix_high_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                        const SizedBox(width: 8),
                        Text(
                          plan != null ? t.regenerate : t.generatePlan,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MealCuisineChips(state: state, isDark: isDark, t: t),
          const SizedBox(height: 20),

          if (_error != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.rose.withValues(alpha: 0.1)
                    : const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark
                      ? AppTheme.rose.withValues(alpha: 0.3)
                      : const Color(0xFFFECDD3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 16,
                    color: AppTheme.rose,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.rose,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _generate(state),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.rose.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        t.tryAgain,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.rose,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (plan == null && !_loading) _buildEmptyState(t, isDark, state),
          if (_loading) _buildLoading(t, isDark),
          if (!_loading)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _MealPlanWideAction(
                isDark: isDark,
                icon: Icons.restaurant_menu_rounded,
                accent: AppTheme.violet,
                title: t.cookWithIngredients,
                onTap: () => _showIngredientDialog(context, state),
              ),
            ),

          if (plan != null && !_loading) ...[
            _MealPlanPremiumShell(
              isDark: isDark,
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _MealPlanAiTile(
                      isDark: isDark,
                      icon: Icons.shopping_bag_rounded,
                      accent: AppTheme.indigo,
                      title: t.aiShoppingListButton,
                      subtitle:
                          (plan.breakfast
                                  .ingredientsForLang(state.lang)
                                  .isEmpty &&
                              plan.lunch
                                  .ingredientsForLang(state.lang)
                                  .isEmpty &&
                              plan.dinner
                                  .ingredientsForLang(state.lang)
                                  .isEmpty &&
                              plan.snacks
                                  .ingredientsForLang(state.lang)
                                  .isEmpty)
                          ? t.aiShoppingDetailsHint
                          : null,
                      enabled: state.isOnline && !_generatingAllDetails,
                      onTap: () => showAiMealPlanShoppingSheet(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MealPlanAiTile(
                      isDark: isDark,
                      icon: Icons.auto_awesome_rounded,
                      accent: AppTheme.cyan,
                      title: _generatingAllDetails
                          ? t.generateAllDetailsBusy
                          : t.generateAllDetailsButton,
                      subtitle: t.generateAllDetailsHint,
                      enabled:
                          state.isOnline && !_generatingAllDetails && !_loading,
                      loading: _generatingAllDetails,
                      onTap: () => _generateAllMealDetails(context, state),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _MealCard(
              key: _mealKeys['breakfast'],
              title: t.breakfast,
              meal: plan.breakfast,
              mealId: 'breakfast',
              state: state,
              detailLoading: _detailLoading['breakfast'] ?? false,
              detailError: _detailError['breakfast'],
              onGenerateDetails: () =>
                  _generateDetailsForMeal(state, 'breakfast', plan.breakfast),
              swapLoading: _swapLoading['breakfast'] ?? false,
              onSwapMeal: () => _swapMeal(state, 'breakfast', plan.breakfast),
              bulkDetailsRunning: _generatingAllDetails,
            ),
            const SizedBox(height: 16),
            _MealCard(
              key: _mealKeys['lunch'],
              title: t.lunch,
              meal: plan.lunch,
              mealId: 'lunch',
              state: state,
              detailLoading: _detailLoading['lunch'] ?? false,
              detailError: _detailError['lunch'],
              onGenerateDetails: () =>
                  _generateDetailsForMeal(state, 'lunch', plan.lunch),
              swapLoading: _swapLoading['lunch'] ?? false,
              onSwapMeal: () => _swapMeal(state, 'lunch', plan.lunch),
              bulkDetailsRunning: _generatingAllDetails,
            ),
            const SizedBox(height: 16),
            _MealCard(
              key: _mealKeys['dinner'],
              title: t.dinner,
              meal: plan.dinner,
              mealId: 'dinner',
              state: state,
              detailLoading: _detailLoading['dinner'] ?? false,
              detailError: _detailError['dinner'],
              onGenerateDetails: () =>
                  _generateDetailsForMeal(state, 'dinner', plan.dinner),
              swapLoading: _swapLoading['dinner'] ?? false,
              onSwapMeal: () => _swapMeal(state, 'dinner', plan.dinner),
              bulkDetailsRunning: _generatingAllDetails,
            ),
            const SizedBox(height: 16),
            _MealCard(
              key: _mealKeys['snacks'],
              title: t.snacks,
              meal: plan.snacks,
              mealId: 'snacks',
              state: state,
              detailLoading: _detailLoading['snacks'] ?? false,
              detailError: _detailError['snacks'],
              onGenerateDetails: () =>
                  _generateDetailsForMeal(state, 'snacks', plan.snacks),
              swapLoading: _swapLoading['snacks'] ?? false,
              onSwapMeal: () => _swapMeal(state, 'snacks', plan.snacks),
              bulkDetailsRunning: _generatingAllDetails,
            ),
            const SizedBox(height: 16),
            _DailyTotalCard(
              plan: plan,
              goals: state.goals,
              isDark: isDark,
              t: t,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(dynamic t, bool isDark, AppState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.indigo.withValues(alpha: 0.1)
                    : AppTheme.lightSurfaceTint,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.refresh, size: 48, color: AppTheme.indigo),
            ),
            const SizedBox(height: 24),
            Text(
              t.noMealPlan,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                t.noMealPlanDesc,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _MealCuisineChips(state: state, isDark: isDark, t: t),
            ),
            const SizedBox(height: 20),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _generate(state),
                borderRadius: BorderRadius.circular(18),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      colors: [AppTheme.indigoLight, AppTheme.indigoDark],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.indigo.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Text(
                    t.generatePlan,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading(dynamic t, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80),
      child: Center(
        child: Column(
          children: [
            const CircularProgressIndicator(color: AppTheme.indigo),
            const SizedBox(height: 16),
            Text(
              t.analyzing,
              style: TextStyle(
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MealPlanPremiumShell extends StatelessWidget {
  final bool isDark;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _MealPlanPremiumShell({
    required this.isDark,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    final outer = isDark
        ? [const Color(0xFF3D4152), const Color(0xFF1C1F2A)]
        : [const Color(0xFFDDD7CE), const Color(0xFFC9C2B6)];
    final inner = isDark ? const Color(0xFF0E1018) : const Color(0xFFFDFBF7);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF5C5348).withValues(alpha: 0.07),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
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
              borderRadius: BorderRadius.circular(23),
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

class _MealPlanAiTile extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color accent;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool enabled;
  final bool loading;

  const _MealPlanAiTile({
    required this.isDark,
    required this.icon,
    required this.accent,
    required this.title,
    this.subtitle,
    this.onTap,
    this.enabled = true,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? AppTheme.slate50 : AppTheme.slate900;
    final muted = isDark ? AppTheme.slate500 : AppTheme.slate600;
    final canTap = enabled && !loading && onTap != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canTap ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      accent.withValues(alpha: 0.18),
                      accent.withValues(alpha: 0.05),
                    ]
                  : [
                      accent.withValues(alpha: 0.14),
                      Colors.white.withValues(alpha: 0.4),
                    ],
            ),
            border: Border.all(
              color: accent.withValues(alpha: isDark ? 0.4 : 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: isDark ? 0.45 : 0.3),
                      accent.withValues(alpha: isDark ? 0.2 : 0.12),
                    ],
                  ),
                ),
                child: loading
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark ? Colors.white : accent,
                        ),
                      )
                    : Icon(
                        icon,
                        size: 22,
                        color: isDark ? Colors.white : accent,
                      ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                  letterSpacing: -0.2,
                  color: titleColor,
                ),
              ),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    color: muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MealPlanCompactAction extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final String label;
  final Color accent;
  final bool enabled;
  final VoidCallback? onTap;

  const _MealPlanCompactAction({
    required this.isDark,
    required this.icon,
    required this.label,
    required this.accent,
    this.enabled = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final canTap = enabled && onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canTap ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isDark
                ? accent.withValues(alpha: enabled ? 0.12 : 0.05)
                : accent.withValues(alpha: enabled ? 0.1 : 0.05),
            border: Border.all(
              color: accent.withValues(
                alpha: enabled ? (isDark ? 0.4 : 0.35) : 0.15,
              ),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: enabled ? accent : accent.withValues(alpha: 0.35),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: enabled
                      ? (isDark ? AppTheme.slate200 : AppTheme.slate800)
                      : AppTheme.slate500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MealPlanWideAction extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color accent;
  final String title;
  final VoidCallback? onTap;

  const _MealPlanWideAction({
    required this.isDark,
    required this.icon,
    required this.accent,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1A1D28), const Color(0xFF12141C)]
                  : [Colors.white, const Color(0xFFF5F2ED)],
            ),
            border: Border.all(
              color: isDark
                  ? AppTheme.slate700.withValues(alpha: 0.85)
                  : AppTheme.slate200,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFF5C5348).withValues(alpha: 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: accent.withValues(alpha: isDark ? 0.2 : 0.12),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: isDark ? accent.withValues(alpha: 0.95) : accent,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                    color: isDark ? AppTheme.slate50 : AppTheme.slate900,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? AppTheme.slate500 : AppTheme.slate400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MealCuisineChips extends StatelessWidget {
  final AppState state;
  final bool isDark;
  final dynamic t;

  const _MealCuisineChips({
    required this.state,
    required this.isDark,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final cur = state.mealPlanCuisine;
    Widget chip(String id, String label) {
      final selected = cur == id;
      return ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: selected
                ? Colors.white
                : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
          ),
        ),
        selected: selected,
        onSelected: (v) {
          if (v) state.setMealPlanCuisine(id);
        },
        selectedColor: AppTheme.indigo,
        backgroundColor: isDark
            ? const Color(0xFF1E293B)
            : const Color(0xFFF1F5F9),
        side: BorderSide(
          color: selected
              ? AppTheme.indigo
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.mealCuisineStyle,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            chip('kurdish', t.cuisineKurdish),
            chip('arabic', t.cuisineArabic),
            chip('all', t.cuisineAll),
          ],
        ),
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  final String title;
  final Meal meal;
  final String mealId;
  final AppState state;
  final bool detailLoading;
  final String? detailError;
  final VoidCallback onGenerateDetails;
  final bool swapLoading;
  final VoidCallback onSwapMeal;
  final bool bulkDetailsRunning;

  const _MealCard({
    super.key,
    required this.title,
    required this.meal,
    required this.mealId,
    required this.state,
    required this.detailLoading,
    required this.detailError,
    required this.onGenerateDetails,
    required this.swapLoading,
    required this.onSwapMeal,
    this.bulkDetailsRunning = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = state.t;
    final isDark = state.isDark;
    final lang = state.lang;
    final dishName = meal.nameForLang(lang);
    final ingList = meal.ingredientsForLang(lang);
    final instList = meal.instructionsForLang(lang);
    final isEaten = state.eatenMeals.contains(mealId);

    return _MealPlanPremiumShell(
      isDark: isDark,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: AppTheme.indigo,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dishName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              swapLoading
                  ? const SizedBox(
                      width: 28,
                      height: 28,
                      child: Padding(
                        padding: EdgeInsets.all(4),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.indigo,
                        ),
                      ),
                    )
                  : SizedBox(
                      width: 28,
                      height: 28,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        iconSize: 20,
                        tooltip: t.swapMeal,
                        onPressed: bulkDetailsRunning ? null : onSwapMeal,
                        icon: Icon(
                          Icons.swap_horiz,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
              const SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${meal.calories}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppTheme.indigoLight : AppTheme.indigo,
                    ),
                  ),
                  Text(
                    t.kcal,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _mealStat(
                t.protein,
                meal.protein,
                isDark ? const Color(0xFFFB7185) : AppTheme.rose,
                isDark,
              ),
              const SizedBox(width: 8),
              _mealStat(
                t.carbs,
                meal.carbs,
                isDark ? const Color(0xFFFBBF24) : AppTheme.amber,
                isDark,
              ),
              const SizedBox(width: 8),
              _mealStat(
                t.fat,
                meal.fat,
                isDark ? const Color(0xFF34D399) : AppTheme.emerald,
                isDark,
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (meal.needsDetailsForLang(lang)) ...[
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: (detailLoading || bulkDetailsRunning)
                    ? null
                    : onGenerateDetails,
                borderRadius: BorderRadius.circular(18),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.indigo.withValues(alpha: isDark ? 0.22 : 0.12),
                        AppTheme.violet.withValues(alpha: isDark ? 0.12 : 0.08),
                      ],
                    ),
                    border: Border.all(
                      color: AppTheme.indigo.withValues(
                        alpha: isDark ? 0.45 : 0.35,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (detailLoading || bulkDetailsRunning)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.indigo,
                          ),
                        )
                      else
                        Icon(
                          Icons.auto_fix_high_rounded,
                          size: 18,
                          color: isDark
                              ? AppTheme.indigoLight
                              : AppTheme.indigoDark,
                        ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          t.generateDetails,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? AppTheme.slate50
                                : AppTheme.slate900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (detailError != null) ...[
              const SizedBox(height: 10),
              Text(
                detailError!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.rose,
                ),
              ),
            ],
          ] else ...[
            Text(
              t.ingredients,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: ingList
                  .map(
                    (ing) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        ing,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            Text(
              t.instructions,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: isDark
                    ? const Color(0xFF64748B)
                    : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 8),
            ...instList.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${e.key + 1}. ',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.indigo,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        e.value,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: isDark
                              ? const Color(0xFFCBD5E1)
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: isEaten
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.emerald.withValues(alpha: 0.1)
                          : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? AppTheme.emerald.withValues(alpha: 0.2)
                            : AppTheme.emerald.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 16,
                          color: isDark
                              ? const Color(0xFF34D399)
                              : AppTheme.emerald,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          t.loggedAsEaten,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            color: isDark
                                ? const Color(0xFF34D399)
                                : AppTheme.emerald,
                          ),
                        ),
                      ],
                    ),
                  )
                : Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
                        if (!await confirmAiEstimate(
                              context,
                              state,
                              details: meal
                                  .ingredientsForLang(state.lang)
                                  .join('\n'),
                            ) ||
                            !context.mounted) {
                          return;
                        }
                        final micros = meal.micros;
                        state.addLogEntry(
                          LogEntry(
                            id: DateTime.now().millisecondsSinceEpoch
                                .toString(),
                            foodId: 'ai-meal-$mealId',
                            name: dishName,
                            amount:
                                meal.portionGrams ??
                                estimatedMealGramsForDisplay(meal.calories),
                            calories: meal.calories,
                            protein: meal.protein,
                            carbs: meal.carbs,
                            fat: meal.fat,
                            timestamp: DateTime.now().millisecondsSinceEpoch,
                            mealId: mealId,
                            micros: micros,
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Ink(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            colors: [AppTheme.indigoLight, AppTheme.indigoDark],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.indigo.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_circle_outline_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              t.logAsEaten,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MealPlanCompactAction(
                  isDark: isDark,
                  icon: Icons.shopping_cart_rounded,
                  label: t.addPlanIngredients,
                  accent: AppTheme.emerald,
                  enabled: ingList.isNotEmpty,
                  onTap: ingList.isEmpty
                      ? null
                      : () async {
                          final r = await state.addIngredientsToShoppingList(
                            ingList,
                          );
                          if (!context.mounted) return;
                          showShoppingBulkSnackBar(
                            context,
                            t: t,
                            isDark: isDark,
                            result: r,
                          );
                        },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MealPlanCompactAction(
                  isDark: isDark,
                  icon: Icons.bookmark_added_rounded,
                  label: t.saveMealTemplate,
                  accent: AppTheme.amberDeep,
                  onTap: () async {
                    final grams = estimatedMealGramsForDisplay(
                      meal.calories,
                    ).toDouble();
                    await state.addFavorite(
                      FavoriteTemplate(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: '$title · $dishName',
                        foodId: 'ai-meal-$mealId',
                        amount: grams,
                        calories: meal.calories.toDouble(),
                        protein: meal.protein.toDouble(),
                        carbs: meal.carbs.toDouble(),
                        fat: meal.fat.toDouble(),
                        micros: meal.micros,
                      ),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(t.savedFavorite)));
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mealStat(String label, int value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E293B).withValues(alpha: 0.3)
              : const Color(0xFFF8FAFC).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: Color(0xFF64748B),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$value ${state.t.grams}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyTotalCard extends StatelessWidget {
  final MealPlanData plan;
  final NutritionalGoals? goals;
  final bool isDark;
  final dynamic t;

  const _DailyTotalCard({
    required this.plan,
    required this.goals,
    required this.isDark,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final totalCal =
        plan.breakfast.calories +
        plan.lunch.calories +
        plan.dinner.calories +
        plan.snacks.calories;
    final totalP =
        plan.breakfast.protein +
        plan.lunch.protein +
        plan.dinner.protein +
        plan.snacks.protein;
    final totalC =
        plan.breakfast.carbs +
        plan.lunch.carbs +
        plan.dinner.carbs +
        plan.snacks.carbs;
    final totalF =
        plan.breakfast.fat + plan.lunch.fat + plan.dinner.fat + plan.snacks.fat;

    final goalCal = goals?.calories ?? 2200;
    final goalP = goals?.protein ?? 120;
    final goalC = goals?.carbs ?? 250;
    final goalF = goals?.fat ?? 70;

    final calPct = (totalCal / goalCal * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppTheme.indigo.withValues(alpha: 0.15),
                  const Color(0xFF0F172A).withValues(alpha: 0.6),
                ]
              : [
                  AppTheme.lightSurfaceTint,
                  Colors.white.withValues(alpha: 0.8),
                ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? AppTheme.indigo.withValues(alpha: 0.3)
              : AppTheme.lightSurfaceTint2,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart_outline, size: 18, color: AppTheme.indigo),
              const SizedBox(width: 8),
              Text(
                t.dailyTotal,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  color: isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: calPct >= 90
                      ? AppTheme.emerald.withValues(alpha: 0.15)
                      : AppTheme.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$calPct% ${t.ofGoal}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: calPct >= 90 ? AppTheme.emerald : AppTheme.amber,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _totalStat(t.calories, '$totalCal / $goalCal', AppTheme.indigo),
              const SizedBox(width: 8),
              _totalStat(t.protein, '${totalP}g / ${goalP}g', AppTheme.rose),
              const SizedBox(width: 8),
              _totalStat(t.carbs, '${totalC}g / ${goalC}g', AppTheme.amber),
              const SizedBox(width: 8),
              _totalStat(t.fat, '${totalF}g / ${goalF}g', AppTheme.emerald),
            ],
          ),
        ],
      ),
    );
  }

  Widget _totalStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark
              ? color.withValues(alpha: 0.08)
              : color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(
                value,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IngredientRecipeSheet extends StatefulWidget {
  final AppState state;
  const _IngredientRecipeSheet({required this.state});

  @override
  State<_IngredientRecipeSheet> createState() => _IngredientRecipeSheetState();
}

class _IngredientRecipeSheetState extends State<_IngredientRecipeSheet> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Map<String, dynamic>? get _recipe => widget.state.savedRecipe;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (!await ensureAiConsent(context, widget.state) || !mounted) return;
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;

    final ingredients = text
        .split(RegExp(r'[,،\n]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (ingredients.isEmpty) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final state = widget.state;
    try {
      final alle = state.userProfile?.allergies ?? [];
      final g = state.goals;
      final p = state.userProfile;
      final result = await state.ai.generateRecipeFromIngredients(
        ingredients: ingredients,
        targetCalories: state.goals?.calories != null
            ? (state.goals!.calories ~/ 3)
            : 500,
        goal: state.localizedNutritionGoalLabel,
        allergiesSummary: alle.isEmpty
            ? ''
            : state.formatAllergiesForPrompt(alle),
        dailyCalories: g?.calories ?? p?.dailyCalories ?? 2200,
        dailyProtein: g?.protein ?? 120,
        dailyCarbs: g?.carbs ?? 250,
        dailyFat: g?.fat ?? 70,
        lang: state.lang,
      );
      if (mounted) {
        if (result != null) {
          final preview = Meal.fromMap(result);
          if (!await confirmAiEstimate(
                context,
                state,
                details: preview.ingredientsForLang(state.lang).join('\n'),
              ) ||
              !mounted) {
            return;
          }
          await state.saveCustomRecipe(result);
        } else {
          _error = AiStrings.get(state.lang, state.aiErrorCode);
        }
        setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().contains('SocketException')
              ? state.t.errorNetwork
              : state.t.recipeGenerationFailed;
          _loading = false;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final t = state.t;
    final isDark = state.isDark;
    final lang = state.lang;
    final recipeMap = _recipe != null
        ? Map<String, dynamic>.from(_recipe!)
        : null;
    final recipeTitle = recipeMap != null
        ? trilingualString(
            recipeMap,
            mapKey: 'names',
            legacyKey: 'name',
            lang: lang,
          )
        : '';
    final recipeIngs = recipeMap != null
        ? trilingualStringList(
            recipeMap,
            mapKey: 'ingredients',
            legacyKey: 'ingredients',
            lang: lang,
          )
        : <String>[];
    final recipeSteps = recipeMap != null
        ? trilingualStringList(
            recipeMap,
            mapKey: 'instructions',
            legacyKey: 'instructions',
            lang: lang,
          )
        : <String>[];

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(Icons.kitchen, size: 22, color: AppTheme.indigo),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t.cookWithIngredients,
                    style: TextStyle(
                      fontSize: 18,
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
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.enterIngredients,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ctrl,
                    maxLines: 3,
                    decoration: InputDecoration(hintText: t.ingredientsHint),
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _generate,
                      icon: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_awesome, size: 18),
                      label: Text(t.generateRecipe),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: AppTheme.rose,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (_recipe != null) ...[
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        const Text('✨', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t.aiRecipe,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: AppTheme.rose,
                          ),
                          onPressed: () {
                            state.clearCustomRecipe();
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      recipeTitle,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      icon: const Icon(Icons.add),
                      label: Text(t.logAsEaten),
                      onPressed: () async {
                        final meal = Meal.fromMap(recipeMap!);
                        if (!await confirmAiEstimate(
                              context,
                              state,
                              details: meal
                                  .ingredientsForLang(state.lang)
                                  .join('\n'),
                            ) ||
                            !context.mounted) {
                          return;
                        }
                        final saved = await state.addLogEntry(
                          LogEntry(
                            id: DateTime.now().millisecondsSinceEpoch
                                .toString(),
                            foodId: 'ai-custom-recipe',
                            name: meal.nameForLang(state.lang),
                            amount: meal.portionGrams ?? 100,
                            calories: meal.calories,
                            protein: meal.protein,
                            carbs: meal.carbs,
                            fat: meal.fat,
                            timestamp: DateTime.now().millisecondsSinceEpoch,
                            micros: meal.micros,
                          ),
                        );
                        if (saved && context.mounted) Navigator.pop(context);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _recipeStat(
                          t.calories,
                          '${_recipe!['calories'] ?? 0}',
                          AppTheme.indigo,
                          isDark,
                        ),
                        const SizedBox(width: 8),
                        _recipeStat(
                          t.protein,
                          '${_recipe!['protein'] ?? 0}g',
                          AppTheme.rose,
                          isDark,
                        ),
                        const SizedBox(width: 8),
                        _recipeStat(
                          t.carbs,
                          '${_recipe!['carbs'] ?? 0}g',
                          AppTheme.amber,
                          isDark,
                        ),
                        const SizedBox(width: 8),
                        _recipeStat(
                          t.fat,
                          '${_recipe!['fat'] ?? 0}g',
                          AppTheme.emerald,
                          isDark,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t.ingredients,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...recipeIngs.map(
                      (ing) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• ',
                              style: TextStyle(
                                color: AppTheme.indigo,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                ing,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t.instructions,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        color: isDark
                            ? const Color(0xFF64748B)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...recipeSteps.asMap().entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${e.key + 1}. ',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.indigo,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                e.value,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color: isDark
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recipeStat(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E293B).withValues(alpha: 0.3)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
