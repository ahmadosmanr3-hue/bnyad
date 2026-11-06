import 'package:flutter/material.dart';
import 'package:nutrify/l10n/localized_numbers.dart';
import 'package:nutrify/utils/measured_portion.dart';

Future<double?> showMeasuredPortion(
  BuildContext context, {
  required bool liquid,
  required bool pizza,
  required String lang,
}) => showDialog<double>(
  context: context,
  builder: (_) =>
      _MeasuredPortionDialog(liquid: liquid, pizza: pizza, lang: lang),
);

class _MeasuredPortionDialog extends StatefulWidget {
  const _MeasuredPortionDialog({
    required this.liquid,
    required this.pizza,
    required this.lang,
  });
  final bool liquid, pizza;
  final String lang;
  @override
  State<_MeasuredPortionDialog> createState() => _MeasuredPortionDialogState();
}

class _MeasuredPortionDialogState extends State<_MeasuredPortionDialog> {
  final mass = TextEditingController(),
      count = TextEditingController(text: '1');
  late String selected = choices.first;
  String? error;
  @override
  void dispose() {
    mass.dispose();
    count.dispose();
    super.dispose();
  }

  String tr(String en, String ar, String ku) => widget.lang == 'ar'
      ? ar
      : widget.lang == 'ku'
      ? ku
      : en;
  List<String> get choices => widget.liquid
      ? [
          tr('Can', 'علبة', 'قووتوو'),
          tr('Bottle', 'زجاجة', 'بوتڵ'),
          tr('Cup / glass', 'كوب', 'کوپ / پەرداخ'),
          tr('Liter', 'لتر', 'لیتر'),
        ]
      : widget.pizza
      ? [
          tr('Slice', 'شريحة', 'پارچە'),
          tr(
            'Whole pizza / one-pizza box',
            'بيتزا كاملة / علبة بيتزا واحدة',
            'پیتزای تەواو / سندووقی یەک پیتزا',
          ),
        ]
      : [
          tr('Defined spoon', 'ملعقة محددة', 'کەوچکی دیاریکراو'),
          tr('Small plate', 'صحن صغير', 'قاپی بچووک'),
          tr('Medium plate', 'صحن متوسط', 'قاپی مامناوەند'),
          tr('Large plate', 'صحن كبير', 'قاپی گەورە'),
          tr('Piece / serving', 'قطعة / حصة', 'پارچە / پشک'),
        ];

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      tr(
        'Define your measured portion',
        'حدد حصتك المقاسة',
        'پشکی پێوانەکراوت دیاری بکە',
      ),
    ),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: selected,
            isExpanded: true,
            items: choices
                .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                .toList(),
            onChanged: (v) => setState(() {
              selected = v!;
              mass.text = widget.liquid && selected == choices.last
                  ? '1000'
                  : '';
              error = null;
            }),
          ),
          Text(
            tr(
              'Use a scale or package label. No universal spoon, plate or slice weight is assumed.',
              'استخدم ميزانًا أو ملصق العبوة. لا نفترض وزنًا موحدًا للملعقة أو الصحن أو الشريحة.',
              'پێوەر یان زانیاریی پاکەت بەکاربهێنە. کێشی یەکسان بۆ کەوچک و قاپ و پارچە دانانرێت.',
            ),
          ),
          TextField(
            controller: mass,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: '${widget.liquid ? 'mL' : 'g'} / $selected',
            ),
          ),
          TextField(
            controller: count,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: tr(
                'Number of portions',
                'عدد الحصص',
                'ژمارەی پشکەکان',
              ),
              errorText: error,
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
      ),
      FilledButton(
        onPressed: () {
          try {
            final value = measuredPortionAmount(
              amountPerUnit: parseLocalizedDouble(mass.text) ?? 0,
              count: parseLocalizedDouble(count.text) ?? 0,
            );
            Navigator.pop(context, value);
          } on FormatException {
            setState(
              () => error = tr(
                'Enter positive measurements (maximum total 10000).',
                'أدخل قياسات موجبة (الإجمالي الأقصى 10000).',
                'پێوانەی ئەرێنی بنووسە (زۆرترین کۆ ١٠٠٠٠).',
              ),
            );
          }
        },
        child: Text(MaterialLocalizations.of(context).okButtonLabel),
      ),
    ],
  );
}
