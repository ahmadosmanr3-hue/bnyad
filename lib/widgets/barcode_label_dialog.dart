import 'package:flutter/material.dart';
import 'package:nutrify/models/barcode_food_lookup.dart';
import 'package:nutrify/l10n/app_localizations.dart';
import 'package:nutrify/l10n/scan_strings.dart';
import 'package:nutrify/l10n/localized_numbers.dart';

class BarcodeLabelDialog extends StatefulWidget {
  final BarcodeFoodLookup lookup;
  final String lang;
  const BarcodeLabelDialog({
    super.key,
    required this.lookup,
    required this.lang,
  });
  @override
  State<BarcodeLabelDialog> createState() => _BarcodeLabelDialogState();
}

class _BarcodeLabelDialogState extends State<BarcodeLabelDialog> {
  late final TextEditingController _name;
  late final List<TextEditingController> _values;
  late String _unit;
  bool _invalid = false;
  @override
  void initState() {
    super.initState();
    final p = widget.lookup;
    _unit = p.basisUnit;
    _name = TextEditingController(text: p.name);
    _values = [
      p.caloriesPer100g,
      p.proteinPer100g,
      p.carbsPer100g,
      p.fatPer100g,
    ].map((v) => TextEditingController(text: v.toString())).toList();
  }

  @override
  void dispose() {
    _name.dispose();
    for (final c in _values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = ScanStrings(widget.lang), t = AppLocalizations(widget.lang);
    final labels = [t.calories, t.protein, t.carbs, t.fat];
    return AlertDialog(
      scrollable: true,
      title: Text(s.editLabel),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(s.volumeNeedsLabel),
            TextField(
              controller: _name,
              decoration: InputDecoration(labelText: s.productName),
              maxLength: 200,
            ),
            DropdownButtonFormField<String>(
          isExpanded: true,
              initialValue: _unit,
              decoration: InputDecoration(labelText: s.basis),
              items: ['g', 'ml']
                  .map(
                    (u) => DropdownMenuItem(
                      value: u,
                      child: Text(u == 'g' ? s.per100g : s.per100ml),
                    ),
                  )
                  .toList(),
              onChanged: (u) {
                if (u != null) setState(() => _unit = u);
              },
            ),
            for (var i = 0; i < 4; i++)
              TextField(
                controller: _values[i],
                textDirection: TextDirection.ltr,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(labelText: labels[i]),
              ),
            if (_invalid)
              Text(
                s.invalidNutrition,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.cancel),
        ),
        FilledButton(
          onPressed: () {
            final n = _values.map((c) => parseLocalizedDouble(c.text)).toList();
            if (n.any((v) => v == null)) {
              setState(() => _invalid = true);
              return;
            }
            final result = widget.lookup.corrected(
              name: _name.text.trim(),
              unit: _unit,
              calories: n[0]!,
              protein: n[1]!,
              carbs: n[2]!,
              fat: n[3]!,
            );
            if (!result.isValid) {
              setState(() => _invalid = true);
              return;
            }
            Navigator.pop(context, result);
          },
          child: Text(t.save),
        ),
      ],
    );
  }
}
