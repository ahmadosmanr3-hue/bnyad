import 'package:flutter/material.dart';
import 'package:nutrify/l10n/scan_result_strings.dart';
import 'package:nutrify/models/food_item.dart';
import 'package:nutrify/models/scan_meal_draft.dart';
import 'package:nutrify/widgets/portion_editor.dart';

/// A separate route keeps the scanner's bottom navigation out of the review
/// controls. All food choices come from the active catalog, never model macros.
class ScanResultEditor extends StatefulWidget {
  const ScanResultEditor({
    super.key,
    required this.draft,
    required this.foods,
    required this.disabled,
    required this.lang,
    required this.onSave,
    this.simulated = false,
  });
  final ScanMealDraft draft;
  final Map<String, FoodItem> foods;
  final Set<String> disabled;
  final String lang;
  final Future<bool> Function(ScanMealDraft) onSave;
  final bool simulated;
  @override
  State<ScanResultEditor> createState() => _ScanResultEditorState();
}

class _ScanResultEditorState extends State<ScanResultEditor> {
  ScanMealDraft get draft => widget.draft;
  ScanResultStrings get s => ScanResultStrings(widget.lang);
  late final title = TextEditingController(text: draft.title);
  bool saving = false;
  String? error;
  @override
  void didUpdateWidget(covariant ScanResultEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.foods, widget.foods)) return;
    draft.confirmed = false;
    for (final portion in [...draft.items]) {
      final current = widget.foods[portion.food.id];
      if (current == null ||
          !validScanFood(current) ||
          widget.disabled.contains(current.id) ||
          widget.disabled.contains(current.canonicalKey) ||
          current.nutritionUnit != portion.food.nutritionUnit) {
        draft.pending.add(portion.food.getLocalizedName(widget.lang));
        draft.items.remove(portion);
      } else {
        portion.food = current;
      }
    }
  }

  @override
  void dispose() {
    title.dispose();
    super.dispose();
  }

  void change(VoidCallback action) => setState(() {
    action();
    draft.confirmed = false;
    error = null;
  });
  String number(double n) => n.toStringAsFixed(n == n.roundToDouble() ? 0 : 1);
  Widget numeric(String value, {TextStyle? style}) =>
      Text(value, textDirection: TextDirection.ltr, style: style);

  Future<bool> replaceList() async =>
      draft.items.isEmpty ||
      await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(s.reset),
              content: Text(s.modeHint),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(s.cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(s.change),
                ),
              ],
            ),
          ) ==
          true;

  Future<void> choose({
    int? index,
    int? pendingIndex,
    Map<String, dynamic>? candidate,
    bool whole = false,
  }) async {
    FocusScope.of(context).unfocus();
    final initial =
        candidate?.values.whereType<String>().toList() ?? <String>[];
    var query = '';
    final chosen = await showModalBottomSheet<FoodItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, update) {
          final results = scanCatalogMatches(
            widget.foods.values,
            widget.disabled,
            query.isEmpty ? initial : [query],
          );
          final allowed = whole || draft.mode == 'dish'
              ? results
              : results
                    .where(
                      (f) => !preparedScanCategories.contains(f.categoryId),
                    )
                    .toList();
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(sheet).bottom,
            ),
            child: SizedBox(
              height: MediaQuery.sizeOf(sheet).height * .78,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.choose,
                            style: Theme.of(sheet).textTheme.titleLarge,
                          ),
                        ),
                        IconButton(
                          tooltip: s.cancel,
                          onPressed: () => Navigator.pop(sheet),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      key: const ValueKey('scan-search'),
                      onChanged: (q) => update(() => query = q),
                      decoration: InputDecoration(
                        labelText: s.search,
                        prefixIcon: const Icon(Icons.search),
                        helperText: initial.isEmpty ? null : initial.first,
                        helperMaxLines: 2,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: allowed.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(s.noMatches),
                            ),
                          )
                        : ListView.builder(
                            itemCount: allowed.length,
                            itemBuilder: (context, i) {
                              final f = allowed[i];
                              return ListTile(
                                key: ValueKey('scan-food-${f.id}'),
                                title: Text(f.getLocalizedName(widget.lang)),
                                subtitle: Text(
                                  '${number(f.calories)} kcal / ${number(f.nutritionReferenceG)} ${f.nutritionUnit}',
                                  textDirection: TextDirection.ltr,
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => Navigator.pop(sheet, f),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (chosen == null || !mounted) return;
    final isWhole = whole || draft.mode == 'dish';
    if (isWhole && index == null && !await replaceList()) return;
    if (!mounted) return;
    final duplicate = draft.items.indexWhere(
      (p) => p.food.canonicalKey == chosen.canonicalKey,
    );
    if (!isWhole && duplicate >= 0 && duplicate != index) {
      setState(() => error = s.invalid);
      return;
    }
    change(() {
      // A new food identity does not inherit an unrelated g or mL quantity.
      final amount =
          index != null &&
              draft.items[index].food.nutritionUnit == chosen.nutritionUnit
          ? draft.items[index].amount
          : isWhole && !chosen.isLiquid
          ? draft.weighedGrams
          : null;
      final portion = ScanFoodPortion(chosen, amount);
      if (isWhole) {
        draft.mode = 'dish';
        draft.items.clear();
        draft.pending.clear();
        draft.items.add(portion);
        draft.title = chosen.getLocalizedName(widget.lang);
        title.text = draft.title;
      } else if (index != null) {
        draft.items[index] = portion;
      } else {
        draft.items.add(portion);
      }
      if (!isWhole && pendingIndex != null) {
        draft.pending.removeAt(pendingIndex);
      }
    });
    await editPortion(draft.items.indexWhere((p) => p.food.id == chosen.id));
  }

  Future<void> editPortion(int i) async {
    final item = draft.items[i];
    double? amount = item.amount;
    // Empty initial quantities must be explicitly supplied, rather than
    // presenting an invented 100 g as an AI portion estimate.
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheet) => StatefulBuilder(
        builder: (sheet, update) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheet).bottom,
          ),
          child: SizedBox(
            height: MediaQuery.sizeOf(sheet).height * .86,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.food.getLocalizedName(widget.lang),
                          style: Theme.of(sheet).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: s.cancel,
                        onPressed: () => Navigator.pop(sheet),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        PortionEditor(
                          food: item.food,
                          lang: widget.lang,
                          amount: amount ?? 0,
                          onChanged: (v) => update(() => amount = v),
                        ),
                        const SizedBox(height: 12),
                        if (amount != null && amount! > 0)
                          macros(ScanFoodPortion(item.food, amount).totals),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const ValueKey('scan-apply-portion'),
                        onPressed:
                            amount != null &&
                                amount!.isFinite &&
                                amount! > 0 &&
                                amount! <= 10000
                            ? () => Navigator.pop(sheet, amount)
                            : null,
                        child: Text(s.apply),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (result != null && mounted) change(() => item.amount = result);
  }

  Widget macros(Map<String, double> totals, {bool summary = false}) =>
      LayoutBuilder(
        builder: (context, constraints) => Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in [
              ('calories', s.calories, 'kcal'),
              ('protein', s.protein, 'g'),
              ('carbs', s.carbs, 'g'),
              ('fat', s.fat, 'g'),
            ])
              SizedBox(
                width: (constraints.maxWidth - 8) / 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.$2,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    numeric(
                      '${number(totals[entry.$1]!)} ${entry.$3}',
                      style: summary
                          ? Theme.of(context).textTheme.titleMedium
                          : Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
          ],
        ),
      );

  Future<void> save() async {
    if (saving || !draft.valid || !draft.confirmed) return;
    setState(() {
      saving = true;
      error = null;
    });
    bool saved = false;
    try {
      saved = await widget.onSave(draft);
    } catch (_) {
      /* Keep edits for review. */
    }
    if (!mounted) return;
    if (saved) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      saving = false;
      draft.confirmed = false;
      error = s.failed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    final colors = Theme.of(context).colorScheme;
    return PopScope(
      canPop: !saving,
      child: Directionality(
        textDirection: ['ku', 'ckb', 'ar'].contains(widget.lang)
            ? TextDirection.rtl
            : TextDirection.ltr,
        child: Scaffold(
          appBar: AppBar(title: Text(s.title)),
          body: AbsorbPointer(
            absorbing: saving,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 840),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    if (widget.simulated)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          s.tr(
                            'SIMULATED AI · test data',
                            'ذكاء اصطناعي محاكى · بيانات اختبار',
                            'زیرەکی دەستکردی لاساییکراوە · داتای تاقیکردنەوە',
                          ),
                        ),
                      ),
                    TextField(
                      key: const ValueKey('scan-title'),
                      controller: title,
                      maxLength: 200,
                      onChanged: (v) => change(() => draft.title = v),
                      decoration: InputDecoration(
                        labelText: s.mealName,
                        border: const OutlineInputBorder(),
                        counterText: '',
                      ),
                    ),
                    const SizedBox(height: 12),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(
                        s.review,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      leading: const Icon(Icons.info_outline, size: 20),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            '${s.estimate}\n${s.modeHint}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final mode in ['dish', 'components'])
                          ChoiceChip(
                            key: ValueKey('scan-mode-$mode'),
                            label: Text(mode == 'dish' ? s.dish : s.components),
                            selected: draft.mode == mode,
                            onSelected: (_) async {
                              if (draft.mode == mode ||
                                  !await replaceList() ||
                                  !mounted) {
                                return;
                              }
                              change(() {
                                draft.mode = mode;
                                draft.items.clear();
                              });
                            },
                          ),
                      ],
                    ),
                    if (draft.items.isEmpty && draft.candidates.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        s.possible,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      for (var i = 0; i < draft.candidates.length; i++)
                        Card(
                          child: ListTile(
                            key: ValueKey('scan-candidate-$i'),
                            dense: true,
                            title: Text(
                              (draft.candidates[i][widget.lang] ??
                                      draft.candidates[i]['en'] ??
                                      '')
                                  .toString(),
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => choose(
                              candidate: draft.candidates[i],
                              whole: true,
                            ),
                          ),
                        ),
                    ],
                    if (draft.items.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(s.empty),
                      ),
                    for (var i = 0; i < draft.pending.length; i++)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(s.pending),
                              Text(
                                draft.pending[i].isEmpty
                                    ? s.choose
                                    : draft.pending[i],
                              ),
                              Wrap(
                                spacing: 8,
                                children: [
                                  TextButton(
                                    onPressed: () => choose(pendingIndex: i),
                                    child: Text(s.change),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        change(() => draft.pending.removeAt(i)),
                                    child: Text(s.remove),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    for (var i = 0; i < draft.items.length; i++)
                      Card(
                        key: ValueKey('scan-item-$i'),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      draft.items[i].food.getLocalizedName(
                                        widget.lang,
                                      ),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                  ),
                                  IconButton(
                                    key: ValueKey('scan-remove-$i'),
                                    tooltip: s.remove,
                                    onPressed: () =>
                                        change(() => draft.items.removeAt(i)),
                                    icon: const Icon(Icons.close),
                                  ),
                                ],
                              ),
                              Text(
                                s.preview,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              if (draft.items[i].amount != null) ...[
                                const SizedBox(height: 8),
                                macros(draft.items[i].totals),
                              ] else
                                Text(
                                  s.portion,
                                  style: TextStyle(color: colors.error),
                                ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  OutlinedButton.icon(
                                    key: ValueKey('scan-portion-$i'),
                                    onPressed: () => editPortion(i),
                                    icon: const Icon(
                                      Icons.straighten,
                                      size: 18,
                                    ),
                                    label: numeric(
                                      draft.items[i].amount == null
                                          ? '— ${draft.items[i].food.nutritionUnit}'
                                          : '${number(draft.items[i].amount!)} ${draft.items[i].food.nutritionUnit}',
                                    ),
                                  ),
                                  TextButton(
                                    key: ValueKey('scan-change-$i'),
                                    onPressed: () => choose(index: i),
                                    child: Text(s.change),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    OutlinedButton.icon(
                      key: const ValueKey('scan-add'),
                      onPressed: draft.items.length >= 15
                          ? null
                          : () => choose(whole: draft.mode == 'dish'),
                      icon: const Icon(Icons.add),
                      label: Text(draft.mode == 'dish' ? s.choose : s.add),
                    ),
                    if (!draft.valid && draft.items.isNotEmpty)
                      Text(s.invalid, style: TextStyle(color: colors.error)),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 840),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!keyboard &&
                          draft.items.isNotEmpty &&
                          draft.items.every((p) => p.amount != null)) ...[
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                s.total,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            numeric(
                              '${number(draft.totals['calories']!)} kcal',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 12,
                          runSpacing: 4,
                          children: [
                            for (final nutrient in [
                              ('protein', s.protein),
                              ('carbs', s.carbs),
                              ('fat', s.fat),
                            ])
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${nutrient.$2}: ',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                  numeric(
                                    '${number(draft.totals[nutrient.$1]!)} g',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ],
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            error!,
                            key: const ValueKey('scan-save-error'),
                            style: TextStyle(color: colors.error),
                          ),
                        ),
                      if (!keyboard)
                        CheckboxListTile(
                          key: const ValueKey('scan-confirm'),
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(s.confirm),
                          value: draft.confirmed,
                          onChanged: saving || !draft.valid
                              ? null
                              : (v) =>
                                    setState(() => draft.confirmed = v == true),
                        ),
                      FilledButton.icon(
                        key: const ValueKey('scan-save'),
                        onPressed: !saving && draft.valid && draft.confirmed
                            ? save
                            : null,
                        icon: saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check),
                        label: Text(
                          saving
                              ? s.tr('Saving…', 'جارٍ الحفظ…', 'تۆمارکردن…')
                              : s.log,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
