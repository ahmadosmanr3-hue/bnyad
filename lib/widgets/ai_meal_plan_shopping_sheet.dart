import 'package:flutter/material.dart';
import 'package:nutrify/widgets/ai_consent.dart';
import 'package:nutrify/utils/ai_strings.dart';
import 'package:provider/provider.dart';
import 'package:nutrify/models/meal.dart';
import 'package:nutrify/providers/app_state.dart';
import 'package:nutrify/theme/app_theme.dart';
import 'package:nutrify/widgets/shopping_feedback_snackbar.dart';

/// Opens a bottom sheet that calls the AI for "what to buy" for the current [MealPlanData].
Future<void> showAiMealPlanShoppingSheet(BuildContext context) async {
  final state = context.read<AppState>();
  if (!await ensureAiConsent(context, state) || !context.mounted) return;
  final t = state.t;
  if (!state.isOnline) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.noInternet)));
    return;
  }
  final plan = state.currentMealPlan;
  if (plan == null) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.needMealPlanForAiShopping)));
    return;
  }
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AiShoppingSheetBody(state: state, plan: plan),
  );
}

String _localized(dynamic value, String lang) => value is Map
    ? (value[lang == 'ckb' ? 'ku' : lang] ?? value['en'] ?? '').toString()
    : value?.toString() ?? '';
List<_BuyRow> _parseBuyItems(Map<String, dynamic>? data, String lang) {
  if (data == null) return [];
  final raw = data['items'] ?? data['buy'] ?? data['toBuy'];
  if (raw is! List) return [];
  final out = <_BuyRow>[];
  for (final e in raw) {
    if (e is Map) {
      final name = _localized(e['name'] ?? e['item'], lang).trim();
      if (name.isEmpty) continue;
      final reason = _localized(
        e['reason'] ?? e['why'] ?? e['note'],
        lang,
      ).trim();
      out.add(_BuyRow(name, reason));
    } else if (e != null) {
      final s = e.toString().trim();
      if (s.isNotEmpty) out.add(_BuyRow(s, ''));
    }
  }
  return out;
}

class _BuyRow {
  final String name;
  final String reason;
  _BuyRow(this.name, this.reason);
}

class _AiShoppingSheetBody extends StatefulWidget {
  final AppState state;
  final MealPlanData plan;

  const _AiShoppingSheetBody({required this.state, required this.plan});

  @override
  State<_AiShoppingSheetBody> createState() => _AiShoppingSheetBodyState();
}

class _AiShoppingSheetBodyState extends State<_AiShoppingSheetBody> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final plan = widget.plan;
    final state = widget.state;
    final t = state.t;
    final eaten = state.eatenMeals;

    final lang = state.lang;
    final pending =
        <({String slotLabel, String dishName, List<String> ingredients})>[];
    if (!eaten.contains('breakfast')) {
      pending.add((
        slotLabel: t.breakfast,
        dishName: plan.breakfast.nameForLang(lang),
        ingredients: plan.breakfast.ingredientsForLang(lang),
      ));
    }
    if (!eaten.contains('lunch')) {
      pending.add((
        slotLabel: t.lunch,
        dishName: plan.lunch.nameForLang(lang),
        ingredients: plan.lunch.ingredientsForLang(lang),
      ));
    }
    if (!eaten.contains('dinner')) {
      pending.add((
        slotLabel: t.dinner,
        dishName: plan.dinner.nameForLang(lang),
        ingredients: plan.dinner.ingredientsForLang(lang),
      ));
    }
    if (!eaten.contains('snacks')) {
      pending.add((
        slotLabel: t.snacks,
        dishName: plan.snacks.nameForLang(lang),
        ingredients: plan.snacks.ingredientsForLang(lang),
      ));
    }

    if (pending.isEmpty) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = t.aiShoppingAllMealsLogged;
      });
      return;
    }

    try {
      final result = await state.ai.generateMealPlanShoppingList(
        pendingMeals: pending,
        lang: state.lang,
      );
      if (!mounted) return;
      if (result == null) {
        setState(() {
          _loading = false;
          _error = AiStrings.get(state.lang, state.aiErrorCode);
        });
        return;
      }
      setState(() {
        _loading = false;
        _data = result;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = widget.state.t.aiShoppingFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final t = state.t;
    final isDark = state.isDark;
    final items = _parseBuyItems(_data, state.lang);
    final intro = _localized(
      _data?['intro'] ?? _data?['summary'],
      state.lang,
    ).trim();

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.smart_toy_outlined,
                      color: isDark ? AppTheme.indigoLight : AppTheme.indigo,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        t.aiShoppingListTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1E293B),
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
              if (_loading)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: AppTheme.indigo),
                        const SizedBox(height: 16),
                        Text(
                          t.aiShoppingLoading,
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_error != null)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.rose),
                      ),
                    ),
                  ),
                )
              else ...[
                if (intro.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Text(
                      intro,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: isDark
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFF475569),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: items.isEmpty
                          ? null
                          : () async {
                              final r = await state
                                  .addIngredientsToShoppingList(
                                    items.map((e) => e.name).toList(),
                                  );
                              if (!context.mounted) return;
                              Navigator.pop(context);
                              showShoppingBulkSnackBar(
                                context,
                                t: t,
                                isDark: isDark,
                                result: r,
                              );
                            },
                      icon: const Icon(Icons.playlist_add, size: 20),
                      label: Text(t.addSuggestedToList),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: items.length,
                    itemBuilder: (_, i) {
                      final row = items[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B).withValues(alpha: 0.5)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                row.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1E293B),
                                ),
                              ),
                              if (row.reason.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  row.reason,
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.35,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
