import 'package:flutter/material.dart';
import 'package:nutrify/models/food_item.dart';
import 'package:nutrify/l10n/localized_numbers.dart';
import 'package:nutrify/utils/measured_portion.dart';

/// Food-specific quantities only. Unspecified household weights must be weighed
/// or explicitly entered by the user, never inferred from the utensil's name.
class PortionEditor extends StatefulWidget {
  const PortionEditor({
    super.key,
    required this.food,
    required this.lang,
    required this.amount,
    required this.onChanged,
  });
  final FoodItem food;
  final String lang;
  final double amount;
  final ValueChanged<double?> onChanged;
  @override
  State<PortionEditor> createState() => _PortionEditorState();
}

class _PortionEditorState extends State<PortionEditor> {
  late final TextEditingController weight = TextEditingController(
    text: widget.amount > 0 ? format(widget.amount) : '',
  );
  final count = TextEditingController(text: '1');
  String unit = 'base';
  double fill = 1;
  bool estimated = false;
  String? error;
  String tr(String en, String ar, String ku) => widget.lang == 'ar'
      ? ar
      : ['ku', 'ckb'].contains(widget.lang)
      ? ku
      : en;
  String format(double n) =>
      n == n.roundToDouble() ? n.toInt().toString() : n.toStringAsFixed(2);
  String get basis => widget.food.isLiquid ? 'mL' : 'g';
  bool get container =>
      unit.contains('bowl') ||
      unit.contains('plate') ||
      ['can', 'bottle', 'glass'].contains(unit);
  Map<String, String> get units => {
    'base': widget.food.isLiquid ? 'mL' : tr('Grams', 'غرام', 'گرام'),
    if (widget.food.isLiquid) ...{
      'liter': 'L',
      'glass': tr('Glass', 'كوب', 'پەرداخ'),
      'can': tr('Can', 'علبة', 'قووتوو'),
      'bottle': tr('Bottle', 'زجاجة', 'بوتڵ'),
    } else ...{
      'teaspoon': tr('Teaspoon', 'ملعقة شاي', 'کەوچکی چای'),
      'tablespoon': tr('Tablespoon', 'ملعقة طعام', 'کەوچکی خواردن'),
      'level': tr(
        'Level tablespoon',
        'ملعقة طعام ممسوحة',
        'کەوچکی خواردنی ساف',
      ),
      'heaped': tr(
        'Heaped tablespoon',
        'ملعقة طعام ممتلئة',
        'کەوچکی خواردنی پڕ',
      ),
      'small-bowl': tr('Small bowl', 'وعاء صغير', 'کاسەی بچووک'),
      'medium-bowl': tr('Medium bowl', 'وعاء متوسط', 'کاسەی مامناوەند'),
      'large-bowl': tr('Large bowl', 'وعاء كبير', 'کاسەی گەورە'),
      'small-plate': tr('Small plate', 'صحن صغير', 'قاپی بچووک'),
      'medium-plate': tr('Medium plate', 'صحن متوسط', 'قاپی مامناوەند'),
      'large-plate': tr('Large plate', 'صحن كبير', 'قاپی گەورە'),
      'piece': tr('Piece / slice', 'قطعة / شريحة', 'دانە / پارچە'),
      if (widget.food.categoryId == 'pizza' ||
          widget.food.name.toLowerCase().contains('pizza'))
        'pizza': tr('Whole pizza', 'بيتزا كاملة', 'پیتزای تەواو'),
    },
    'custom': tr('Custom serving', 'حصة مخصصة', 'پشکی تایبەت'),
  };
  double? spoonAmount(String choice) {
    if (widget.food.isLiquid || widget.food.source['type'] != 'usda') {
      return null;
    }
    for (final p in widget.food.portions) {
      if (RegExp(r'^1 cup \(').hasMatch(p['names']?['en']?.toString() ?? '')) {
        final amount = (p['amount'] as num).toDouble();
        if (choice == 'teaspoon') return amount / 48;
        if (['tablespoon', 'level'].contains(choice)) return amount / 16;
      }
    }
    return null;
  }

  @override
  void dispose() {
    weight.dispose();
    count.dispose();
    super.dispose();
  }

  void update() {
    try {
      final value =
          measuredPortionAmount(
            amountPerUnit:
                (parseLocalizedDouble(weight.text) ?? 0) *
                (unit == 'liter' ? 1000 : 1),
            count: parseLocalizedDouble(count.text) ?? 0,
          ) *
          fill;
      setState(() => error = null);
      widget.onChanged(value);
    } on FormatException {
      setState(
        () => error = tr(
          'Enter positive quantities; total at most 10,000.',
          'أدخل كميات موجبة؛ الإجمالي حتى 10000.',
          'بڕی ئەرێنی بنووسە؛ کۆی گشتی تا ١٠٠٠٠.',
        ),
      );
      widget.onChanged(null);
    }
  }

  Widget field(TextEditingController controller, String label, String key) =>
      TextField(
        key: ValueKey(key),
        controller: controller,
        textDirection: TextDirection.ltr,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (_) => update(),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      );
  @override
  Widget build(BuildContext context) {
    final f = widget.food;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr('Your portion', 'حصتك', 'پشکی تۆ'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: units.entries
              .map(
                (e) => ChoiceChip(
                  key: ValueKey('portion-${e.key}'),
                  label: Text(e.value),
                  selected: unit == e.key,
                  materialTapTargetSize: MaterialTapTargetSize.padded,
                  onSelected: (_) {
                    setState(() {
                      unit = e.key;
                      fill = 1;
                      estimated = false;
                      count.text = '1';
                      weight.text = unit == 'base'
                          ? '100'
                          : unit == 'liter'
                          ? '1'
                          : '';
                      final spoon = spoonAmount(unit);
                      if (spoon != null) {
                        weight.text = spoon.toStringAsFixed(1);
                        estimated = true;
                      }
                    });
                    update();
                  },
                ),
              )
              .toList(),
        ),
        if (f.portions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            tr(
              'Catalog portions · check the weight',
              'حصص القائمة · تحقق من الوزن',
              'پشکەکانی لیست · کێشەکە بپشکنە',
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: f.portions
                .map(
                  (p) => ActionChip(
                    label: Text(
                      '${p['estimated'] == true ? '≈ ' : ''}${p['amount'] == 1000 && f.isLiquid ? '1 L' : p['names']?[widget.lang] ?? p['names']?['en']}',
                    ),
                    onPressed: () {
                      setState(() {
                        unit = 'custom';
                        weight.text = format((p['amount'] as num).toDouble());
                        count.text = '1';
                        fill = 1;
                        estimated = p['estimated'] == true;
                      });
                      update();
                    },
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 16),
        if (!['base', 'liter'].contains(unit)) ...[
          Text(
            tr(
              'Use the edible weight for THIS food and preparation. Weigh one full portion or use its package label. Raw and cooked weights differ.',
              'استخدم الوزن الصالح للأكل لهذا الطعام وطريقة تحضيره. زن حصة كاملة أو راجع ملصقها. تختلف أوزان النيء والمطبوخ.',
              'کێشی بەشی خواردنەوەی ئەم خواردنە و شێوازی ئامادەکردنەکە بەکاربهێنە. پشکێکی پڕ بکێشە یان لیبڵەکە بخوێنەوە. کێشی خاو و لێنراو جیاوازە.',
            ),
          ),
          const SizedBox(height: 12),
        ],
        field(
          weight,
          ['base', 'liter'].contains(unit)
              ? (unit == 'liter' ? 'L' : basis)
              : '$basis / ${units[unit]}',
          'portion-weight',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            IconButton.filledTonal(
              key: const ValueKey('portion-minus'),
              tooltip: tr(
                'Decrease quantity',
                'تقليل الكمية',
                'کەمکردنەوەی بڕ',
              ),
              onPressed: () {
                final n = parseLocalizedDouble(count.text) ?? 1;
                count.text = format(n <= .25 ? n : (n - 1).clamp(.25, 10000));
                update();
              },
              icon: const Icon(Icons.remove),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: field(
                count,
                tr('Quantity', 'الكمية', 'بڕ'),
                'portion-count',
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              key: const ValueKey('portion-plus'),
              tooltip: tr('Increase quantity', 'زيادة الكمية', 'زیادکردنی بڕ'),
              onPressed: () {
                count.text = format(
                  (parseLocalizedDouble(count.text) ?? 0) + 1,
                );
                update();
              },
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        if (container) ...[
          const SizedBox(height: 12),
          Text(
            '${tr('Fill level', 'مستوى الامتلاء', 'ئاستی پڕبوون')} · \u2066${(fill * 100).round()}%\u2069',
          ),
          Slider(
            key: const ValueKey('portion-fill'),
            value: fill,
            min: .25,
            max: 1,
            divisions: 3,
            onChanged: (v) {
              setState(() => fill = v);
              update();
            },
          ),
          Text(
            tr(
              'Fill fraction scales the measured full-portion amount. It does not convert volume to weight.',
              'نسبة الامتلاء تعدّل كمية الحصة الكاملة المقاسة، ولا تحوّل الحجم إلى وزن.',
              'ڕێژەی پڕبوون بڕی پشکی پڕی پێوانەکراو دەگۆڕێت؛ قەبارە ناکات بە کێش.',
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          error == null
              ? '${tr('Total', 'الإجمالي', 'کۆی گشتی')}: \u2066${format(widget.amount)} $basis\u2069'
              : '—',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (widget.food.isLiquid && container)
          Wrap(
            spacing: 8,
            children: [
              for (final capacity in [150, 250, 330, 500, 750, 1000])
                ActionChip(
                  label: Text('$capacity mL'),
                  onPressed: () {
                    weight.text = '$capacity';
                    update();
                  },
                ),
            ],
          ),
        if (estimated)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              tr(
                'Estimated from this food’s catalog portion; packing and preparation vary. Adjust to your actual weight.',
                'تقدير من حصة هذا الطعام؛ يختلف الوزن حسب التعبئة والتحضير. عدّل الوزن الفعلي.',
                'خەمڵاندن لە پشکی ئەم خواردنە؛ پڕکردنەوە و ئامادەکردن کێش دەگۆڕن. کێشی ڕاستەقینە ڕێک بخە.',
              ),
            ),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }
}
